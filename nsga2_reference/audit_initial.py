"""Audita a cardinalidade da populacao inicial reproduzindo a inicializacao real
do algoritmo (sampling + eliminacao de duplicados do pymoo) para as 30 sementes.
Emite init_audit.csv."""
import csv, numpy as np
import nsga2_morap_v3 as M
from pymoo.optimize import minimize
from pymoo.core.termination import Termination
class StopAfterInit(Termination):
    def _update(s, algorithm): return 1.0
def sampler(tag, pop):
    if tag == "halton": return M.FixedInitialSampling(M.halton_design(pop))
    if tag == "paired": return M.PairedRandomSampling()
    return None
rows=[]
for tag in ("rand","halton","paired"):
    for pop in (50,100):
        for seed in range(1,31):
            p=M.Morap(10**9)
            res=minimize(p, M.MixedNSGA2(pop,sampling=sampler(tag,pop)),
                         StopAfterInit(), seed=seed, verbose=False)
            X=res.algorithm.pop.get("X")
            dec=[(tuple(int(d[f"z{i}"]) for i in range(3)),
                  tuple(int(d[f"n{i}"]) for i in range(3))) for d in X]
            rows.append(dict(tag=tag,requested_initial_size=pop,seed=seed,
                             actual_initial_population_size=len(dec),
                             unique_initial_decisions=len(set(dec)),
                             initial_duplicates_removed=pop-len(dec)))
        r=[x for x in rows if x['tag']==tag and x['requested_initial_size']==pop]
        col=[x['seed'] for x in r if x['unique_initial_decisions']!=pop]
        print(f"  {tag}-{pop}: colisoes em {col if col else 'nenhuma semente'}",flush=True)
with open('init_audit.csv','w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"init_audit.csv: {len(rows)} registos")
