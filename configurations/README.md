# configurations — the exact parameters of every reported run

One parameter file per reported experiment. These are the files that pin the
published numbers to a configuration.

## Contents

| File | Experiment |
|---|---|
| `parameters_dms.m` | continuous scale-invariance study, DMS baseline |
| `parameters_dms_si.m` | continuous scale-invariance study, DMS-SI |
| `parameters_dms_si_mix.m` | reference parameter file for the mixed-variable method, with the full field-by-field documentation of the two-space and DNR settings |
| `parameters_B2_fixed.m` | categorical-neighborhood ablation, Fixed poll variant |
| `parameters_B2_cc_static.m` | categorical-neighborhood ablation, CC-static control |
| `parameters_B2_cc_dnr.m` | categorical-neighborhood ablation, CC-DNR |
| `parameters_B2_full.m` | categorical-neighborhood ablation, Full |
| `parameters_MORAP_fixed.m` | MORAP-NM study, Fixed |
| `parameters_MORAP_cc_dnr.m` | MORAP-NM study, CC-DNR |
| `parameters_MORAP_full.m` | MORAP-NM study, Full |
| `b3_dnr_identity.mat` | stored categorical permutation schedule, identity mode |
| `b3_dnr_covering_cycles.mat` | stored categorical permutation schedule, covering-cycles mode |
| `b3_dnr_sobol_rank.mat` | stored categorical permutation schedule, Sobol-rank mode |
| `b3_dnr_affine.mat` | stored categorical permutation schedule, affine mode |

The four schedule files correspond to the four categorical-schedule modes
compared in the MORAP-NM study; the runs they produced are in
`results/archives/morap_nm/dnr_run*.mat`.

## Two things to know when reading these files

**Each file records one step-size configuration.** The continuous study
reports configurations C1, C2 and the non-expansive regime; a single
parameter file fixes one of them. The pair of step-size parameters in force
is stated in the header of each file. When comparing two methods, check that
both ran under the same regime.

**`nPini` is inert unless `user_list_size = 1`.** With `user_list_size = 0`,
which is the setting used throughout, the initial list size equals the
problem dimension `n`, whatever value `nPini` holds. Reading `nPini` in
isolation gives the wrong initial list size.
