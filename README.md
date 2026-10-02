GWASToolKit
============
[![DOI](https://zenodo.org/badge/55601542.svg)](https://zenodo.org/badge/latestdoi/55601542)

[![Languages](https://skillicons.dev/icons?i=bash,r,py)](https://skillicons.dev)

GWASToolKit runs association analyses on imputed genotype data: genome-wide (GWAS), per variant,
per region, or per gene. It was written for the Athero-Express Genomics Study (AEGS) and is also
used for AAAGS and CTMMGS.

> **Status: rewrite in progress.** This branch (`snakemake-rewrite`) rebuilds GWASToolKit as a
> Python-based [Snakemake](https://snakemake.github.io) workflow, to be released as **v3.0.0**.
> So far the workflow runs the four modes (`GWAS`, `VARIANT`, `REGION`, `GENES`) with SNPTEST, up to
> and including the merged results tables. QC, plots, clumping and the other engines are not there
> yet. It has been tested on the simulated test data with a stand-in for SNPTEST, not yet with
> SNPTEST itself. For running analyses today, use the Bash scripts of **v1.4.4** (see below).

--------------

#### What v3 will be

One workflow, one configuration file, several association engines, one output format.

| Mode | What it does |
|---|---|
| `GWAS` | Genome-wide analysis, followed by QC, Manhattan and QQ plots, clumping and regional plots of the lead variants |
| `VARIANT` | Analysis of a list of variants, with per-variant plots and a summary table |
| `REGION` | Analysis of one region, with a regional association plot |
| `GENES` | Analysis of a list of genes ± a range, with regional association plots |

- **Engines:** [SNPTEST](https://www.chg.ox.ac.uk/~gav/snptest/) (default),
  [PLINK 2](https://www.cog-genomics.org/plink/2.0/) / PLINK 1.9, and
  [REGENIE](https://rgcgithub.github.io/regenie/). All results are converted to one standard table.
- **Post-GWAS harmonisation and QC:** [Harmonia](https://github.com/CirculatoryHealth/gwas2cojo).
- **Plots:** [GWASLab](https://github.com/Cloufield/gwaslab).
- **Cluster:** SLURM, through Snakemake; failed runs resume where they stopped.

The full list of changes is in [CHANGELOG.md](CHANGELOG.md).

--------------

#### The configuration file

All settings are in [config/config.yaml](config/config.yaml). Copy it to your project directory and
edit the copy.

The imputed datasets are listed once, under `datasets`. To switch dataset, change one line:

```yaml
analysis:
  dataset: "aegs_topmed_r3_b38_eur_nl"
```

Each dataset records its study, genome build, file format and chromosome naming. The genome build
of the chosen dataset decides which gene coordinates and LD reference are used, so data and
references are always of the same build.

| Dataset | Study | Build | Description |
|---|---|---|---|
| `aegs_topmed_r3_b38_eur_nl` (default) | AEGS | b38 | TOPMed r3; unrelated, European/NL-only (n = 1,989) |
| `aegs_topmed_r3_b38_unrelated` | AEGS | b38 | TOPMed r3; unrelated, all ancestries (n = 2,054) |
| `aegs_topmed_r3_b38_noneur_nonnl` | AEGS | b38 | TOPMed r3; unrelated, non-European/non-NL (n = 65) |
| `aegs_topmed_r3_b38_complete` | AEGS | b38 | TOPMed r3; complete, includes related and failed-QC samples |
| `aegs_topmed_r3_b38_complete_cleaned` | AEGS | b38 | As above; variants filtered on R2 > 0.9 and MAF > 0.001 |
| `aegs_1kgp3_hrc_r11_b37` | AEGS | b37 | 1000G phase 3 + HRC r1.1 combined |
| `aaags_1kgp3_gonl5_b37` | AAAGS | b37 | 1000G phase 3 + GoNL5 (IMPUTE2) |
| `aaags_1kgp3_b37` | AAAGS | b37 | 1000G phase 3 |
| `aaags_hrc_r11_b37` | AAAGS | b37 | HRC r1.1 |
| `ctmmgs_1kgp3_gonl5_b37` | CTMMGS | b37 | 1000G phase 3 + GoNL5 (IMPUTE2) |
| `ctmmgs_1kgp3_b37` | CTMMGS | b37 | 1000G phase 3 |
| `ctmmgs_hrc_r11_b37` | CTMMGS | b37 | HRC r1.1 |

--------------

#### Installation and the `gwastoolkit` command

You need [mamba](https://mamba.readthedocs.io) (or conda); we recommend installing it through
[Miniforge](https://github.com/conda-forge/miniforge).

**Step 1: get the code and switch to the rewrite branch.**

```
mkdir -p ~/git && cd ~/git
git clone https://github.com/swvanderlaan/GWASToolKit.git
cd GWASToolKit
git switch snakemake-rewrite
```

**Step 2: create the environment.** This installs Python, Snakemake (with the SLURM plugin),
bcftools, polars and GWASToolKit itself.

```
mamba env create -f environment.yml
```

**Step 3: activate it.** Do this every time you start a new terminal.

```
mamba activate gwastoolkit
```

**Step 4: check that it works.**

```
gwastoolkit --version
snakemake --version
bcftools --version
python -m unittest discover -s tests
```

The last command runs the tests and should end with `OK`.

To update an existing environment after `environment.yml` has changed:

```
mamba env update -f environment.yml --prune
```

> **Not installed by the environment:** SNPTEST, QCTOOL, PLINK and REGENIE. On the HPC these are
> already installed; their locations are set in the `site` section of the configuration file.

Every `gwastoolkit` command has a `--help`.

| Command | What it does |
|---|---|
| `gwastoolkit --help` | Overview, with examples |
| `gwastoolkit datasets` | List the datasets in the registry; filter with `--study` and `--build` |
| `gwastoolkit validate --config FILE` | Check a configuration file: misspelled settings, wrong values, settings that do not go together. Writes a dated log file next to the configuration file |
| `gwastoolkit validate --config FILE --check-files` | Also check that the files, directories and programs it names exist, and that the input files fit the configuration (run this on the cluster) |
| `gwastoolkit show --config FILE` | Show the analysis, dataset, references and output directory that follow from a configuration file |
| `gwastoolkit run --config FILE --dry-run` | Show every job and command that would be run, without running anything |
| `gwastoolkit run --config FILE` | Run the analysis on this machine (`--cores N` for N jobs at a time) |
| `gwastoolkit run --config FILE --slurm` | Run the analysis, submitting the jobs to SLURM |
| `gwastoolkit make-gene-list` | Make the gene coordinate files for builds 37 and 38 (once per installation; needed for mode `GENES`) |
| `gwastoolkit find-variants --config FILE --variants ID [ID ...]` | Check, with bcftools, whether variants are in the genotype data; `--file` takes a list or a conditioning file |

--------------

#### Running an analysis

`gwastoolkit run` starts [Snakemake](https://snakemake.github.io) with the workflow in
[workflow/Snakefile](workflow/Snakefile), which is written to be read: it explains the few Snakemake
ideas it uses. Results that already exist are not made again, so after a failure the same command
continues where it stopped. The SLURM settings are in [profiles/slurm/config.yaml](profiles/slurm/config.yaml);
memory and run time per step are set in the Snakefile.

**What is analysed.** Each mode has one or more *targets*:

| Mode | Target(s) | Set in the configuration with |
|---|---|---|
| `GWAS` | `gwas`: all chromosomes of the dataset | — |
| `VARIANT` | `variants`: the listed variants, looked up by position | `targets.variant_file` |
| `REGION` | one region, named for example `chr1_154376264_154476264` | `targets.region` |
| `GENES` | one target per gene: the gene ± `targets.range` base pairs | `targets.gene_file`, `targets.range` |

For `VARIANT`, `REGION` and `GENES` the targets are first extracted from the genotype data with
bcftools, once, into a small file; SNPTEST then runs on that small file. (With an index next to the
genotype files, `.tbi` or `.csi`, the extraction takes seconds; without one bcftools reads through
each file once.) The exception is a conditional analysis: the variants to condition on must be in
the file SNPTEST reads, so SNPTEST then reads the whole chromosome, limited to the targets with `-range`.

Results are written to `<project.dir>/<project.name>/`, in a sub-directory per target:

| Directory | Contents |
|---|---|
| `extract/<target>/` | The extracted genotypes (`VARIANT`, `REGION`, `GENES`) |
| `raw/<target>/` | Results as the engine wrote them |
| `chunks/<target>/` | The same results per chromosome, as standard tables |
| `results/<target>/` | The final tables, each as `.summary.tsv.gz` and `.summary.parquet`: one per phenotype (`<target>.<phenotype>.<exclusion>.<engine>`), and for `VARIANT`, `REGION` and `GENES` also one with all phenotypes together (`<target>.ALL_PHENOTYPES...`) |
| `logs/` | One log file per job |

The standard table has the same columns whatever engine was used: `phenotype`, `engine`,
`variant_id`, `chr`, `pos`, `effect_allele`, `other_allele`, `eaf`, `maf`, `mac`, `n`, `info`,
`beta`, `se`, `z`, `p`, `hwe_p`, `alt_id`, `avg_max_post_call`, `all_aa`, `all_ab`, `all_bb`,
`model_status`. In the genotype counts A is the other allele and B the effect allele; these five
columns are kept from v1.x and are `NA` for engines that do not report them.

The Parquet file holds the same table with typed columns and loads much faster than the text file.
Read it with `pandas.read_parquet("gwas.BMI.EXCL_DEFAULT.snptest.summary.parquet")`; the resulting table
can be given to [GWASLab](https://github.com/Cloufield/gwaslab) directly.

--------------

#### Settings and checks

**SNPTEST method.** With `analysis.method: "auto"` (the default), mode `GWAS` uses `expected` and
the modes `VARIANT`, `REGION` and `GENES` use `newml`. Set `expected`, `score` or `newml` to choose yourself.

**Phenotype scaling.** `analysis.standardize` is `RAW` (as in the sample file), `STANDARDIZE`
(quantile-normalised) or `SCALE` (mean 0, variance 1).

**Checks before anything runs.** `gwastoolkit run` (and `gwastoolkit validate --check-files`) checks
that the phenotypes, the covariates and the exclusion column are in the sample file, that a
`baseline_phenotype` is a value that occurs for every phenotype, and that a conditioning file is well-formed.

Two things are left to you: whether the baseline phenotype is a sensible category, and whether the
variants you condition on are in the genotype data. For the second, run
`gwastoolkit find-variants --config FILE` before the analysis: without further options it looks for
the variants in `analysis.condition_file`. It ends with an error if one is not found.

**One mode per run.** A configuration file sets one mode. To run several modes on the same project,
use one configuration file per mode; they can share a project directory, because results are kept
in a sub-directory per target.

**Gene coordinates.** Mode `GENES` needs a file with gene coordinates for the genome build of the
dataset, set under `references.<build>.genes`. Make the files for builds 37 and 38 once per
installation (this needs internet access):

```
gwastoolkit make-gene-list
```

This downloads the [GENCODE](https://www.gencodegenes.org) gene annotation of the human reference
genome, release 47 (for b37 the same release mapped to GRCh37, so both builds hold the same genes),
checks it against the published checksum, and writes `RESOURCES/genes.gencode_v47.b38.txt.gz` and
`RESOURCES/genes.gencode_v47lift37.b37.txt.gz`, each with an `.info.txt` that records the source.
The same release always gives identical files. Without internet access, give a downloaded file
with `--gtf FILE --build b38`. To keep only some gene types, add for example
`--gene-types protein_coding`; the types become part of the file name
(`genes.gencode_v47.protein_coding.b38.txt.gz`), and you choose the list to use in the configuration.

You can also use your own file: plain text (may be gzipped), no header, columns separated by spaces
or tabs, the first four being `chromosome start end symbol`, for example
`19 11089463 11133820 LDLR`. The chromosome may be written with or without `chr`. PLINK's gene
lists (`glist-hg19`, `glist-hg38`) have this layout.

**E-mail from SLURM.** Set your address and when to be mailed in the `slurm` section of the
configuration (`email`, and `mail_type`: `NONE`, `BEGIN`, `END`, `FAIL`, `REQUEUE`, `ALL`, or a
combination such as `END,FAIL`). SLURM mails per job, so `FAIL` is the sensible choice for a GWAS.

--------------

#### Test data

[tests/data](tests/data) holds a small, fully simulated dataset (500 samples, two chromosomes,
about 0.2 Mb) with a matching configuration file, so that everything can be tried without real
data. One variant per chromosome has a planted effect. See [tests/data/README.md](tests/data/README.md).

```
gwastoolkit show --config tests/data/config.test.yaml
gwastoolkit run --config tests/data/config.test.yaml --dry-run
gwastoolkit find-variants --config tests/data/config.test.yaml --variants chr21:20235673:G:T
```

The test configuration is set to mode `GWAS`; change `analysis.mode` to `VARIANT`, `REGION` or
`GENES` to try the other modes (the variant list, region and gene list are already filled in).

A real run on the test data needs SNPTEST (set its location under `site.snptest` in the
configuration). The tests use a stand-in, [tests/stubs/fake_snptest.py](tests/stubs/fake_snptest.py),
which writes files in SNPTEST's layout; it is for testing only.

--------------

#### Using v1.4.4 (Bash scripts)

The Bash scripts are tagged as `v1.4.4`. On this branch they have been moved, unchanged, to
[_archive_old_workflow/](_archive_old_workflow), together with their configuration file and helper
scripts. They need SLURM, SNPTEST v2.5.4+, PLINK, LocusZoom v1.3 and R.

To run them from the archive, set `GWASTOOLKITDIR` in `gwastoolkit.conf` to the full path of the
`_archive_old_workflow` directory, edit the other settings, then run:

```
bash _archive_old_workflow/gwastoolkit.run.sh $(pwd)/_archive_old_workflow/gwastoolkit.conf
```

> Note: give the full path to the configuration file (hence `$(pwd)`); the scripts use it to
> create directories and to submit the follow-up jobs.

--------------

#### Roadmap to v3.0.0

- [x] Configuration file with a dataset registry
- [x] Validation of the configuration, and a `gwastoolkit` command with a proper `--help`
- [x] A small, simulated test dataset
- [x] Workflow for `GWAS` with SNPTEST: standard table, merge, Parquet
- [x] `VARIANT`, `REGION` and `GENES` modes, extracting the targets once
- [ ] Check the SNPTEST step (methods `expected` and `newml`) against real SNPTEST output on the HPC
- [x] Gene coordinates for b37 and b38 (`gwastoolkit make-gene-list`)
- [ ] Shared preparation: format conversion and a b38 LD reference
- [ ] Engine adapters: PLINK 2, PLINK 1.9, REGENIE (SNPTEST is done)
- [ ] `GWAS` mode with Harmonia and GWASLab
- [ ] Clumping and per-variant plots
- [ ] Validation against v1.4.4, then retiring the Bash scripts
- [ ] Wiki

--------------

#### The MIT License (MIT)
##### Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.
