"""Monta o pacote definitivo para deposito no Zenodo: verifica, agrega, desenha e
comprime. Recusa correr sem FOLLOWUP_DONE e sem a auditoria a passar."""
import hashlib, json, os, subprocess, sys, zipfile, datetime

STAMP = os.environ.get("PKG_DATE") or datetime.date.today().isoformat()
ZIPNAME = f"DMS_SI_Mix_MORAP_NM_NSGA2_baseline_{STAMP}.zip"

def run(cmd, label):
    print(f"\n=== {label} ===", flush=True)
    r = subprocess.run(cmd, text=True, capture_output=True)
    print(r.stdout.rstrip())
    if r.stderr.strip(): print(r.stderr.rstrip())
    if r.returncode != 0:
        sys.exit(f"FALHA em {label} (codigo {r.returncode}) — pacote nao construido")
    return r

if not os.path.exists("FOLLOWUP_DONE"):
    sys.exit("FOLLOWUP_DONE em falta — a corrida ainda nao terminou")

run([sys.executable, "audit_definitive.py"], "auditoria de integridade")
run([sys.executable, "aggregate_definitive.py"], "agregacao definitiva")
run([sys.executable, "make_figure_definitive.py"], "figura")

FILES = [
    # codigo
    "nsga2_morap_v3.py", "run_definitive.sh", "run_followup.sh",
    "audit_definitive.py", "audit_initial.py", "aggregate_definitive.py",
    "make_figure_definitive.py", "verify_rerun_100.py", "make_package.py",
    # dados brutos por configuracao
    *[f"results_{t}_{p}.csv" for t, p in
      [("rand",20),("rand",50),("rand",100),("rand",200),("rand",600),
       ("halton",50),("halton",100),("paired",50),("paired",100)]],
    "curves_all.json",
    *[f for f in __import__("glob").glob("curves_*.jsonl")],
    *[f"curves_rand_{p}.json" for p in (50, 200, 600)],
    # agregados e referencias
    "summary_definitive.csv", "oracle_envelope.csv", "init_control.csv",
    "init_audit.csv", "reference_points.csv", "hv_reference.json",
    "init_design_50.json", "init_design_100.json", "exact_front.npz",
    # proveniencia
    "results_rand_100_PREPATCH.csv", "definitive.log", "run_remaining.sh",
    "recompute_dms_hv.py",
    # sentinelas: sem elas o pacote extraido nao passa a sua propria auditoria
    "DEFINITIVE_DONE", "FOLLOWUP_DONE",
    # figura e documentacao
    "Fig_MORAP_NM_definitive.pdf", "README.md",
]

present = [f for f in FILES if os.path.exists(f)]
absent  = [f for f in FILES if not os.path.exists(f)]
if absent:
    sys.exit(f"ficheiros em falta para o pacote: {absent}")

lines = [f"# MANIFEST (pacote NSGA-II) — {ZIPNAME}",
         f"# gerado {STAMP} | Python {sys.version.split()[0]}",
         "", f"{'sha256':<64}  {'bytes':>10}  ficheiro"]
for f in present:
    h = hashlib.sha256(open(f, "rb").read()).hexdigest()
    lines.append(f"{h}  {os.path.getsize(f):>10}  {f}")
open("MANIFEST_nsga2.txt", "w").write("\n".join(lines) + "\n")

with zipfile.ZipFile(ZIPNAME, "w", zipfile.ZIP_DEFLATED) as z:
    for f in present + ["MANIFEST_nsga2.txt"]:
        z.write(f)
print(f"\n=== pacote: {ZIPNAME} ({os.path.getsize(ZIPNAME)/1e6:.2f} MB, "
      f"{len(present)+1} ficheiros) ===")
