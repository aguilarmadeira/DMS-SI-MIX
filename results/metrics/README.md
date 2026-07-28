# results/metrics — metric tables, anytime curves, invariance checks

Derived results. Nothing here is primary data: every file must be reproducible
from `results/archives/` together with the exact front in `data/MORAP_NM/`.

Expected contents:

- metric tables: hypervolume, IGD, recall, precision, pair coverage, evaluation
  counts and nominal poll sizes (e.g. `b2_summary.csv`);
- anytime curves (e.g. `b3_anytime_curves.csv`);
- the relabeling and reindexing checks: categorical relabelings should produce
  identical canonical trajectories, as predicted by the representation-invariance
  theorem, while different schedules produce bounded variation. Keep the two
  separate: the first is a correctness check of the theorem in the released
  code, the second is a sensitivity result.

State, for each table, the reference-point construction used, so the numbers are
comparable in the same way as in the article.
