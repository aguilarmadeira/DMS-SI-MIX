# data/MORAP_NM — no-mixing reliability allocation instance

Problem data and exact-front artifacts for the MORAP-NM study.

Expected contents:

- the MORAP-NM component data defining the instance;
- the exhaustive enumeration script that produces the exact Pareto front
  (`enumerate_pareto.m` or equivalent);
- the frozen exact Pareto front: 578 decision points with distinct objective
  vectors (`morap_nm_exact_front.csv`) and the corresponding decision file
  (`morap_nm_exact_front_decisions.csv`).

The front published here is the one used to compute the recall, precision, IGD
and hypervolume-gap figures reported in the article. Its SHA-256 hash is
recorded in `MANIFEST.txt` at the repository root; a reader who re-runs the
enumeration should obtain a file with that hash.
