# results/archives — final nondominated archives

One MATLAB archive per reported run. Every table in `results/metrics/` is
recomputable from these files.

## Layout

| Folder | Contents |
|---|---|
| `b2_default/` | **The set reported in the article** (Table 5 and the decomposition). 24 archives: 6 problems × 4 poll variants. |
| `b2_sobol50/` | Same 24 runs under the `b2_sobol50` initial design (initialization-sensitivity study). |
| `b2_halton200/` | Same 24 runs under the `b2_halton200` initial design (initialization-sensitivity study). |
| `morap_nm/` | MORAP-NM runs, reindexing study, and categorical-schedule modes. |

The three `b2_*` folders hold files with identical names. They are **not**
interchangeable: only `b2_default/` corresponds to the numbers printed in the
article. The other two exist so that the initialization-sensitivity result in
`results/metrics/b2_init_sensitivity.csv` can be checked.

## Reading a MORAP-NM archive — please read before use

The three MORAP-NM run files are named `pilot_fixed_run1/2/3.mat` for
historical reasons. **All three names contain "fixed", but the three files are
three different poll variants:**

| File | Poll variant |
|---|---|
| `pilot_fixed_run1.mat` | **Fixed** |
| `pilot_fixed_run2.mat` | **CC-DNR** |
| `pilot_fixed_run3.mat` | **Full** |

The authoritative label is inside each file, in `State.poll_variant`; the
filename is not. Reading the names literally will assign the CC-DNR and Full
results to Fixed and make the Table 6 figures irreproducible. The same mapping
is recorded in `B3_final_manifest.txt` at the repository root.

The remaining files in `morap_nm/` are: `b3b_results.mat` (the five
deterministic reindexings), and `dnr_run1_identity.mat`,
`dnr_run2_covering.mat`, `dnr_run3_sobol.mat`, `dnr_run4_affine.mat` (the
categorical-schedule modes).

## Structure of an archive

Each `.mat` contains `Plist`, `Flist`, `alfa`, `func_eval`, and a `State`
struct. `State` carries the fields used to recompute the published tables:

- `poll_variant` — the authoritative variant label;
- `func_eval`, `iter`, `iter_suc` — evaluation and poll counts;
- `Flist` — the final nondominated objective vectors;
- `Plist_z`, `alfa`, `rhoK` — canonical states, step sizes, rotation counters;
- `CacheP`, `CacheF`, `CachenormP` — the full evaluation cache;
- `covK` — categorical coverage;
- `parameters` — the run configuration as executed;
- `PollLog` — the per-poll record (see `results/logs/`).

## Verification

The archives in `b2_default/` were checked against
`results/metrics/b2_summary.csv` on all 18 reported rows (6 problems × Fixed,
CC-DNR, Full): `State.func_eval` matches the `n_eval` column, `State.iter`
matches `polls`, and the width of `Flist` matches `list_size`, in every case.
`State.poll_variant` matches the variant in each filename.
