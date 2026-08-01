"""Compara a repeticao de rand pop=100 (com filtro HV explicito e coluna
n_outside_ref) contra a corrida anterior, nas colunas comuns. O filtro explicito
e' equivalente ao comportamento ja' verificado do pymoo, portanto exige-se
IGUALDADE EXATA; qualquer diferenca denuncia uma alteracao involuntaria."""
import csv, sys
COMMON=["pop","seed","checkpoint","reached","n_new","recall","precision","igd",
        "hv_gap","raw_at_checkpoint","cache_hits_at_checkpoint",
        "final_raw","final_cache_hits"]
old={(r["seed"],r["checkpoint"]):r for r in csv.DictReader(open("results_rand_100_PREPATCH.csv"))}
new={(r["seed"],r["checkpoint"]):r for r in csv.DictReader(open("results_rand_100.csv"))}
assert set(old)==set(new), f"conjuntos de (semente,checkpoint) diferem: {set(old)^set(new)}"
bad=[]
for k in sorted(old):
    for c in COMMON:
        if old[k].get(c,"")!=new[k].get(c,""):
            bad.append((k,c,old[k].get(c),new[k].get(c)))
if bad:
    print(f"FALHA: {len(bad)} diferencas"); [print("  ",*b) for b in bad[:20]]; sys.exit(1)
print(f"PASS: {len(old)} linhas identicas em {len(COMMON)} colunas comuns; "
      f"coluna nova n_outside_ref presente = {'n_outside_ref' in next(iter(new.values()))}")
