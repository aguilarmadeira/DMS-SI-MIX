# results/metrics — metric tables, anytime curves, invariance checks

Derived results. Nothing here is primary data: every file is reproducible
from `results/archives/` together with the exact front in `data/MORAP_NM/`.

## Tables and the script that produces each

| Table | Produced by | Reads |
|---|---|---|
| `b2_summary.csv` | `b2_metrics.m` | `results/archives/b2_default/` |
| `b2_decomposition.csv` | `b2_effect_decomposition.m` | `results/archives/b2_default/` |
| `b2_init_sensitivity.csv` | `b2_init_sensitivity.m` | all three `b2_*` archive folders |
| `b3_anytime_curves.csv` | `b3_anytime_morap_nm.m` | `results/archives/morap_nm/` |

Supporting functions: `metrics_objective.m` and `hypervolume_exact.m` compute
the indicators, `paretodominance.m` and `front_matching.m` the dominance and
matching primitives, `ref_front_analytical.m` samples the analytical
reference fronts, `morap_common_reference_metrics.m` builds the common
MORAP-NM reference, and `b2_rotation_diagnostics.m`,
`b3a_conformity_morap_nm.m` and `b3b_indexing_morap_nm.m` produce the
invariance and reindexing checks.

## The hypervolume reference points are not shared

**The HV columns of the three `b2_*` tables are not comparable with one
another.** Each script builds its own union reference front over the runs it
loads, and each loads a different set:

- `b2_summary.csv` — union over the three variants of a pair;
- `b2_decomposition.csv` — union over all four variants, CC-static included;
- `b2_init_sensitivity.csv` — union over all variants of all three initial
  designs.

The same run therefore appears with a different HV value in each of the three
files. This is expected, not an inconsistency. What is meaningful is the
*difference between variants within one table*, which is what the article
reports and what the decomposition into geometry and rotation effects uses.

The MORAP-NM tables use a different construction again: a common reference
derived from the exact 578-point front, which is what makes the recall,
precision, IGD and HV-gap figures in the anytime curves comparable across
variants.

The exact formula in force is documented in the header comment of each
script; read it before reusing a column.

## Two further cautions

**IGD against the analytical front is a proximity diagnostic, not an
optimality gap.** For DTLZ2, ZDT3 and ZDT1, `b2_metrics.m` additionally
reports IGD against a sampled analytical front of the *continuous* problem.
The mixed-variable reformulation has a different attainable front, so this
column measures proximity to the continuous front and must not be read as a
distance to the mixed optimum.

**`b2_default/` is the reported set.** The `b2_sobol50/` and `b2_halton200/`
folders hold files with identical names but different contents; only
`b2_default/` corresponds to the numbers printed in the article.
