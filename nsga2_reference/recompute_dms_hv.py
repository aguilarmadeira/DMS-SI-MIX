"""Recalcula o HV gap do lado DMS-SI-Mix na MESMA referencia usada pelo baseline
NSGA-II, para que as duas colunas possam ficar lado a lado.

A referencia vem de hv_reference.json (calculada so a partir da frente exata,
independente das corridas) e NAO da uniao com arquivos finais usada na Tabela 6.

Uso:
    python3 recompute_dms_hv.py <arquivo_final.csv> [<arquivo2.csv> ...]

Cada ficheiro deve conter os vetores objetivo finais de uma variante, uma linha
por ponto e EXATAMENTE tres colunas. Com cabecalho, exigem-se os nomes f1, f2, f3.
Sem cabecalho, exigem-se tres colunas e nada mais: o script recusa-se a escolher
silenciosamente as tres primeiras de um ficheiro mais largo.
"""
import csv, json, sys
import numpy as np
from pymoo.indicators.hv import HV

ref = json.load(open("hv_reference.json"))
r = np.array(ref["ref_point"], float)
hv_star = float(ref["HV_star"])
ind = HV(ref_point=r)

print(f"referencia: r={r}  HV*={hv_star!r}  (base: {ref['basis']})")
print(f"{'ficheiro':<38} {'pontos':>7} {'fora_r':>7} {'HV':>14} {'HV gap':>12}")
for path in sys.argv[1:]:
    with open(path, newline="") as fh:
        first = fh.readline()
    has_header = any(c.isalpha() for c in first.replace("e", "").replace("E", ""))
    if has_header:
        # com cabecalho: exigir nomes explicitos, nunca adivinhar colunas
        with open(path, newline="") as fh:
            rd = csv.DictReader(fh)
            required = {"f1", "f2", "f3"}
            if not required <= set(rd.fieldnames or []):
                raise ValueError(f"{path}: colunas obrigatorias f1, f2, f3 "
                                 f"(encontradas: {rd.fieldnames})")
            A = np.array([[float(r["f1"]), float(r["f2"]), float(r["f3"])] for r in rd])
    else:
        rows = [r for r in csv.reader(open(path)) if r]
        # sem cabecalho: exigir exatamente tres colunas. NAO cortar as tres
        # primeiras — um ficheiro com indice ou variaveis de decisao produziria
        # um HV numericamente valido sobre as colunas erradas, que e' a pior
        # classe de erro porque nao falha.
        if any(len(r) != 3 for r in rows):
            bad = next(len(r) for r in rows if len(r) != 3)
            raise ValueError(f"{path}: esperadas exatamente tres colunas objetivo, "
                             f"uma linha por vetor; encontrada linha com {bad} colunas. "
                             f"Se o ficheiro tiver indice ou variaveis de decisao, "
                             f"extraia primeiro as colunas (f1,f2,f3) ou use cabecalho.")
        A = np.asarray(rows, dtype=float)
    if A.ndim != 2 or A.shape[1] != 3:
        raise ValueError(f"{path}: matriz {A.shape}, esperado (n, 3)")

    inside = np.all(A <= r, axis=1)
    hv_a = float(ind(A[inside])) if inside.any() else 0.0
    assert hv_a <= hv_star + 1e-10 * max(1.0, abs(hv_star)), "HV(arquivo) > HV*"
    gap = (hv_star - hv_a) / hv_star
    print(f"{path:<38} {len(A):>7} {int((~inside).sum()):>7} {hv_a:>14.6f} {gap:>12.3e}")
