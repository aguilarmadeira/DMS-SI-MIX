# configurations — exact parameters of every reported run

One parameter file per reported experiment. These are the files that pin the
published numbers to a configuration.

Expected contents:

- continuous scale-invariance study: `parameters_dms.m` and
  `parameters_dms_si.m`;
- B2 ablation: `parameters_B2_fixed.m`, `parameters_B2_cc_static.m`,
  `parameters_B2_cc_dnr.m`, `parameters_B2_full.m`;
- MORAP-NM: `parameters_MORAP_fixed.m`, `parameters_MORAP_cc_dnr.m`,
  `parameters_MORAP_full.m`.

Two cautions, both of which have bitten before:

1. Each file is a snapshot of ONE step-size configuration. The continuous study
   reports C1, C2 and the non-expansive regime; a single file records only one
   of them. Either ship one file per configuration, or ship a driver that sets
   (beta, gamma) explicitly, so that nobody reproduces a comparison in which the
   two methods ran under different regimes.
2. `nPini` is inert unless `user_list_size = 1`. With `user_list_size = 0` the
   initial list size equals the problem dimension n, whatever value `nPini`
   holds. Do not read `nPini` in isolation.

Check that each file's header names the file it actually is, and that the
comment on `list` covers every value used (the released DMS header documents
"0-4" but values 5 = Halton and 6 = Sobol are also in use).
