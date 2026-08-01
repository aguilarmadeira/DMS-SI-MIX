"""MORAP-NM: mixed-variable NSGA-II vs DMS-SI-Mix exact-front recovery.

Corrections over the exploratory v1:
  1. Real NSGA-II: binary tournament by dominance+crowding (pymoo's
     MixedVariableMating defaults to RandomSelection -> v1 had NO selection pressure).
  2. Budget is measured in NEW evaluations (cache misses). Checkpoints that are not
     reached are reported as 'not reached', never silently downgraded.
  3. A real cache: F is consulted only on a miss; hits are counted separately.
  4. NSGA-II curves come from the emitted results/curve files; published
     DMS-SI-Mix reference points are stored separately in reference_points.csv.
  5. The cached exact front carries a signature of (CARD, NMAX, component data,
     objective source); a mismatch forces recomputation instead of silently
     reusing a front belonging to a different problem.
"""
import itertools, json, csv, os, sys, numpy as np
from pymoo.core.problem import ElementwiseProblem
from pymoo.core.variable import Integer, Choice
from pymoo.core.mixed import (MixedVariableGA, MixedVariableMating,
                              MixedVariableDuplicateElimination, MixedVariableSampling)
from pymoo.operators.selection.tournament import TournamentSelection
from pymoo.algorithms.moo.nsga2 import binary_tournament, RankAndCrowding
from pymoo.core.termination import Termination
from pymoo.core.sampling import Sampling
from pymoo.indicators.hv import HV
from pymoo.optimize import minimize
import pymoo

R=[[0.94,0.91,0.89,0.75,0.72],[0.97,0.86,0.70,0.66],[0.96,0.89,0.72,0.71,0.67]]
C=[[9,6,6,3,2],[12,3,2,2],[10,6,4,3,2]]
W=[[9,6,4,7,8],[5,7,3,4],[6,8,2,4,4]]
CARD=[5,4,5]; NMAX=7
CHECKPOINTS=[4696,6168,6611,10000,15000,20000]
STAGNATION=20_000          # raw proposals with no new distinct decision -> stop
RAW_CAP=400_000

def F(z,n):
    p=1.0
    for i in range(3): p*=(1-(1-R[i][z[i]])**n[i])
    return (1.0-p, float(sum(n[i]*C[i][z[i]] for i in range(3))),
                   float(sum(n[i]*W[i][z[i]] for i in range(3))))

def _front_signature():
    """Identifies the problem the cached front belongs to: block cardinalities,
    redundancy bound, component data, and the source of the objective itself."""
    import hashlib, inspect
    payload = repr((CARD, NMAX, R, C, W)) + inspect.getsource(F)
    return hashlib.sha256(payload.encode()).hexdigest()

def exact_front(cache_path="exact_front.npz"):
    import os
    sig = _front_signature()
    dec=[]
    for z in itertools.product(*[range(c) for c in CARD]):
        for n in itertools.product(*[range(1,NMAX+1)]*3):
            dec.append((z,n))
    if os.path.exists(cache_path):
        d=np.load(cache_path)
        if str(d["signature"]) == sig:
            return {dec[i] for i in d["idx"]}, d["obj"], int(d["nspace"])
        print(f"  [aviso] {cache_path} pertence a outra definicao do problema; a recomputar",flush=True)
    O=np.array([F(*d) for d in dec]); keep=np.ones(len(O),bool)
    for a in range(0,len(O),500):
        blk=O[a:a+500]
        keep[a:a+500]=~(np.all(O[None]<=blk[:,None],axis=2)&np.any(O[None]<blk[:,None],axis=2)).any(axis=1)
    idx=np.where(keep)[0]
    np.savez(cache_path, idx=idx, obj=O[idx], nspace=len(O), signature=sig,
             card=np.array(CARD), nmax=NMAX)
    return {dec[i] for i in idx}, O[idx], len(O)

def archive_snapshots(objs, checkpoints):
    """Incremental passive archive; returns {checkpoint: array of nondominated}."""
    arch=np.empty((0,3)); snaps={}; cps=sorted(checkpoints)
    for i,f in enumerate(objs,1):
        v=np.asarray(f)
        if len(arch):
            if (np.all(arch<=v,axis=1)&np.any(arch<v,axis=1)).any():
                pass
            else:
                arch=arch[~(np.all(v<=arch,axis=1)&np.any(v<arch,axis=1))]
                arch=np.vstack([arch,v])
        else:
            arch=v[None,:]
        if cps and i==cps[0]:
            snaps[cps.pop(0)]=arch.copy()
    return snaps

def van_der_corput(n, base):
    x, f = 0.0, 1.0/base
    while n: x += f*(n % base); n //= base; f /= base
    return x

def halton_design(n_points):
    """Desenho de baixa discrepancia no espaco misto canonico, com **exatamente
    n_points decisoes canonicas distintas**: o mapeamento de pontos Halton para
    grelhas finitas pequenas (5,4,5,7,7,7) pode colidir, pelo que a sequencia
    prossegue ate perfazer o numero pedido. Sem isto, as populacoes iniciais
    efetivas de halton e rand poderiam ter dimensoes diferentes.
    NOTA: construido aqui segundo o mesmo principio; NAO e' bit-a-bit a lista do
    manuscrito, cujo gerador nao esta publico."""
    bases=[2,3,5,7,11,13]; out=[]; seen=set(); k=0; dup=0
    while len(out)<n_points:
        k+=1
        h=[van_der_corput(k,b) for b in bases]
        z=tuple(min(int(h[i]*CARD[i]), CARD[i]-1) for i in range(3))
        n=tuple(1+min(int(h[3+i]*NMAX), NMAX-1) for i in range(3))
        if (z,n) in seen: dup+=1; continue
        seen.add((z,n)); out.append((z,n))
    halton_design.stats={"requested_initial_size":n_points,
                         "actual_initial_size":len(out),
                         "unique_initial_decisions":len(seen),
                         "initial_duplicates_skipped":dup,
                         "halton_indices_consumed":k}
    return out

def _decision_of(d):
    return (tuple(int(d[f"z{i}"]) for i in range(3)), tuple(int(d[f"n{i}"]) for i in range(3)))

def sample_distinct(problem, n, **kw):
    """Amostra aleatoria ate obter EXATAMENTE n decisoes canonicas distintas.
    E' a rotina partilhada pelos controlos de inicializacao: tanto o ramo halton
    como o ramo paired-random a executam, pelo que consomem exatamente os mesmos
    numeros pseudoaleatorios e entram na primeira geracao com o mesmo estado."""
    got={}; batches=0
    while len(got)<n:
        batch=MixedVariableSampling()._do(problem,n,**kw); batches+=1
        for d in batch:
            k=_decision_of(d)
            if k not in got: got[k]=d
            if len(got)==n: break
    sample_distinct.stats={"batches_drawn":batches,"unique_initial_decisions":len(got)}
    return list(got.values())

class PairedRandomSampling(Sampling):
    """Controlo aleatorio emparelhado: n decisoes distintas garantidas."""
    def _do(s, problem, n_samples, **kw):
        return np.array(sample_distinct(problem,n_samples,**kw),dtype=object)

class FixedInitialSampling(Sampling):
    """Devolve um desenho fixo, mas consome EXATAMENTE os mesmos numeros
    pseudoaleatorios que o controlo aleatorio emparelhado consumiria. Sem isto, as corridas
    halton e rand entram na primeira geracao com estados aleatorios diferentes e o
    contraste deixa de isolar a inicializacao (MixedVariableSampling._do chama
    var.sample(n_samples, random_state=...) por variavel)."""
    def __init__(s, decisions): super().__init__(); s.dec=decisions
    def _do(s, problem, n_samples, **kw):
        _ = sample_distinct(problem, n_samples, **kw)   # queima exatamente os mesmos draws
        rows=[]
        for k in range(n_samples):
            z,n = s.dec[k % len(s.dec)]
            d={f"z{i}": z[i] for i in range(3)}; d.update({f"n{i}": n[i] for i in range(3)})
            rows.append(d)
        return np.array(rows, dtype=object)

class Morap(ElementwiseProblem):
    """Cache-backed: only misses count as evaluations."""
    def __init__(s, budget):
        v={f"z{i}":Choice(options=list(range(CARD[i]))) for i in range(3)}
        v.update({f"n{i}":Integer(bounds=(1,NMAX)) for i in range(3)})
        super().__init__(vars=v,n_obj=3)
        s.cache={}; s.order=[]; s.stamps=[]; s.hits=0; s.raw=0; s.budget=budget; s.since_new=0
    def _evaluate(s,X,out,*a,**k):
        d=(tuple(int(X[f"z{i}"]) for i in range(3)), tuple(int(X[f"n{i}"]) for i in range(3)))
        s.raw+=1
        if d in s.cache:
            s.hits+=1; s.since_new+=1
        else:
            s.cache[d]=F(*d); s.order.append(d); s.stamps.append((s.raw,s.hits)); s.since_new=0
        out["F"]=list(s.cache[d])

class BudgetTermination(Termination):
    """Reads algorithm.problem, NOT a stored reference: pymoo deep-copies the
    termination object, which would otherwise detach it from the live problem
    and make the criterion never fire."""
    def _update(s,algorithm):
        p=algorithm.problem
        if len(p.order)>=p.budget or p.since_new>=STAGNATION or p.raw>=RAW_CAP: return 1.0
        return len(p.order)/p.budget

class MixedNSGA2(MixedVariableGA):
    """MixedVariableGA + NSGA-II parent selection and survival."""
    def __init__(s,pop_size,sampling=None,**kw):
        if sampling is not None: kw['sampling']=sampling
        super().__init__(pop_size=pop_size,
            mating=MixedVariableMating(
                selection=TournamentSelection(func_comp=binary_tournament),
                eliminate_duplicates=MixedVariableDuplicateElimination()),
            survival=RankAndCrowding(), advance_after_initial_infill=True, **kw)
        s.tournament_type="comp_by_dom_and_crowding"

def hv_reference(front_obj):
    """r = z_nad + 0.1 (z_nad - z_ideal), calculado SO' a partir da frente exata.
    Independente das corridas, logo comparavel entre metodos para sempre.
    Difere da referencia da Tabela 6 do manuscrito, que usa a uniao com os
    arquivos finais; para comparacao like-for-like o lado DMS-SI-Mix tem de ser
    recalculado nesta referencia."""
    zi=front_obj.min(axis=0); zn=front_obj.max(axis=0)
    return zn + 0.1*(zn-zi)

def run(pop,seed,FRONT,budget=20000,sampling=None,hv_ind=None,hv_star=None):
    p=Morap(budget)
    minimize(p, MixedNSGA2(pop,sampling=sampling), BudgetTermination(), seed=seed, verbose=False)
    objs=[p.cache[d] for d in p.order]
    hits=np.cumsum([1 if d in FRONT else 0 for d in p.order])
    snaps=archive_snapshots(objs,[c for c in CHECKPOINTS if c<=len(p.order)])
    rows=[]
    for B in CHECKPOINTS:
        if len(p.order)<B:
            rows.append(dict(pop=pop,seed=seed,checkpoint=B,reached=0,n_new=len(p.order),
                             recall="",precision="",igd="",hv_gap="",n_outside_ref="",raw_at_checkpoint="",
                             cache_hits_at_checkpoint="",final_raw=p.raw,final_cache_hits=p.hits))
            continue
        arch=snaps[B]; h=int(hits[B-1])
        igd=float(np.mean(np.min(np.linalg.norm(FRONT_OBJ[:,None,:]-arch[None,:,:],axis=2),axis=1)))
        hvgap=""; n_out=""
        if hv_ind is not None:
            inside=np.all(arch<=hv_ind.ref_point,axis=1)
            n_out=int((~inside).sum())
            hv_a=float(hv_ind(arch[inside])) if inside.any() else 0.0
            assert hv_a <= hv_star + 1e-10*max(1.0,abs(hv_star)), \
                f"HV(arquivo)={hv_a} > HV*={hv_star}"
            hvgap=float((hv_star-hv_a)/hv_star)
        rw,hh=p.stamps[B-1]
        rows.append(dict(pop=pop,seed=seed,checkpoint=B,reached=1,n_new=B,
                         recall=h/len(FRONT),precision=h/len(arch),igd=igd,hv_gap=hvgap,n_outside_ref=n_out,
                         raw_at_checkpoint=rw,cache_hits_at_checkpoint=hh,
                         final_raw=p.raw,final_cache_hits=p.hits))
    return rows, hits, len(p.order), p.raw, p.hits

if __name__=="__main__":
    pops=[int(x) for x in sys.argv[1].split(",")]; seeds=int(sys.argv[2])
    tag=sys.argv[3] if len(sys.argv)>3 else "rand"
    FRONT,FRONT_OBJ,NSPACE=exact_front()
    globals()['FRONT_OBJ']=FRONT_OBJ
    ref=hv_reference(FRONT_OBJ); hv_ind=HV(ref_point=ref); hv_star=float(hv_ind(FRONT_OBJ))
    import json as _j, os as _os
    _payload={"formula":"r = z_nad + margin * (z_nad - z_ideal)","margin":0.1,
              "basis":"exact Pareto front only (run-independent)",
              "z_ideal":[float(x) for x in FRONT_OBJ.min(axis=0)],
              "z_nad":[float(x) for x in FRONT_OBJ.max(axis=0)],
              "ref_point":[float(x) for x in ref],"HV_star":hv_star,
              "n_front":len(FRONT),"n_space":int(NSPACE),
              "hv_gap_definition":"HV_gap(A) = (HV(P*;r) - HV({f in A : f <= r}; r)) / HV(P*;r)",
              "note":("Ler SEMPRE a precisao completa. Difere da referencia da Tabela 6 do "
                      "manuscrito (uniao com arquivos finais): o lado DMS-SI-Mix tem de ser "
                      "recalculado nesta referencia antes de qualquer tabela conjunta.")}
    if _os.path.exists('hv_reference.json'):
        _st=_j.load(open('hv_reference.json'))
        for _k in ("z_ideal","z_nad","ref_point","HV_star","margin"):
            assert _st.get(_k)==_payload[_k], (
                f"hv_reference.json diverge em '{_k}': ficheiro={_st.get(_k)} "
                f"calculado={_payload[_k]}. A frente exata, a formula ou a margem "
                f"mudaram — nao sobrescrever a referencia historica.")
        print("hv_reference.json verificado (inalterado)",flush=True)
    else:
        _j.dump(_payload,open('hv_reference.json','w'),indent=2)
        print("hv_reference.json criado",flush=True)
    samp=None
    if tag=="paired":
        samp=PairedRandomSampling()
    if tag=="halton":
        samp=FixedInitialSampling(halton_design(pops[0]))
        _rep=dict(halton_design.stats); _rep["pop"]=pops[0]
        _j.dump(_rep,open(f'init_design_{pops[0]}.json','w'),indent=2)
        print("desenho inicial:",_rep,flush=True)
    print(f"ref HV {np.round(ref,4)} | HV* {hv_star:.6g} | init={tag}",flush=True)
    print(f"pymoo {pymoo.__version__} | espaço {NSPACE} | frente exata {len(FRONT)}")
    import csv as _csv
    for pop in pops:
        res_path=f'results_{tag}_{pop}.csv'
        crv_path=f'curves_{tag}_{pop}.jsonl'
        done=set()
        if os.path.exists(res_path):
            done={int(r['seed']) for r in _csv.DictReader(open(res_path))}
            if done: print(f"  retoma: {len(done)} sementes ja feitas em {res_path}",flush=True)
        for seed in range(1,seeds+1):
            if seed in done: continue
            rows,hits,ndist,raw,ch=run(pop,seed,FRONT,sampling=samp,hv_ind=hv_ind,hv_star=hv_star)
            new_file=not os.path.exists(res_path)
            with open(res_path,'a',newline='') as f:
                w=_csv.DictWriter(f,fieldnames=list(rows[0].keys()))
                if new_file: w.writeheader()
                w.writerows(rows)
            idx=np.unique(np.linspace(0,len(hits)-1,220).astype(int))
            with open(crv_path,'a') as f:
                f.write(json.dumps({"seed":seed,"L":int(len(hits)),
                                    "x":[int(i+1) for i in idx],
                                    "h":[int(hits[i]) for i in idx]})+"\n")
            print(f"  pop={pop:4d} seed={seed:2d} distintas={ndist:6d} raw={raw:8d} hits={ch:8d}",flush=True)
    print(f"-> results_{tag}_{pops[0]}.csv, curves_{tag}_{pops[0]}.jsonl")
