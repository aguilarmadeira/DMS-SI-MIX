# supplementary — index

The article refers the reader to "the supplementary material" in four places.
This index maps each reference to the file in this release that answers it.

| Where the article says it | What it refers to | Where it is |
|---|---|---|
| §5.3 | Complete per-run records: new black-box evaluations, cache hits, boundary-degenerate trials, stopping reasons | `results/archives/*/*.mat`, field `State.PollLog` — documented in `results/logs/README.md` |
| §5.3 | The CC-static control separating the fixed-geometry effect from the rotation effect | `results/metrics/b2_decomposition.csv`, produced by `results/metrics/b2_effect_decomposition.m` from the `cc_static` archives in `results/archives/b2_default/` |
| §5.4 | The complete anytime curves | `results/metrics/b3_anytime_curves.csv`, produced by `results/metrics/b3_anytime_morap_nm.m` |
| §5.4 | Detailed reindexing results and the poll-level relabeling-conformity trace | `results/archives/morap_nm/b3b_results.mat`, with `results/metrics/b3b_indexing_morap_nm.m` and `results/metrics/b3a_conformity_morap_nm.m` |

## Material beyond what the article discusses

This release also contains results the article does not report:

**Initial-design sensitivity of the categorical ablation.**
`results/metrics/b2_init_sensitivity.csv`, with the corresponding archives in
`results/archives/b2_sobol50/` and `results/archives/b2_halton200/`, repeats
the ablation under three initial designs (the default, a 50-point Sobol
design, and a 200-point Halton design). The structural cost result — that the
Fixed and CC-DNR variants have identical nominal poll cardinality — is
invariant across all three designs. The hypervolume ranking is not: the
per-problem winner changes with the initial design on five of the six
instances, so the ranking reported in the article should be read as holding
for the stated initial design, not as a design-independent ordering.

**The four categorical-schedule modes.**
`results/archives/morap_nm/dnr_run*.mat` holds the identity, covering-cycles,
Sobol-rank and affine schedules run on MORAP-NM, with the schedules
themselves in `configurations/b3_dnr_*.mat`. Only the covering-cycles
schedule carries the finite-period covering guarantee that the theory
requires; the other three are included as controls.

## A note on the hypervolume reference points

The three categorical-ablation tables in `results/metrics/` do not share a
hypervolume reference point, and their HV columns are therefore not
comparable with one another. Each builds a union reference front over the
runs it loads, and each loads a different set: `b2_summary.csv` over the
three variants of a pair, `b2_decomposition.csv` over all four variants
including CC-static, and `b2_init_sensitivity.csv` over all variants of all
three initial designs. This is why the same run appears with three different
HV values across the three files. Differences *within* a table are the
meaningful quantity. The MORAP-NM tables are separate again: they use the
common reference of `morap_common_reference_metrics.m`, derived from the
exact front. Full detail is in the header comment of each script.
