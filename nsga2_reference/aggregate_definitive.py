"""Agrega a corrida definitiva. Fontes exclusivas: results_<tag>_<pop>.csv.
Emite summary_definitive.csv, oracle_envelope.csv e init_control.csv.

Regra de elegibilidade do envelope oracle (critica): uma populacao so concorre
num checkpoint se as 30 sementes o tiverem atingido. Calcular a mediana apenas
sobre as sementes sobreviventes selecionaria implicitamente as corridas menos
propensas a estagnacao.
"""
import argparse, csv, glob, json, os, sys
import numpy as np

_ap = argparse.ArgumentParser(description=__doc__)
_ap.add_argument("--allow-partial", action="store_true",
                 help="permite agregar durante a corrida, para acompanhamento")
ARGS = _ap.parse_args()
if not ARGS.allow_partial and not os.path.exists("FOLLOWUP_DONE"):
    sys.exit("A agregacao definitiva exige FOLLOWUP_DONE. "
             "Use --allow-partial apenas para acompanhamento.")
MODE = "PARCIAL (acompanhamento)" if ARGS.allow_partial else "DEFINITIVO"

N_SEEDS = 30
CKPT = [4696, 6168, 6611, 10000, 15000, 20000]
SENS_POPS = [20, 50, 100, 200, 600]          # familia de sensibilidade (tag=rand)
METRICS = {"recall": "max", "precision": "max", "igd": "min", "hv_gap": "min"}

CFG = [("rand", 20), ("rand", 50), ("rand", 100), ("rand", 200), ("rand", 600),
       ("halton", 50), ("halton", 100), ("paired", 50), ("paired", 100)]
EXPECTED_FILES = {f"results_{t}_{p}.csv" for t, p in CFG}
actual = set(glob.glob("results_*.csv")); actual.discard("results_rand_100_PREPATCH.csv")
unexpected = actual - EXPECTED_FILES
missing = EXPECTED_FILES - actual
assert not unexpected, f"ficheiros de resultado inesperados: {sorted(unexpected)}"
if missing:
    assert ARGS.allow_partial, f"ficheiros de resultado em falta: {sorted(missing)}"
    print(f"[{MODE}] em falta ({len(missing)}): {sorted(missing)}")

rows = []
for tag, pop in CFG:
    f = f"results_{tag}_{pop}.csv"
    if not os.path.exists(f):
        continue
    for x in csv.DictReader(open(f)):
        rows.append(dict(x, tag=tag, pop=pop))

def stats(vals):
    a = np.array(vals, float)
    return dict(median=float(np.median(a)), q1=float(np.percentile(a, 25)),
                q3=float(np.percentile(a, 75)), min=float(a.min()), max=float(a.max()))

summary = []
for tag in sorted({r["tag"] for r in rows}):
    for pop in sorted({r["pop"] for r in rows if r["tag"] == tag}):
        for cp in CKPT:
            sel = [r for r in rows if r["tag"] == tag and r["pop"] == pop
                   and int(r["checkpoint"]) == cp]
            reached = [r for r in sel if r["reached"] == "1"]
            d = dict(tag=tag, pop=pop, checkpoint=cp,
                     n_seeds_total=len(sel), n_reached=len(reached),
                     eligible_for_envelope=int(len(reached) == N_SEEDS))
            for m in METRICS:
                if reached:
                    s = stats([float(r[m]) for r in reached])
                    d.update({f"{m}_{k}": round(v, 6) for k, v in s.items()})
                else:
                    d.update({f"{m}_{k}": "" for k in ("median", "q1", "q3", "min", "max")})
            d["raw_at_cp_median"] = (int(np.median([int(r["raw_at_checkpoint"]) for r in reached]))
                                     if reached else "")
            summary.append(d)
with open("summary_definitive.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(summary[0].keys())); w.writeheader(); w.writerows(summary)

# ---- envelope oracle, metrica a metrica, so sobre populacoes elegiveis ----
env = []
for cp in CKPT:
    cand = [d for d in summary if d["tag"] == "rand" and d["pop"] in SENS_POPS
            and d["checkpoint"] == cp]
    elig = [d for d in cand if d["eligible_for_envelope"] == 1]
    excl = sorted(d["pop"] for d in cand if d["eligible_for_envelope"] == 0)
    row = dict(checkpoint=cp,
               eligible_pops=";".join(str(d["pop"]) for d in sorted(elig, key=lambda z: z["pop"])),
               excluded_pops=";".join(map(str, excl)),
               n_eligible=len(elig))
    for m, direction in METRICS.items():
        if not elig:
            row[f"oracle_{m}"] = ""; row[f"oracle_{m}_pop"] = ""; continue
        pick = (max if direction == "max" else min)(elig, key=lambda d: d[f"{m}_median"])
        row[f"oracle_{m}"] = pick[f"{m}_median"]
        row[f"oracle_{m}_pop"] = pick["pop"]
    env.append(row)
with open("oracle_envelope.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(env[0].keys())); w.writeheader(); w.writerows(env)

# ---- controlo de inicializacao: halton vs paired, mesma populacao ----
ctrl = []
for pop in (50, 100):
    for cp in CKPT:
        g = {t: next((d for d in summary if d["tag"] == t and d["pop"] == pop
                      and d["checkpoint"] == cp), None) for t in ("halton", "paired")}
        # mesmo principio do envelope: nunca comparar apenas as sementes sobreviventes
        if not all(g.values()) or any(g[t]["n_reached"] != N_SEEDS for t in ("halton", "paired")):
            if all(g.values()):
                ctrl.append(dict(pop=pop, checkpoint=cp, eligible=0,
                                 halton_n_reached=g["halton"]["n_reached"],
                                 paired_n_reached=g["paired"]["n_reached"],
                                 halton_recall_median="", paired_recall_median="",
                                 delta_recall=""))
            continue
        ctrl.append(dict(pop=pop, checkpoint=cp, eligible=1,
                         halton_n_reached=g["halton"]["n_reached"],
                         paired_n_reached=g["paired"]["n_reached"],
                         halton_recall_median=g["halton"]["recall_median"],
                         paired_recall_median=g["paired"]["recall_median"],
                         delta_recall=round(g["halton"]["recall_median"]
                                            - g["paired"]["recall_median"], 6)))
if ctrl:
    with open("init_control.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(ctrl[0].keys())); w.writeheader(); w.writerows(ctrl)

print(f"[{MODE}]")
print(f"summary_definitive.csv: {len(summary)} linhas")
print(f"oracle_envelope.csv:    {len(env)} checkpoints")
print(f"init_control.csv:       {len(ctrl)} linhas")
print()
print("envelope oracle (populacoes elegiveis = 30/30 sementes atingiram o checkpoint):")
for r in env:
    print(f"  B={r['checkpoint']:>5}  elegiveis=[{r['eligible_pops']}]"
          + (f" EXCLUIDAS=[{r['excluded_pops']}]" if r['excluded_pops'] else "")
          + f"  recall={r['oracle_recall']} (pop {r['oracle_recall_pop']})"
          + f"  HVgap={r['oracle_hv_gap']} (pop {r['oracle_hv_gap_pop']})")
