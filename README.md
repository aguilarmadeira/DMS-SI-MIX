# DMS-SI-Mix — Reproducibility Package

Reproducibility package for the two-space scale-invariant Direct Multisearch
method **DMS-SI-Mix**, supporting the article

> J. F. A. Madeira, *A Two-Space Scale-Invariant Direct Multisearch Method for
> Mixed-Variable Multiobjective Optimization.*

---

## Scope of this release

> **Version 1.0.0 contains the data, configurations, results, and validation
> scripts. It does not contain the MATLAB solver.**
>
> The DMS-SI-Mix implementation is added in **version 1.1.0**, published on
> acceptance of the article. Until then the solver is available to reviewers on
> request through the journal editor.

Everything needed to *check* the reported numbers is here; what is deferred is
the implementation that produced them.

## Layout

```
DMS-SI-Mix/
├── README.md
├── LICENSE
├── CITATION.cff
├── data/
│   ├── B2/              controlled mixed-variable ablation instances
│   └── MORAP_NM/        problem data, exhaustive enumeration script,
│                        frozen 578-point exact Pareto front
├── results/
│   ├── logs/            per-poll logs
│   ├── archives/        final nondominated archives per run
│   └── metrics/         metric tables, anytime curves,
│                        relabeling and reindexing checks
├── configurations/      parameter files, one per reported run
├── supplementary/       supplementary material of the article
└── MANIFEST.txt         file inventory with integrity hashes
```

## Verifying the results without the solver

Version 1.0.0 is designed so that the central empirical claims can be checked
independently:

**The MORAP-NM exact-front claims.** Re-run the enumeration script in
`data/MORAP_NM/` to regenerate the exact Pareto front, and check it against its
hash in `MANIFEST.txt`. Then recompute recall, precision, IGD and the
hypervolume gap from the archives in `results/archives/` against that front,
using the common reference point construction documented in the article. The
reference point is built once from the union of the exact front and the final
archives of all compared variants, so the three hypervolume gaps are directly
comparable.

**The ablation and metric tables.** Every table in `results/metrics/` can be
recomputed from the archives in `results/archives/`. No table reports a quantity
that is not derivable from the published archives.

**Run provenance.** Each archive in `results/archives/` corresponds to exactly
one parameter file in `configurations/`, and every file is listed with its hash
in `MANIFEST.txt`. This is what pins the reported numbers to the runs that
produced them.

Re-running the optimizer itself requires the solver, added in v1.1.0.

## Citing

Cite the **concept DOI**, which covers all versions of this package and remains
valid when the solver is added:

```
[concept DOI — fill in after the first Zenodo release]
```

The version-specific DOI of the exact package that supported the submission:

```
[v1.0.0 DOI — fill in after the first Zenodo release]
```

Use the version DOI when you need the exact bytes; use the concept DOI when you
mean the package as an evolving artifact.

## Environment

Runs were produced in MATLAB. The MATLAB version and the code revision used for
the reported runs are recorded at the top of `MANIFEST.txt`.

## Related

Benchmark suites used in this work are archived separately:
[`MOO_Prob_Matlab`](https://doi.org/10.5281/zenodo.20783714) — continuous and
mixed-variable MATLAB benchmark suites.

## License

Data, configurations, results, and documentation in this release are licensed
CC-BY-4.0 (see `LICENSE`). The MATLAB solver added in v1.1.0 carries its own
license, stated in that release.

## Funding

Fundação para a Ciência e a Tecnologia (FCT), Portugal, through IDMEC, under
LAETA, project UID/50022/2025.
