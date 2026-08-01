# DMS-SI-Mix — Reproducibility Package

Reproducibility package for the two-space scale-invariant Direct Multisearch method **DMS-SI-Mix**, supporting the article

> J. F. A. Madeira, *A Two-Space Scale-Invariant Direct Multisearch Method for Mixed-Variable Multiobjective Optimization.*

---

## Scope of this release

> **Version 1.1.0 contains the data, configurations, results, validation scripts, and the
> external NSGA-II reference point. It does not contain the MATLAB solver.**
>
> The DMS-SI-Mix implementation is added in **version 2.0.0**, published on acceptance of
> the article. Until then the solver is available to reviewers on request through the
> journal editor.

Everything needed to *check* the reported numbers is here; what is deferred is the
implementation that produced them. The external NSGA-II reference in `nsga2_reference/`
is the one part of the package that is fully executable today: it is Python, it is
public, and it does not depend on the embargoed solver.

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
├── nsga2_reference/     external NSGA-II reference point on MORAP-NM
│                        (Python, self-contained; see its own README.md)
├── supplementary/       supplementary material of the article
└── MANIFEST.txt         file inventory with integrity hashes
```

## Verifying the results without the solver

Version 1.1.0 is designed so that the central empirical claims can be checked
independently:

**The MORAP-NM exact-front claims.** Re-run the enumeration script in `data/MORAP_NM/` to
regenerate the exact Pareto front, and check it against its hash in `MANIFEST.txt`. Then
recompute recall, precision, IGD and the hypervolume gap from the archives in
`results/archives/` against that front, using the common reference point construction
documented in the article. The reference point is built once from the union of the exact
front and the final archives of all compared variants, so the three hypervolume gaps are
directly comparable.

**The ablation and metric tables.** Every table in `results/metrics/` can be recomputed
from the archives in `results/archives/`. No table reports a quantity that is not
derivable from the published archives.

**Run provenance.** Each archive in `results/archives/` corresponds to exactly one
parameter file in `configurations/`, and every file is listed with its hash in
`MANIFEST.txt`. This is what pins the reported numbers to the runs that produced them.

Re-running the optimizer itself requires the solver, added in v2.0.0.

## External NSGA-II reference point

`nsga2_reference/` holds the mixed-variable NSGA-II baseline reported in Section 5.4 and
in Appendix A.4 of the article: nine configurations × 30 seeds × 6 checkpoints, 1620
result rows, run on the same MORAP-NM instance, against the same frozen 578-point exact
front, under the same budget semantics.

It is reproducible end to end without any MATLAB:

```bash
cd nsga2_reference
python3 nsga2_morap_v3.py <pop> 30 <rand|halton|paired>   # resumable, per seed
python3 audit_initial.py           # -> init_audit.csv
python3 audit_definitive.py        # package integrity; exit 0 = ok
python3 aggregate_definitive.py    # -> summary, oracle envelope, init control
python3 make_figure_definitive.py  # -> Fig_MORAP_NM_definitive.pdf
```

`audit_definitive.py` is a real gate, not a report: it exits non-zero if the row count,
the (seed, checkpoint) product, the value domains, the Hypervolume reference payload, the
initial-population cardinalities or the rand-100 non-regression test fail.

> **The Hypervolume reference used there is not the one used in Table 6 of the article.**
> `nsga2_reference/` uses `r = z_nad + 0.1 (z_nad − z_ideal)` computed from the exact
> front *alone*, which makes it independent of any run and permanently comparable across
> methods. Table 6 uses a reference built from the union with the final archives. Recall,
> precision and IGD are reference-independent and are directly comparable as published;
> the Hypervolume column is not. `recompute_dms_hv.py` is provided for anyone who wants
> to place both methods on the run-independent reference.

Details, protocol and the initialization control are documented in
[`nsga2_reference/README.md`](nsga2_reference/README.md).

## Citing

Cite the **concept DOI**, which covers all versions of this package and remains valid when
the solver is added:

```
10.5281/zenodo.21671272
```

The version-specific DOIs:

```
v1.0.0   10.5281/zenodo.21671273
v1.1.0   minted on release; see the Zenodo record
```

Use the version DOI when you need the exact bytes; use the concept DOI when you mean the
package as an evolving artifact. The article cites the concept DOI.

## Environment

The MATLAB runs were produced in MATLAB; the MATLAB version and the code revision used
for the reported runs are recorded at the top of `MANIFEST.txt`. The NSGA-II reference was
produced in Python 3.11.15 with `pymoo` 0.6.2.

## Related

Benchmark suites used in this work are archived separately:
[`MOO_Prob_Matlab`](https://doi.org/10.5281/zenodo.20783714) — continuous and
mixed-variable MATLAB benchmark suites.

## License

Data, configurations, results, the NSGA-II reference package, and documentation in this
release are licensed CC-BY-4.0 (see `LICENSE`). The MATLAB solver added in v2.0.0 carries
its own license, stated in that release.

## Funding

Fundação para a Ciência e a Tecnologia (FCT), Portugal, through IDMEC, under LAETA,
project UID/50022/2025.
