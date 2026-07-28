# supplementary — index

The article refers the reader to "the supplementary material" in six places.
This index maps each reference to the file in this release that answers it.

| # | Where the article says it | What it promises | Where it is |
|---|---|---|---|
| 1 | Table 3 caption (§5.2) | Full per-strategy hypervolume profiles π(τ) and the corresponding tables for configurations C1 and C2 | **Not included in v1.0.0** — see note below |
| 2 | §5.2, end | Detailed per-strategy profiles π(1.001) and π(2) for C1 and C2 | **Not included in v1.0.0** — see note below |
| 3 | §5.3 | Complete per-run records: new black-box evaluations, cache hits, boundary-degenerate trials, stopping reasons | `results/archives/*/…​.mat`, field `State.PollLog` — documented in `results/logs/README.md` |
| 4 | §5.3 | The CC-static control separating the fixed-geometry effect from the rotation effect | `results/metrics/b2_decomposition.csv`, produced by `results/metrics/b2_effect_decomposition.m` from the `cc_static` archives in `results/archives/b2_default/` |
| 5 | §5.4 | The complete anytime curves | `results/metrics/b3_anytime_curves.csv`, produced by `results/metrics/b3_anytime_morap_nm.m` |
| 6 | §5.4 | Detailed reindexing results and the poll-level relabeling-conformity trace | `results/archives/morap_nm/b3b_results.mat`, with `results/metrics/b3b_indexing_morap_nm.m` and `results/metrics/b3a_conformity_morap_nm.m` |

## Note on items 1 and 2

Items 1 and 2 concern the **continuous** 108-benchmark suite of Section 5.2.
Those per-strategy hypervolume profiles are not part of this release, which
covers the mixed-variable ablation and the MORAP-NM study. They must either be
added here before the article is submitted, or the two sentences in the article
that promise them must be changed to point at what is actually published.

Leaving them as they stand would send a reader to a file that does not exist.

## Beyond what the article promises

This release also contains material the article does not currently discuss:

- `results/metrics/b2_init_sensitivity.csv` — the categorical-ablation results
  under three initial designs (default, `b2_sobol50`, `b2_halton200`), with the
  corresponding archives in `results/archives/b2_sobol50/` and
  `results/archives/b2_halton200/`. The structural cost result (Fixed and
  CC-DNR have identical nominal poll cardinality) is invariant across the three
  designs; the hypervolume ranking is not.
- `results/archives/morap_nm/dnr_run*.mat` — the four categorical-schedule
  modes (identity, covering cycles, Sobol-rank, affine), with the schedules
  themselves in `configurations/`.
