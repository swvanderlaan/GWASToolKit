"""
Building the command lines of the association engines.

Each engine has ONE function here that turns the configuration into a command.
The workflow calls these functions, so a change to how an engine is run is made
in one place only (GWASToolKit v1.x repeated the SNPTEST command about fifteen
times, once for every combination of settings).

See the commands that would be run, without running anything, with:
    gwastoolkit run --config <file> --dry-run

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import os
import shlex
from typing import List, Optional

from gwastoolkit.config import Config, read_list

VERSION_NAME = "GWASToolKit engines"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"


def _join(arguments: List[str]) -> str:
    """Turn a list of arguments into one shell command, quoting where needed."""
    return " ".join(shlex.quote(str(argument)) for argument in arguments)


def snptest_command(
    config: Config,
    phenotype: str,
    chromosome: str,
    output: str,
    genotypes: Optional[str] = None,
    variant_ranges: Optional[List[str]] = None,
) -> str:
    """
    The SNPTEST command for one phenotype on one genotype file.

    Parameters
    ----------
    config : Config
        The validated configuration.
    phenotype : str
        Name of the phenotype (a column in the sample file).
    chromosome : str
        The chromosome analysed (1-22 or X); decides the genotype and sample file.
    output : str
        Where SNPTEST writes its results (`-o`).
    genotypes : str, optional
        Genotype file to use instead of the dataset's file for this chromosome,
        for example a small file with extracted variants.
    variant_ranges : list of str, optional
        Restrict the analysis to these base pair ranges, each as 'start-end' (`-range`).

    Returns
    -------
    str
        The command, ready to be run by a shell.
    """
    analysis = config.analysis
    dataset = config.active_dataset
    is_chromosome_x = str(chromosome).upper() == "X"

    if genotypes is None:
        genotypes = dataset.path_for(chromosome)
    sample_file = config.sample_file
    if is_chromosome_x and analysis.sample_file_chrx:
        sample_file = analysis.sample_file_chrx

    arguments = [config.site.snptest, "-data", genotypes, sample_file]

    # VCF files: tell SNPTEST which field holds the genotype probabilities.
    if dataset.format.startswith("vcf"):
        arguments += ["-genotype_field", dataset.genotype_field]

    # The test: additive model (-frequentist 1) with the chosen method.
    # `config.method` is the method given, or for "auto": expected for GWAS, newml for the other modes.
    arguments += ["-pheno", phenotype, "-frequentist", "1", "-method", config.method]

    # For categorical phenotypes with more than two categories (method newml):
    # the category the others are compared against.
    if analysis.baseline_phenotype:
        arguments += ["-baseline_phenotype", analysis.baseline_phenotype]

    # Continuous phenotypes: as they are (RAW), quantile-normalised (STANDARDIZE),
    # or scaled to mean 0 and variance 1 (SCALE), which is what SNPTEST does
    # when neither option is given.
    if analysis.standardize == "RAW":
        arguments += ["-use_raw_phenotypes"]
    elif analysis.standardize == "STANDARDIZE":
        arguments += ["-quantile_normalise_phenotypes"]

    arguments += ["-hwe", "-lower_sample_limit", analysis.lower_sample_limit]

    covariates = read_list(analysis.covariate_file)
    if covariates:
        arguments += ["-cov_names"] + covariates

    # Leave out the samples for which the exclusion column has the exclusion value.
    if analysis.exclusion_column:
        arguments += ["-exclude_samples_where", f"{analysis.exclusion_column}=={analysis.exclusion_value}"]

    # Conditional analysis: the file holds e.g. `rsid1 add rsid2 add`.
    if analysis.condition:
        arguments += ["-condition_on"] + read_list(analysis.condition_file)

    if variant_ranges:
        arguments += ["-range"] + list(variant_ranges)

    arguments += ["-o", output]
    return _join(arguments)


def bcftools_extract_command(config: Config, chromosome: str, regions_file: str, output: str) -> str:
    """
    The bcftools command that extracts regions from the genotype file of one chromosome.

    If the genotype file has an index (.tbi or .csi) bcftools jumps straight to
    the regions (`--regions-file`, seconds). Without an index it reads through
    the whole file once (`--targets-file`), which is slower but gives the same result.

    Parameters
    ----------
    config : Config
        The validated configuration.
    chromosome : str
        The chromosome to extract from (1-22 or X).
    regions_file : str
        File with `chromosome start end` per line (tab-separated, 1-based, inclusive).
    output : str
        The (bgzipped) VCF file to write.
    """
    genotypes = config.active_dataset.path_for(chromosome)
    has_index = os.path.isfile(genotypes + ".tbi") or os.path.isfile(genotypes + ".csi")
    return _join([
        config.site.bcftools, "view",
        "--regions-file" if has_index else "--targets-file", regions_file,
        "--output-type", "z", "--output", output,
        genotypes,
    ])
