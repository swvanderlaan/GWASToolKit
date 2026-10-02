"""
Reading and validating the GWASToolKit configuration file (config/config.yaml).

The configuration is a YAML file. This module describes what a valid
configuration looks like (the "schema"), using pydantic models: one class per
section of the file. Loading a file through `load_config()` gives either a
checked `Config` object, or a `ConfigError` listing everything that is wrong.

Three kinds of checks exist:
  1. Errors    -- the file cannot be used (unknown setting, wrong type, a
                  dataset name that does not exist, ...). Raised by `load_config()`.
  2. Warnings  -- the file can be used, but something needs attention.
                  Returned by `collect_warnings()`.
  3. File checks -- whether the files and programs named in the configuration
                  exist on this machine. Returned by `check_files()`; kept
                  separate because a configuration is often written on another
                  machine than the cluster it runs on.

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import difflib
import functools
import os
import re
from pathlib import Path
from typing import Dict, List, Literal, Optional

import yaml
from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator, model_validator

VERSION_NAME = "GWASToolKit configuration"
VERSION = "3.0.0.dev0"
VERSION_DATE = "2026-10-02"

# The autosomes; chromosome X is handled separately through `path_chrx`.
AUTOSOMES = [str(chromosome) for chromosome in range(1, 23)]
# When SLURM can send an e-mail about a job.
MAIL_TYPES = ["NONE", "BEGIN", "END", "FAIL", "REQUEUE", "ALL"]
# Phenotype types (in the SNPTEST sample file) that SNPTEST's method newml can analyse:
# binary and discrete. For a continuous phenotype (P) newml stops with an error.
NEWML_PHENOTYPE_TYPES = ("B", "D")
# How SNPTEST lets a variant be conditioned on (-condition_on <variant> [<model>] ...).
CONDITION_MODELS = {"add", "dom", "rec", "het", "gen"}
# Dataset names are used in file names, so keep them simple.
DATASET_NAME_PATTERN = re.compile(r"^[a-z0-9_]+$")


class ConfigError(Exception):
    """Raised when a configuration file is invalid; holds a list of readable messages."""

    def __init__(self, messages: List[str]):
        self.messages = messages
        super().__init__("\n".join(messages))


class _Section(BaseModel):
    """Base class for all sections: settings that are not known are an error (catches typos)."""

    model_config = ConfigDict(extra="forbid")


# ------------------------------------------------------------------------------
# The sections of the configuration file, in the order they appear in the file
# ------------------------------------------------------------------------------
class Site(_Section):
    """Where the software lives on this machine or cluster."""

    software: str
    gwastoolkit: str
    snptest: str
    plink2: str
    regenie: str
    harmonia: str
    plink1: str = ""
    # Found on the PATH of the environment unless a full path is given.
    bcftools: str = "bcftools"


class Slurm(_Section):
    """Job notification settings."""

    email: str = ""
    mail_type: str = "FAIL"

    @field_validator("mail_type")
    @classmethod
    def _known_mail_types(cls, value: str) -> str:
        # One type, or several separated by commas, e.g. "END,FAIL".
        types = [item.strip().upper() for item in value.split(",") if item.strip()]
        unknown = [item for item in types if item not in MAIL_TYPES]
        if not types or unknown:
            raise ValueError(f"use one or more of {', '.join(MAIL_TYPES)}, separated by commas")
        if "NONE" in types and len(types) > 1:
            raise ValueError("NONE cannot be combined with other types")
        return ",".join(types)

    @model_validator(mode="after")
    def _email_is_needed_for_mail(self) -> "Slurm":
        if self.mail_type != "NONE" and not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", self.email):
            raise ValueError("slurm.email: give a valid e-mail address, or set slurm.mail_type to NONE")
        return self

    @property
    def sbatch_options(self) -> str:
        """The sbatch options for e-mail notifications; empty if mail_type is NONE."""
        if self.mail_type == "NONE":
            return ""
        return f"--mail-user={self.email} --mail-type={self.mail_type}"


class Project(_Section):
    """Where the results go."""

    dir: str
    name: str

    @field_validator("name")
    @classmethod
    def _name_is_a_single_directory(cls, value: str) -> str:
        # The name becomes a directory, so no spaces or slashes.
        if not re.match(r"^[A-Za-z0-9._-]+$", value):
            raise ValueError("use only letters, digits, '.', '_' and '-' (no spaces or slashes)")
        return value


class Analysis(_Section):
    """What to run."""

    mode: Literal["GWAS", "VARIANT", "REGION", "GENES"]
    engine: Literal["snptest", "plink2", "plink1", "regenie"] = "snptest"
    dataset: str
    sample_file: str = ""
    sample_file_chrx: str = ""
    phenotype_file: str
    covariate_file: str
    exclusion_name: str = "EXCL_DEFAULT"
    exclusion_column: str = ""
    exclusion_value: str = ""
    standardize: Literal["RAW", "STANDARDIZE", "SCALE"] = "RAW"
    method: Literal["auto", "expected", "score", "newml"] = "auto"
    baseline_phenotype: str = ""
    condition: bool = False
    condition_file: str = ""
    lower_sample_limit: int = Field(default=10, ge=1)

    @field_validator("exclusion_name")
    @classmethod
    def _exclusion_name_is_a_label(cls, value: str) -> str:
        # The label ends up in output file names.
        if not re.match(r"^[A-Z0-9_]+$", value):
            raise ValueError("use capitals, digits and '_' only, for example EXCL_DEFAULT")
        return value


class Region(_Section):
    """One genomic region."""

    chr: str
    start: int = Field(ge=0)
    end: int = Field(ge=1)

    @field_validator("chr", mode="before")
    @classmethod
    def _chromosome_as_text(cls, value) -> str:
        # Accept 1, "1", "chr1" and "X"; store without the 'chr' prefix.
        text = str(value).strip()
        if text.lower().startswith("chr"):
            text = text[3:]
        text = text.upper()
        if text not in AUTOSOMES + ["X"]:
            raise ValueError("must be a chromosome: 1-22 or X")
        return text


class Targets(_Section):
    """What to analyse in the VARIANT, REGION and GENES modes."""

    variant_file: str = ""
    region: Optional[Region] = None
    gene_file: str = ""
    range: int = Field(default=500000, ge=0)


class QC(_Section):
    """Filters applied to the association results."""

    min_info: float = Field(default=0.3, ge=0, le=1)
    min_mac: float = Field(default=6, ge=0)
    min_maf: float = Field(default=0.005, ge=0, le=0.5)
    max_abs_beta_se: float = Field(default=100, gt=0)


class Clumping(_Section):
    """Clumping settings (GWAS mode only)."""

    p1: float = Field(default=5e-6, gt=0, le=1)
    p2: float = Field(default=1, gt=0, le=1)
    r2: float = Field(default=0.2, gt=0, le=1)
    kb: int = Field(default=500, gt=0)


class Regenie(_Section):
    """REGENIE settings; only used when `analysis.engine` is `regenie`."""

    step1_call_rate: float = Field(default=0.10, ge=0, le=1)
    step1_maf: float = Field(default=0.10, ge=0, le=0.5)
    step1_hwe: float = Field(default=0.001, ge=0, le=1)
    step1_prune: str = "100 10 0.2"
    step1_block_size: int = Field(default=1000, gt=0)
    step2_block_size: int = Field(default=1000, gt=0)
    exclude_range_file: str = ""
    covariates_quantitative: List[str] = []
    covariates_categorical: List[str] = []
    phenotypes_quantitative: List[str] = []
    phenotypes_binary: List[str] = []

    @field_validator("step1_prune")
    @classmethod
    def _prune_is_three_numbers(cls, value: str) -> str:
        # PLINK --indep-pairwise takes: window size, step size, r2 threshold.
        if not re.match(r"^\d+(kb)?\s+\d+\s+(0?\.\d+|[01])$", value.strip()):
            raise ValueError("must be three values 'window step r2', for example '100 10 0.2'")
        return value.strip()


class ReferenceSet(_Section):
    """Reference files for one genome build."""

    genes: str = ""
    ld_reference: str = ""


class Study(_Section):
    """Defaults shared by all datasets of one study."""

    description: str = ""
    sample_file: str = ""


class Dataset(_Section):
    """One imputed genotype dataset in the registry."""

    study: str
    description: str = ""
    build: Literal["b37", "b38"]
    format: Literal["vcf.gz", "vcf", "bgen", "gen.gz", "gen"]
    genotype_field: str = ""
    contig_prefix: Literal["", "chr"] = ""
    path: str
    path_chrx: str = ""
    n_samples: Optional[int] = Field(default=None, ge=1)
    # The autosomes this dataset has files for; almost always 1-22 (the default).
    chromosomes: List[str] = AUTOSOMES

    @field_validator("chromosomes", mode="before")
    @classmethod
    def _chromosomes_as_text(cls, value):
        # Accept [21, 22] as well as ["21", "22"].
        if not isinstance(value, list) or not value:
            raise ValueError("must be a list of chromosomes, for example [21, 22]")
        chromosomes = [str(item) for item in value]
        unknown = [item for item in chromosomes if item not in AUTOSOMES]
        if unknown:
            raise ValueError(f"not an autosome (1-22): {', '.join(unknown)}; chromosome X is set with path_chrx")
        return chromosomes

    @model_validator(mode="after")
    def _paths_and_format_agree(self) -> "Dataset":
        problems = []
        for setting, path in (("path", self.path), ("path_chrx", self.path_chrx)):
            if not path:
                continue
            if "{chr}" not in path:
                problems.append(f"{setting} must contain '{{chr}}' where the chromosome goes")
            if not path.endswith("." + self.format):
                problems.append(f"{setting} does not end in '.{self.format}', the format given")
        if self.format.startswith("vcf") and not self.genotype_field:
            problems.append("genotype_field is required for VCF files, for example 'GP'")
        if problems:
            raise ValueError("; ".join(problems))
        return self

    def path_for(self, chromosome) -> str:
        """Return the file path for one chromosome (1-22 or X)."""
        chromosome = str(chromosome)
        if chromosome.upper() == "X":
            if not self.path_chrx:
                raise ValueError("this dataset has no chromosome X data (path_chrx is empty)")
            return self.path_chrx.replace("{chr}", "X")
        return self.path.replace("{chr}", chromosome)


# ------------------------------------------------------------------------------
# The whole configuration file
# ------------------------------------------------------------------------------
class Config(_Section):
    """The complete configuration: all sections plus the checks that span sections."""

    site: Site
    slurm: Slurm
    project: Project
    analysis: Analysis
    targets: Targets = Targets()
    qc: QC = QC()
    clumping: Clumping = Clumping()
    regenie: Regenie = Regenie()
    references: Dict[str, ReferenceSet]
    studies: Dict[str, Study]
    datasets: Dict[str, Dataset]

    @model_validator(mode="after")
    def _check_across_sections(self) -> "Config":
        """Checks that need more than one section, e.g. 'does the chosen dataset exist?'."""
        problems = []
        analysis = self.analysis

        # --- the registry itself ---
        for name, dataset in self.datasets.items():
            if not DATASET_NAME_PATTERN.match(name):
                problems.append(f"datasets.{name}: use lower-case letters, digits and '_' only in dataset names")
            if dataset.study not in self.studies:
                problems.append(
                    f"datasets.{name}.study: '{dataset.study}' is not listed under `studies` "
                    f"(known: {', '.join(self.studies)})"
                )
            if dataset.build not in self.references:
                problems.append(f"datasets.{name}.build: no `references.{dataset.build}` section exists")

        # --- the chosen dataset ---
        if analysis.dataset not in self.datasets:
            message = f"analysis.dataset: '{analysis.dataset}' is not listed under `datasets`"
            close = difflib.get_close_matches(analysis.dataset, list(self.datasets), n=3)
            if close:
                message += f"; did you mean: {', '.join(close)}?"
            problems.append(message)
        elif self.datasets[analysis.dataset].study in self.studies and not self.sample_file:
            problems.append(
                "analysis.sample_file: no sample file given, and the study of the chosen dataset has no default one"
            )

        # --- engine and mode combinations ---
        if analysis.engine == "regenie":
            if analysis.mode != "GWAS":
                problems.append("analysis.engine: 'regenie' is only available for mode GWAS")
            if not (self.regenie.phenotypes_quantitative or self.regenie.phenotypes_binary):
                problems.append("regenie: give at least one phenotype in phenotypes_quantitative or phenotypes_binary")
        # A baseline phenotype is only used by method newml; with "auto" that is in the modes other than GWAS.
        uses_newml = analysis.method == "newml" or (analysis.method == "auto" and analysis.mode != "GWAS")
        if analysis.baseline_phenotype and not uses_newml:
            problems.append("analysis.baseline_phenotype: only used with method 'newml', which this analysis does not use")
        if analysis.condition and not analysis.condition_file:
            problems.append("analysis.condition_file: required when condition is true")
        if analysis.condition and analysis.engine != "snptest":
            problems.append("analysis.condition: conditional analysis is so far only available with engine 'snptest'")
        if bool(analysis.exclusion_column) != bool(analysis.exclusion_value):
            problems.append("analysis: give both exclusion_column and exclusion_value, or leave both empty")

        # --- the targets each mode needs ---
        if analysis.mode == "VARIANT" and not self.targets.variant_file:
            problems.append("targets.variant_file: required for mode VARIANT")
        if analysis.mode == "GENES" and not self.targets.gene_file:
            problems.append("targets.gene_file: required for mode GENES")
        if analysis.mode == "REGION" and self.targets.region is None:
            problems.append("targets.region: required for mode REGION")
        region = self.targets.region
        if region is not None and region.start >= region.end:
            problems.append("targets.region: start must be smaller than end")

        if problems:
            raise ValueError("\n".join(problems))
        return self

    # --- convenience: the settings that follow from the chosen dataset ---
    @property
    def active_dataset(self) -> Dataset:
        """The dataset chosen with `analysis.dataset`."""
        return self.datasets[self.analysis.dataset]

    @property
    def active_study(self) -> Study:
        """The study the chosen dataset belongs to."""
        return self.studies[self.active_dataset.study]

    @property
    def active_references(self) -> ReferenceSet:
        """The reference files for the genome build of the chosen dataset."""
        return self.references[self.active_dataset.build]

    @property
    def sample_file(self) -> str:
        """The sample file to use: the one given for the analysis, else the study default."""
        return self.analysis.sample_file or self.active_study.sample_file

    def phenotype_types(self) -> Dict[str, str]:
        """The type (P, B, D, ...) of every column of the sample file; empty if the file cannot be read."""
        return _sample_column_types(self.sample_file)

    def method_for(self, phenotype: str) -> str:
        """
        The SNPTEST method for one phenotype.

        A method given in the configuration is used as it is. With "auto":
          * mode GWAS: expected, for every phenotype;
          * modes VARIANT, REGION and GENES: newml for binary and discrete
            phenotypes (types B and D in the sample file), expected for
            continuous phenotypes (type P), which newml cannot analyse.
        """
        if self.analysis.method != "auto":
            return self.analysis.method
        if self.analysis.mode == "GWAS":
            return "expected"
        return "newml" if self.phenotype_types().get(phenotype) in NEWML_PHENOTYPE_TYPES else "expected"

    @property
    def project_dir(self) -> str:
        """The directory the results are written to: project.dir/project.name."""
        return os.path.join(self.project.dir, self.project.name)

    def reference_path(self, path: str) -> str:
        """Reference paths are relative to `site.gwastoolkit` unless they start with '/'."""
        if not path or os.path.isabs(path):
            return path
        return os.path.join(self.site.gwastoolkit, path)


# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
def _readable_errors(error: ValidationError) -> List[str]:
    """Turn a pydantic ValidationError into one readable line per problem."""
    messages = []
    for item in error.errors():
        location = ".".join(str(part) for part in item["loc"])
        text = item["msg"]
        # pydantic prefixes our own messages with "Value error, "; remove that.
        if text.startswith("Value error, "):
            text = text[len("Value error, "):]
        if item["type"] == "extra_forbidden":
            text = "unknown setting (check the spelling)"
        for line in text.split("\n"):
            # Cross-section checks already name the setting; others get the location in front.
            if location and not _names_a_setting(line):
                line = f"{location}: {line}"
            messages.append(line)
    return messages


def _names_a_setting(line: str) -> bool:
    """True if a message starts with the name of a setting, like 'analysis.dataset: ...'."""
    return bool(re.match(r"^[a-z_]+(\.[A-Za-z0-9_]+)*: ", line))


def load_config(path) -> Config:
    """
    Read and validate a configuration file.

    Parameters
    ----------
    path : str or Path
        The YAML configuration file.

    Returns
    -------
    Config
        The validated configuration.

    Raises
    ------
    ConfigError
        If the file does not exist, is not valid YAML, or fails validation.
    """
    path = Path(path)
    if not path.is_file():
        raise ConfigError([f"configuration file not found: {path}"])
    try:
        with open(path, "r", encoding="utf-8") as handle:
            content = yaml.safe_load(handle)
    except yaml.YAMLError as error:
        raise ConfigError([f"{path} is not valid YAML: {error}"]) from error
    if not isinstance(content, dict):
        raise ConfigError([f"{path} is empty or does not contain settings"])
    try:
        return Config.model_validate(content)
    except ValidationError as error:
        raise ConfigError(_readable_errors(error)) from error


def read_list(path) -> List[str]:
    """
    Read a list file (phenotypes, covariates, genes): names separated by spaces or new lines.

    Lines starting with '#' are skipped.
    """
    names = []
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith("#"):
                names.extend(line.split())
    return names


def collect_warnings(config: Config) -> List[str]:
    """Return things that need attention but do not make the configuration invalid."""
    warnings = []
    analysis = config.analysis
    dataset = config.active_dataset
    references = config.active_references

    if analysis.mode == "GENES" and not references.genes:
        warnings.append(
            f"references.{dataset.build}.genes is empty: gene coordinates must be created by the preparation step"
        )
    if analysis.mode == "GWAS" and not references.ld_reference:
        warnings.append(
            f"references.{dataset.build}.ld_reference is empty: "
            "the LD reference for clumping must be created by the preparation step"
        )
    if config.slurm.mail_type != "NONE" and config.slurm.email.endswith("@example.org"):
        warnings.append("slurm.email still holds the placeholder address")
    if analysis.engine == "regenie":
        range_file = config.regenie.exclude_range_file
        if not range_file:
            warnings.append("regenie.exclude_range_file is empty: no regions are left out of step 1")
        elif dataset.build not in os.path.basename(range_file):
            warnings.append(
                f"regenie.exclude_range_file does not mention '{dataset.build}' in its name: "
                "check that it matches the genome build of the dataset"
            )
    return warnings


@functools.lru_cache(maxsize=None)
def _sample_column_types(path: str) -> Dict[str, str]:
    """Column name -> type of a SNPTEST sample file; empty if the file is missing or unreadable."""
    try:
        names, types, _ = read_sample_file_header(path)
    except (OSError, ValueError):
        return {}
    return dict(zip(names, types))


def read_sample_file_header(path):
    """Read a SNPTEST sample file; returns (column names, column types, rows of values)."""
    with open(path, "r", encoding="utf-8") as handle:
        lines = [line.split() for line in handle if line.strip()]
    if len(lines) < 3 or len(lines[0]) != len(lines[1]):
        raise ValueError("not a SNPTEST sample file: expected a line of column names, a line of column "
                         "types, and one line per sample")
    return lines[0], lines[1], lines[2:]


def check_inputs(config: Config) -> List[str]:
    """
    Check that the CONTENTS of the input files fit the configuration.

    Checked, as far as the files exist:
      * the phenotypes, the covariates and the exclusion column are columns of the sample file;
      * phenotypes have a phenotype type in the sample file (P, B or D);
      * method newml is not asked for a continuous phenotype;
      * `baseline_phenotype` is a value that occurs for every phenotype analysed with newml;
      * the conditioning file lists variants, each optionally followed by a model
        (add, dom, rec, het or gen).
    Returns a list of problems; an empty list means nothing was found.
    """
    problems = []
    analysis = config.analysis

    phenotypes = read_list(analysis.phenotype_file) if os.path.isfile(analysis.phenotype_file) else []
    covariates = read_list(analysis.covariate_file) if os.path.isfile(analysis.covariate_file) else []
    if os.path.isfile(analysis.phenotype_file) and not phenotypes:
        problems.append(f"analysis.phenotype_file: no phenotypes in {analysis.phenotype_file}")
    for name in phenotypes:
        if not re.match(r"^[A-Za-z0-9_-]+$", name):
            problems.append(f"phenotype '{name}': use only letters, digits, '_' and '-' in phenotype names")

    if os.path.isfile(config.sample_file):
        try:
            names, types, rows = read_sample_file_header(config.sample_file)
        except ValueError as error:
            return problems + [f"sample file {config.sample_file}: {error}"]
        kind = dict(zip(names, types))
        for name in phenotypes:
            if name not in kind:
                problems.append(f"phenotype '{name}' is not a column of the sample file {config.sample_file}")
            elif kind[name] not in ("P", "B", "D"):
                problems.append(f"phenotype '{name}' has type {kind[name]} in the sample file; "
                                "a phenotype must be P (continuous), B (binary) or D (discrete)")
            elif config.method_for(name) == "newml" and kind[name] not in NEWML_PHENOTYPE_TYPES:
                problems.append(f"phenotype '{name}' is continuous (type P); method 'newml' only analyses binary "
                                "and discrete phenotypes (B, D). Use method 'auto' or 'expected'")
            elif analysis.baseline_phenotype and config.method_for(name) == "newml":
                values = {row[names.index(name)] for row in rows}
                if analysis.baseline_phenotype not in values:
                    problems.append(f"analysis.baseline_phenotype: '{analysis.baseline_phenotype}' does not occur "
                                    f"as a value of phenotype '{name}' in the sample file")
        for name in covariates:
            if name not in kind:
                problems.append(f"covariate '{name}' is not a column of the sample file {config.sample_file}")
        if analysis.exclusion_column and analysis.exclusion_column not in kind:
            problems.append(f"analysis.exclusion_column: '{analysis.exclusion_column}' is not a column of the "
                            f"sample file {config.sample_file}")

    if analysis.condition and os.path.isfile(analysis.condition_file):
        words = read_list(analysis.condition_file)
        if not words:
            problems.append(f"analysis.condition_file: {analysis.condition_file} is empty")
        elif words[0] in CONDITION_MODELS or any(
            first in CONDITION_MODELS and second in CONDITION_MODELS for first, second in zip(words, words[1:])
        ):
            problems.append(f"analysis.condition_file: expected variants, each optionally followed by a model "
                            f"({', '.join(sorted(CONDITION_MODELS))}); for example `rs123 add rs456 add`")
    return problems


def check_files(config: Config) -> List[str]:
    """
    Check that the files, directories and programs named in the configuration exist.

    Only what the chosen mode, engine and dataset need is checked.
    Returns a list of problems; an empty list means all were found.
    """
    problems = []
    analysis = config.analysis
    dataset = config.active_dataset

    def need_file(setting: str, path: str) -> None:
        if not path:
            return
        if not os.path.isfile(path):
            problems.append(f"{setting}: file not found: {path}")

    def need_dir(setting: str, path: str) -> None:
        if not os.path.isdir(path):
            problems.append(f"{setting}: directory not found: {path}")

    # Directories and software.
    need_dir("project.dir", config.project.dir)
    need_dir("site.gwastoolkit", config.site.gwastoolkit)
    need_dir("site.harmonia", config.site.harmonia)
    engine_program = getattr(config.site, analysis.engine)
    if not engine_program:
        problems.append(f"site.{analysis.engine}: no path given for the chosen engine")
    else:
        need_file(f"site.{analysis.engine}", engine_program)

    # Analysis input.
    need_file("sample file", config.sample_file)
    need_file("analysis.sample_file_chrx", analysis.sample_file_chrx)
    need_file("analysis.phenotype_file", analysis.phenotype_file)
    need_file("analysis.covariate_file", analysis.covariate_file)
    if analysis.condition:
        need_file("analysis.condition_file", analysis.condition_file)
    if analysis.mode == "VARIANT":
        need_file("targets.variant_file", config.targets.variant_file)
    if analysis.mode == "GENES":
        need_file("targets.gene_file", config.targets.gene_file)
    if analysis.engine == "regenie":
        need_file("regenie.exclude_range_file", config.regenie.exclude_range_file)

    # Genotype data: one file per autosome, plus chromosome X if the dataset has it.
    chromosomes = dataset.chromosomes + (["X"] if dataset.path_chrx else [])
    for chromosome in chromosomes:
        need_file(f"datasets.{analysis.dataset} (chromosome {chromosome})", dataset.path_for(chromosome))

    return problems
