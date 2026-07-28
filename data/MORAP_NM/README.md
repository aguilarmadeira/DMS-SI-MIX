# data/MORAP_NM — no-mixing reliability allocation instance

Problem data and exact-front artifacts for the MORAP-NM study.

## Contents

- `morap_nm_data.m` — the MORAP-NM component data defining the instance;
- `enumerate_morap_nm.m`, `enumerate_pareto.m` — the exhaustive enumeration
  that produces the exact Pareto front;
- `morap_nm_exact_front.csv` — the frozen exact Pareto front: 578 decision
  points with distinct objective vectors;
- `MORAP_NM_data_freeze.md` — the record of the data freeze.

## The exact front file

`morap_nm_exact_front.csv` carries decisions and objectives in the same rows:

| Columns | Meaning |
|---|---|
| `z1, n1, z2, n2, z3, n3` | the decision: component type and redundancy level per subsystem |
| `oneMinusR, C, W` | the three objectives: unreliability, cost, weight |

578 rows, one per exact-front point, with 578 distinct objective vectors.

## Verifying it

This front is the one used to compute the recall, precision, IGD and
hypervolume-gap figures reported in the article. Its SHA-256 hash is recorded
in `MANIFEST.txt` at the repository root, and an MD5 in `B3_final_manifest.txt`
taken at the time the runs were produced.

Re-running the enumeration should regenerate a file with that hash. The metrics
can then be recomputed from the archives in `results/archives/morap_nm/` using
`results/metrics/pilot_metrics_morap_nm.m` and
`results/metrics/morap_common_reference_metrics.m` — note the filename caveat
documented in `results/archives/README.md` before matching runs to variants.
