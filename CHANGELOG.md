# Changelog

All notable changes to GWASToolKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) from v3.0.0 onwards.

> **A note on version numbers.** The repository carries the tags `v0.9`, `v1.0`, `v1.1`, `v2.0`,
> `v2.1` and `v2.2` (2017–2020), while the scripts themselves counted on separately and reached
> v1.4.4 in 2026. To avoid a clash with the existing `v2.x` tags, the Snakemake/Python rewrite is
> released as **v3.0.0**. Entries below v3.0.0 were reconstructed from the git history.

## [Unreleased] — towards 3.0.0

Rewrite of GWASToolKit as a Python-based Snakemake workflow, developed on the branch
`snakemake-rewrite`. The Bash scripts of v1.4.4 are kept in `_archive_old_workflow/` until the
rewrite is validated. Not yet rebuilt: QC filtering, plots, clumping, and the engines other than SNPTEST.

### Added
- `config/config.yaml`: a YAML configuration that replaces the sourced Bash file `gwastoolkit.conf`.
  - A **dataset registry** (`datasets`) holding all imputed datasets of AEGS, AAAGS and CTMMGS.
    Switching dataset is a one-line change (`analysis.dataset`). The default is
    `aegs_topmed_r3_b38_eur_nl` (TOPMed r3, b38; unrelated, European/NL-only; n = 1,989).
  - Each dataset records its genome build, file format and chromosome naming; reference files
    (gene coordinates, LD reference) are chosen per build (`references`).
  - Software locations (`site`) are separated from analysis settings.
- `gwastoolkit` Python package with a command-line interface (`gwastoolkit --help`):
  - `validate`: checks a configuration file (unknown or misspelled settings, wrong values, settings
    that do not go together) and reports all problems at once; `--check-files` also checks that the
    files, directories and programs it names exist. Writes a dated log file next to the configuration.
  - `datasets`: lists the dataset registry, optionally per study and genome build.
  - `show`: shows the analysis, dataset, references and output directory that follow from a configuration.
  - `run`: runs the analysis through Snakemake, on this machine or on SLURM (`--slurm`);
    `--dry-run` shows every job and command without running anything.
- `workflow/Snakefile`: the Snakemake workflow. So far, with SNPTEST: the modes `GWAS`, `VARIANT`,
  `REGION` and `GENES`, conversion to the standard table, one merged table per target and phenotype,
  and for the targeted modes one table with all phenotypes together.
- `gwastoolkit/targets.py`: variants, regions and genes (± range) are extracted from the genotype
  data once with bcftools; SNPTEST runs on the small extracted file. v1.x started one job per variant
  or gene, each reading a whole chromosome. Variant lists may have a header naming the chromosome and
  position columns; variants are looked up by position.
- Input checks before anything runs: phenotypes, covariates and exclusion column must be in the sample
  file, `baseline_phenotype` must be a value that occurs, and the conditioning file must be well-formed.
- `analysis.standardize: "SCALE"`: phenotypes scaled to mean 0 and variance 1 (SNPTEST's default),
  next to `RAW` and `STANDARDIZE`.
- Results are organised per target: `results/gwas/`, `results/variants/`, `results/<region>/` or
  `results/<gene>/`, with matching `extract/`, `raw/`, `chunks/` and `logs/` directories.
- `site.bcftools`: the bcftools program used for extraction and for `find-variants` (default: `bcftools`).
- `profiles/slurm/config.yaml`: Snakemake profile for SLURM.
- `gwastoolkit/engines.py`: the SNPTEST command is built in one place (v1.x repeated it about fifteen
  times), so conditional analysis, method and phenotype scaling now work the same in every mode.
- `gwastoolkit/schema.py` and `gwastoolkit/adapters/snptest.py`: the standard results table, and the
  conversion of SNPTEST output to it. Columns are selected by name, never by position.
- `gwastoolkit find-variants` (`gwastoolkit/find_variants.py`): checks with bcftools whether variants,
  for example those of a conditioning file, are present in the genotype data.
- `gwastoolkit make-gene-list` (`gwastoolkit/make_gene_list.py`): makes the gene coordinate files for
  builds 37 and 38 from the GENCODE annotation (release 47; b37 from the same release mapped to
  GRCh37), with a checksum check and an `.info.txt` recording the source. `--gene-types` restricts
  the list and is reflected in the file name. Replaces `resource.creator.sh`, whose parser script
  was not in the repository.
- The standard table keeps five columns of the v1.x summary: `alt_id` (ALTID), `avg_max_post_call`
  (AvgMaxPostCall), `all_aa`, `all_ab` and `all_bb`.
- `gwastoolkit/merge.py`: merges standard tables.
- `gwastoolkit/to_parquet.py`: every final table is also written as Parquet (typed columns, fast to
  load in pandas, polars, R and GWASLab).
- SLURM e-mail notifications: `slurm.email` and `slurm.mail_type` (one type, or several such as
  `END,FAIL`) are passed to every job.
- `analysis.method: "auto"` (the new default): SNPTEST method `expected` for mode `GWAS`, `newml`
  for the modes `VARIANT`, `REGION` and `GENES`.
- `tests/stubs/fake_snptest.py`: a stand-in for SNPTEST, so the workflow can be tested without it.
- Datasets can list the chromosomes they have files for (`chromosomes`), default 1-22.
- `gwastoolkit/config.py`: the configuration schema (pydantic).
- `tests/`: tests for the configuration, the command-line interface, the adapter and the workflow.
- `tests/data/`: a small, fully simulated test dataset (500 samples, chromosomes 21 and 22, VCF
  with `GT:DS:GP`, SNPTEST sample file, target lists, planted effects for `BMI` and `T2D`), its
  generator `make_test_data.py`, a matching configuration `config.test.yaml`, and tests.
- `pyproject.toml` and `environment.yml` (Python, Snakemake with the SLURM plugin, bcftools, polars) for
  installation; installation instructions in the README.
- `CHANGELOG.md` (this file).

### Changed
- `README.md` rewritten: describes the rewrite and its status, and corrects the entry point of the
  v1.x scripts (`gwastoolkit.run.sh`).
- The frequency filter is expressed as a minimum minor allele frequency (`qc.min_maf`), where v1.x
  filtered on the coded allele frequency only.
- Sample exclusion is given as a column and a value, no longer as a literal SNPTEST flag. It is
  passed to SNPTEST as `column=value` (a single `=`), the only spelling that both v2.5.4 and v2.5.6
  accept; the `column==value` of v1.x is refused by SNPTEST v2.5.6.
- Results tables are tab-separated and use the standard column names; v1.x wrote space-separated
  tables with its own names (`RSID`, `CodedAlleleB`, `CAF`, ...).
- Allele frequencies and the minor allele count are computed over the called genotypes
  (`all_AA + all_AB + all_BB`); v1.x divided by `all_total`. For imputed data these are the same.
- A conditional analysis in the modes `VARIANT`, `REGION` and `GENES` does not extract the targets:
  SNPTEST reads the whole chromosome, limited with `-range`, because the variants to condition on
  may lie outside the targets.
- Default gene coordinates for b37 are the GENCODE list made by `make-gene-list`; v1.x used PLINK's
  `glist-hg19.gz`, which still works.
- `-baseline_phenotype` is only passed to SNPTEST when `analysis.baseline_phenotype` is set; v1.x
  always passed it with method `newml`.
- The raw/quantile-normalise option for phenotypes is passed to SNPTEST with every method; v1.x
  left it out with method `newml`.
- The v1.4.4 workflow was moved, unchanged, to `_archive_old_workflow/`: all `gwastoolkit.*.sh`
  scripts, `summariser.sh`, `resource.creator.sh`, `gwastoolkit.conf`, `SCRIPTS/` and `ARCHIVED/`.
  It still runs from there when `GWASTOOLKITDIR` points to that directory.
- `.gitignore`: `.claude/`, `claude/`, Python caches and `*.gwastoolkit.log` are ignored.

### Removed
- From the configuration: per-step SLURM memory and time variables (`QMEM*`, `QTIME*`; these move
  to the workflow rules), personal directory paths, and the hard-coded REGENIE PGEN location (the
  workflow will create the PGEN files itself).

## [1.4.4] — 2026-01-21

Final release of the Bash/SNPTEST-based toolkit (tag `v1.4.4`).

### Changed
- Updates to accommodate REGENIE and SNPTEST v2.5.6.
- Updated references to the sample file in the configuration.

## 1.3.9 and later (untagged) — 2023-09 to 2024-09

### Added
- Basic REGENIE support for GWAS: PLINK-based QC, step 1, step 2 and a wrapper (2024-09).
- `SCRIPTS/liftover.py` to convert a list of coordinates between genome builds (2024-04).
- `SCRIPTS/alt_models.py` and `SCRIPTS/alt_models_summarize.py` for interaction, genotypic,
  dominant and recessive models (2024-04).
- Build 37 example variant list (2024-06).

### Changed
- Default data switched to TOPMed-imputed, build 38 VCF files (2024-05).
- SNPTEST reads genotype probabilities (`GP`) from VCF, so INFO is no longer always 1 (v1.3.9, 2024-06).
- Plots are written as PNG only (2023-11).
- Exclusion lists replaced by SNPTEST's `-exclude_samples_where`; configuration cleaned up (2023-09).

### Fixed
- Several fixes to the per-gene analysis (2024-04).

## 2021 to 2022 (untagged)

### Changed
- Added a reference to SNPTEST v2.5.6 (2021-11).

### Fixed
- Variants with INFO = 1 were filtered out (2022-10).
- A faulty `awk` statement (2021-10).

## [2.2] / [1.1] — 2020-12-07

### Changed
- Job submission moved from SGE (`qsub`) to SLURM (`sbatch`); references to SGE removed.

## [2.1] — 2017-09-27

### Changed
- Documentation updates.

## [2.0] / [1.0] / [0.9] — 2017-08-24

### Added
- Conditional analysis (SNPTEST `-condition_on`) and the matching configuration settings.

[Unreleased]: https://github.com/swvanderlaan/GWASToolKit/compare/v1.4.4...snakemake-rewrite
[1.4.4]: https://github.com/swvanderlaan/GWASToolKit/compare/v2.2...v1.4.4
[2.2]: https://github.com/swvanderlaan/GWASToolKit/compare/v2.1...v2.2
[1.1]: https://github.com/swvanderlaan/GWASToolKit/releases/tag/v1.1
[2.1]: https://github.com/swvanderlaan/GWASToolKit/compare/v2.0...v2.1
[2.0]: https://github.com/swvanderlaan/GWASToolKit/releases/tag/v2.0
[1.0]: https://github.com/swvanderlaan/GWASToolKit/releases/tag/v1.0
[0.9]: https://github.com/swvanderlaan/GWASToolKit/releases/tag/v0.9
