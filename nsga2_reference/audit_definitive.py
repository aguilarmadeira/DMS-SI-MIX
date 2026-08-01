"""Teste de integridade do pacote definitivo MORAP-NM vs NSGA-II.

Correr APOS FOLLOWUP_DONE. Sai com codigo 1 se qualquer verificacao falhar, para
poder ser usado antes do deposito. Nao resume resultados: verifica que o pacote
esta completo, homogeneo e internamente coerente.

  DEFINITIVE_DONE -> terminaram as sete configuracoes principais
  FOLLOWUP_DONE   -> pacote completo (controlos emparelhados + repeticao do
                     rand-100 + verificacao de nao regressao)
"""
import csv, json, os, sys, subprocess

CFG = [("rand", 100), ("rand", 200), ("rand", 600), ("rand", 50),
       ("halton", 50), ("halton", 100), ("rand", 20),
       ("paired", 50), ("paired", 100)]            # 9 configuracoes distintas
CKPT = [4696, 6168, 6611, 10000, 15000, 20000]
N_SEEDS = 30
N_ROWS_EXPECTED = len(CFG) * N_SEEDS * len(CKPT)   # 1620

REQUIRED_COLUMNS = {
    "pop", "seed", "checkpoint", "reached", "n_new",
    "recall", "precision", "igd", "hv_gap", "n_outside_ref",
    "raw_at_checkpoint", "cache_hits_at_checkpoint",
    "final_raw", "final_cache_hits",
}
HV_KEYS = {"formula", "margin", "basis", "z_ideal", "z_nad", "ref_point",
           "HV_star", "n_front", "n_space", "hv_gap_definition", "note"}
EXPECTED_INIT = {("rand", 50), ("rand", 100), ("halton", 50),
                 ("halton", 100), ("paired", 50), ("paired", 100)}
# anomalia conhecida: o pymoo elimina duplicados na populacao inicial e nao os repoe
KNOWN_INIT_COLLISIONS = {("rand", 100): {"9"}}

ok = True
def chk(cond, msg):
    global ok
    print(("  PASS  " if cond else "  FALHA ") + msg)
    ok = ok and bool(cond)

print("1. sentinelas")
chk(os.path.exists("DEFINITIVE_DONE"),
    "DEFINITIVE_DONE presente (7 configuracoes principais)")
chk(os.path.exists("FOLLOWUP_DONE"),
    "FOLLOWUP_DONE presente (controlos emparelhados + repeticao + verificacao)")

print("2. ficheiros de resultado, esquema e dimensao")
rows = []
for tag, pop in CFG:
    f = f"results_{tag}_{pop}.csv"
    if not os.path.exists(f):
        chk(False, f"{f} em falta")
        continue
    reader = csv.DictReader(open(f))
    chk(REQUIRED_COLUMNS <= set(reader.fieldnames or []),
        f"{f}: esquema completo, incluindo n_outside_ref")
    r = list(reader)
    rows += [dict(x, tag=tag) for x in r]
    chk(len(r) == N_SEEDS * len(CKPT), f"{f}: {len(r)} linhas (esperado 180)")
    chk({int(x["seed"]) for x in r} == set(range(1, N_SEEDS + 1)),
        f"{f}: sementes 1..{N_SEEDS} completas")
    chk({int(x["checkpoint"]) for x in r} == set(CKPT),
        f"{f}: os 6 checkpoints presentes")
    chk(all(x["reached"] in ("0", "1") for x in r),
        f"{f}: reached explicito em todas as linhas")
    chk(all(x["recall"] != "" for x in r if x["reached"] == "1"),
        f"{f}: metricas preenchidas sempre que reached=1")
    # produto cartesiano exato: sem isto, uma linha duplicada compensaria uma ausente
    expected_keys = {(sd, cp) for sd in range(1, N_SEEDS + 1) for cp in CKPT}
    actual_keys = {(int(x["seed"]), int(x["checkpoint"])) for x in r}
    chk(actual_keys == expected_keys and len(r) == len(actual_keys),
        f"{f}: exatamente uma linha por par (semente, checkpoint)")
    # dominios dos valores nas linhas atingidas
    bad = []
    for x in r:
        if x["reached"] != "1":
            continue
        if int(x["n_new"]) != int(x["checkpoint"]):
            bad.append((x["seed"], x["checkpoint"], "n_new != checkpoint")); continue
        try:
            rec, pre = float(x["recall"]), float(x["precision"])
            igd, hvg = float(x["igd"]), float(x["hv_gap"])
        except ValueError:
            bad.append((x["seed"], x["checkpoint"], "metrica nao numerica")); continue
        import math
        vals = [rec, pre, igd, hvg]
        if not all(math.isfinite(v) for v in vals):
            bad.append((x["seed"], x["checkpoint"], "valor nao finito"))
        elif not (0 <= rec <= 1 and 0 <= pre <= 1 and 0 <= hvg <= 1 and igd >= 0):
            bad.append((x["seed"], x["checkpoint"], f"fora de dominio {vals}"))
    chk(not bad, f"{f}: dominios validos (n_new==checkpoint; recall/precision/HVgap em [0,1]; IGD>=0)"
                 + (f" — {bad[:3]}" if bad else ""))

print(f"3. total de linhas: {len(rows)} (esperado {N_ROWS_EXPECTED})")
chk(len(rows) == N_ROWS_EXPECTED,
    f"{N_ROWS_EXPECTED} linhas = 9 configs x 30 sementes x 6 checkpoints")

print("4. referencia de HV — payload completo (houve um incidente de reducao silenciosa)")
if os.path.exists("hv_reference.json"):
    hv = json.load(open("hv_reference.json"))
    chk(HV_KEYS <= set(hv), f"payload completo; faltam {sorted(HV_KEYS - set(hv))}")
    chk(abs(hv.get("HV_star", 0) - 24193.823685372037) < 1e-9, "HV* inalterado")
    chk(hv.get("margin") == 0.1, "margem 0.1")
    chk(hv.get("n_front") == 578, "frente exata com 578 decisoes")
    chk(hv.get("n_space") == 34300, "espaco completo com 34 300 decisoes")
else:
    chk(False, "hv_reference.json em falta")

print("5. cardinalidade da populacao inicial (rand, halton e paired)")
if os.path.exists("init_audit.csv"):
    ia = list(csv.DictReader(open("init_audit.csv")))
    found = {(r["tag"], int(r["requested_initial_size"])) for r in ia}
    chk(EXPECTED_INIT <= found,
        f"todas as combinacoes presentes; faltam {sorted(EXPECTED_INIT - found)}")
    for tag, pop in sorted(EXPECTED_INIT):
        rc = [r for r in ia if r["tag"] == tag and int(r["requested_initial_size"]) == pop]
        chk(len(rc) == N_SEEDS, f"{tag}-{pop}: {len(rc)} sementes auditadas (esperado {N_SEEDS})")
        col = {r["seed"] for r in rc if int(r["unique_initial_decisions"]) != pop}
        expected = KNOWN_INIT_COLLISIONS.get((tag, pop), set())
        if tag in ("halton", "paired"):
            # len(rc)==N_SEEDS no predicado: sem isto, um ficheiro sem estas linhas
            # passaria vaziamente (conjunto de colisoes vazio).
            chk(len(rc) == N_SEEDS and not col,
                f"{tag}-{pop}: cardinalidade inicial exata nas {len(rc)} sementes auditadas")
        else:
            chk(len(rc) == N_SEEDS and col == expected,
                f"{tag}-{pop}: colisoes = {sorted(col) or 'nenhuma'} "
                f"(esperado {sorted(expected) or 'nenhuma'})")
            if col:
                print("         nota: anomalia conhecida — o pymoo elimina duplicados na "
                      "populacao inicial e nao os repoe; e' a razao de existir o controlo paired")
else:
    chk(False, "init_audit.csv em falta")

print("6. desenho inicial Halton (relatorio do harness)")
for pop in (50, 100):
    f = f"init_design_{pop}.json"
    if os.path.exists(f):
        d = json.load(open(f))
        chk(d["unique_initial_decisions"] == d["requested_initial_size"],
            f"{f}: {d['unique_initial_decisions']}/{d['requested_initial_size']} distintas, "
            f"{d['initial_duplicates_skipped']} colisoes saltadas")
    else:
        chk(False, f"{f} em falta")

print("7. nao regressao da repeticao de rand-100")
if os.path.exists("verify_rerun_100.py") and os.path.exists("results_rand_100_PREPATCH.csv"):
    v = subprocess.run([sys.executable, "verify_rerun_100.py"], text=True, capture_output=True)
    for stream in (v.stdout, v.stderr):
        if stream.strip():
            print("   " + stream.strip().replace("\n", "\n   "))
    chk(v.returncode == 0, "rand-100 repetido e' exatamente igual nas 13 colunas comuns")
else:
    chk(False, "verify_rerun_100.py ou results_rand_100_PREPATCH.csv em falta")

print()
print("RESULTADO:", "PACOTE INTEGRO" if ok else "PACOTE INCOMPLETO OU INCOERENTE")
sys.exit(0 if ok else 1)
