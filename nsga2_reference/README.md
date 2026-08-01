# MORAP-NM — mixed-variable NSGA-II reference point for DMS-SI-Mix

Supplementary package for *A Two-Space Scale-Invariant Direct Multisearch Method
for Mixed-Variable Multiobjective Optimization* (J. F. A. Madeira).

It provides an external reference point for the exact-front experiment of
Section 5.4: a mixed-variable NSGA-II run on MORAP-NM under the same evaluation
budget, the same exact Pareto front and the same metrics as the DMS-SI-Mix poll
variants reported in the manuscript.

Everything here is Python and public; it does not depend on the DMS-SI-Mix solver
release.

---

## 1. What was run

MORAP-NM: 3 categorical variables of cardinality (5, 4, 5) and 3 ordered
redundancy variables in {1..7}; 34 300 decisions; exact Pareto front of **578**
decisions with distinct objective vectors, obtained by exhaustive enumeration and
verified against the value published in the manuscript.

Nine configurations × 30 seeds × 6 checkpoints = **1620 result rows**.

| tag | pop. | role |
|---|---|---|
| `rand` | 100 | **reference configuration** — conventional default, not chosen after seeing results |
| `rand` | 20, 50, 200, 600 | population sensitivity; 600 is a *front-size-informed* case (the front has 578 points) |
| `halton` | 50, 100 | initialization control, low-discrepancy start |
| `paired` | 50, 100 | initialization control, random start **paired** with the Halton one |

`paired` exists because `pymoo` removes duplicates from the initial population and
does not replace them: with `pop_size=100`, seed 9 starts with 99 distinct
decisions. The paired control draws until exactly *n* distinct decisions are
obtained, and the Halton branch consumes the identical random draws, so both enter
the first generation with the same generator state and the same initial
cardinality. Verified on the full `bit_generator.state`, with a negative control.

## 2. Protocol

- Python 3.11.15, `pymoo` 0.6.2, seeds 1..30.
- NSGA-II: `TournamentSelection(binary_tournament)` + `RankAndCrowding()`,
  `advance_after_initial_infill=True`, `tournament_type="comp_by_dom_and_crowding"`.
  Default per-type operators: `Choice` → uniform crossover + random resetting;
  `Integer` → SBX + polynomial mutation with rounding repair.
- **Unbounded passive external archive** — the returned nondominated set is not
  truncated by the population size.
- **Budget in new evaluations**: a repeated decision is served from a cache, does
  not consume budget, and the run continues. Stop at 20 000 new evaluations,
  or at 20 000 consecutive raw proposals without a new distinct decision, or at a
  compute cap of 400 000 raw proposals.
- Checkpoints 4 696 / 6 168 / 6 611 (the stopping budgets of DMS-SI-Mix Fixed,
  CC-DNR and Full) plus 10 000 / 15 000 / 20 000.
- Exact points matched by **canonical decision identity** `(z1,z2,z3,n1,n2,n3)`.
- Metrics: recall, precision, IGD, Hypervolume gap.

**Hypervolume reference.** `r = z_nad + 0.1 (z_nad − z_ideal)`, computed from the
**exact front alone** — independent of any run, hence permanently comparable
across methods. Full precision in `hv_reference.json`; that file is the only
source the computation reads. `HV_gap(A) = (HV(P*;r) − HV({f∈A : f ≤ r};r)) / HV(P*;r)`.

> This reference **differs** from the union-based one used in Table 6 of the
> manuscript. To place both methods in one Hypervolume column, the DMS-SI-Mix side
> must be recomputed on this reference from its final archives. Recall, precision
> and IGD are reference-independent and are directly comparable as published.

## 3. Headline results

At 6 168 new evaluations, the budget at which CC-DNR stopped:

| method | recall | precision | IGD |
|---|---|---|---|
| DMS-SI-Mix CC-DNR (published) | 0.9948 | 0.9965 | 0.0112 |
| NSGA-II pop. 100 (reference) | 0.3841 [IQR 0.374–0.403] | 0.6039 | 1.7583 |
| NSGA-II oracle-best of those tested | 0.4386 (pop. 200) | — | — |

At 20 000 new evaluations — about 3.2× that budget — population 600 reaches
recall 0.9273 [0.920–0.931], still below the CC-DNR value at 6 168.

**Initialization control:** Halton minus paired-random differs by at most 0.007 in
median recall, at every budget and both population sizes, with alternating sign.
The initial design does not account for the contrast.

**Oracle envelope** is computed metric by metric from population-wise medians:
maximum for recall and precision, minimum for IGD and HV gap. A population enters
only if all 30 seeds reached that checkpoint — population 20 is therefore excluded
at 15 000 and 20 000. The winning size is not the same across metrics, so no single
tested configuration attains all of them at once; see `oracle_envelope.csv`.

## 4. Files

**Code**

| file | purpose |
|---|---|
| `nsga2_morap_v3.py` | harness; resumable per seed |
| `run_definitive.sh`, `run_followup.sh`, `run_remaining.sh` | drivers |
| `audit_initial.py` | reproduces the real initial population, 6 combinations × 30 seeds |
| `audit_definitive.py` | package integrity test; exits non-zero on failure |
| `aggregate_definitive.py` | aggregation; refuses to run without `FOLLOWUP_DONE` unless `--allow-partial` |
| `make_figure_definitive.py` | figure, from `curves_all.json` + `reference_points.csv` only |
| `verify_rerun_100.py` | non-regression test of the `rand-100` repetition |
| `make_package.py` | builds this archive; refuses if the audit fails |

**Data**

| file | content |
|---|---|
| `results_<tag>_<pop>.csv` | one row per (seed, checkpoint); 180 rows each |
| `curves_<tag>_<pop>.jsonl` | per-seed anytime curve (`.json` for the four configurations run before the resumable harness) |
| `summary_definitive.csv` | median, Q1, Q3, min, max per metric; `n_reached`; `eligible_for_envelope` |
| `oracle_envelope.csv` | envelope per checkpoint, winning population per metric, eligible and excluded populations |
| `init_control.csv` | Halton vs paired, with `eligible` flag |
| `init_audit.csv` | initial cardinality, 180 records |
| `hv_reference.json`, `reference_points.csv`, `exact_front.npz` | references |
| `results_rand_100_PREPATCH.csv` | pre-repetition snapshot, kept for the non-regression test |
| `definitive.log` | full run log, including the two interruptions |

**Column meanings** (`results_*.csv`): `reached` — whether the seed attained that
checkpoint; `n_new` — new evaluations at the checkpoint; `raw_at_checkpoint`,
`cache_hits_at_checkpoint` — proposals and cache hits *at* that checkpoint;
`final_raw`, `final_cache_hits` — totals for the whole run; `n_outside_ref` —
archive points outside the Hypervolume reference box, excluded from HV by
construction.

## 5. Reproducing

```bash
python3 nsga2_morap_v3.py <pop> 30 <rand|halton|paired>   # resumable
python3 audit_initial.py                                  # -> init_audit.csv
python3 audit_definitive.py                               # integrity, exit 0 = ok
python3 aggregate_definitive.py                           # -> summary, envelope, control
python3 make_figure_definitive.py                         # -> figure
```

The harness skips seeds already present in the CSV, so an interrupted run resumes
without loss. `exact_front.npz` carries a SHA-256 signature of `(CARD, NMAX,
component data, source of the objective)`: if the problem definition changes, the
front is recomputed instead of being silently reused.

## 6. Scope

These results concern **MORAP-NM**: a genuinely nominal instance, small decision
space, large exact front. They do not generalize to the six controlled
mixed-variable reformulations of Section 5.3, whose categorical block carries fixed
numeric embeddings into the original continuous benchmark function. The comparison
covers one evolutionary solver; further variants, archive-truncating strategies and
surrogate-based mixed-variable methods are outside its scope.
