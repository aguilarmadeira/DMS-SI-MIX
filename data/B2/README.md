# data/B2 — the six controlled mixed-variable instances

The categorical-neighborhood ablation (Fixed / CC-static / CC-DNR / Full) is
run on six controlled mixed-variable reformulations. Those instances are not
duplicated here: they are distributed in the companion benchmark archive
`MOO_Prob_Matlab`, https://doi.org/10.5281/zenodo.20783713, which is the
authoritative source for them.

This file records exactly which six they are, so that a reader can put the
same instances on the MATLAB path.

## The six instances

| Instance in this study | File in `MOO_Prob_Matlab` | n | m | C / D / K | kappa |
|---|---|---|---|---|---|
| DPAM1-Mix | `problems_mixed/baseline_1/DPAM1_mix.m` | 10 | 2 | 4 / 3 / 3 | 1 |
| FES1-Mix | `problems_mixed/baseline_1/FES1_mix.m` | 10 | 2 | 4 / 3 / 3 | 1 |
| QV1-Mix | `problems_mixed/baseline_1/QV1_mix.m` | 10 | 2 | 4 / 3 / 3 | 1 |
| DTLZ2-Mix | `problems_mixed/baseline_1/DTLZ2_mix.m` | 12 | 3 | 4 / 4 / 4 | 1 |
| ZDT3-Mix | `problems_mixed/spatial_thermal_9e4/ZDT3_mix.m` | 30 | 2 | 10 / 10 / 10 | 9e4 |
| ZDT1-Mix | `problems_mixed/sobol_digit_oscillatory_1e6/ZDT1_mix.m` | 30 | 2 | 10 / 10 / 10 | 1e6 |

`C / D / K` is the number of continuous, ordered-discrete and categorical
coordinates; `kappa` is the scale-contrast of the strategy the instance is
drawn from. The exact per-instance figures are listed in
`problems_mixed/INDEX.txt` of the benchmark archive.

Four of the six are taken at `baseline_1`, that is, without scale
heterogeneity, so that the ablation isolates the categorical mechanism. The
remaining two are drawn from a spatial-thermal and a digit-oscillatory
strategy respectively, to check that the same conclusion survives scale
heterogeneity.

## A naming caveat

The run harness refers to the last two instances by the names
`ZDT3_mix_thermal` and `ZDT1_mix_sobol_digit_oscilatory`, which is how they
appear inside the stored archives. These are the same functions as
`spatial_thermal_9e4/ZDT3_mix.m` and
`sobol_digit_oscillatory_1e6/ZDT1_mix.m`; only the local wrapper name
differs. Note also the single `l` in `oscilatory` in the harness name against
the double `l` in the benchmark archive's folder name.
