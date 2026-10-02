"""
The `gwastoolkit` command-line interface.

Commands
--------
validate : check a configuration file, and optionally that its files exist.
datasets : list the imputed datasets in the registry of a configuration file.
show     : show what will be analysed with a configuration file.
run      : run the analysis (through Snakemake), or show what would be run.
find-variants : check whether variants are present in the genotype data.
make-gene-list : make the gene coordinate files for builds 37 and 38 (needed for mode GENES).

Run `gwastoolkit --help`, or `gwastoolkit <command> --help`, for the options.

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import logging
import shlex
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from gwastoolkit import VERSION, VERSION_DATE, VERSION_NAME, find_variants, make_gene_list
from gwastoolkit.config import Config, ConfigError, check_files, check_inputs, collect_warnings, load_config

# The example configuration that ships with the repository: <repository>/config/config.yaml.
REPOSITORY = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = REPOSITORY / "config" / "config.yaml"
# The Snakemake workflow, and the profile that makes Snakemake submit jobs to SLURM.
SNAKEFILE = REPOSITORY / "workflow" / "Snakefile"
SLURM_PROFILE = REPOSITORY / "profiles" / "slurm"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

EXAMPLES = """\
examples:
  gwastoolkit datasets
      List all datasets in the example configuration.
  gwastoolkit datasets --study AEGS --build b38
      List only the AEGS datasets on genome build 38.
  gwastoolkit validate --config /path/to/project/config.yaml
      Check your configuration file; a log file is written next to it.
  gwastoolkit validate --config /path/to/project/config.yaml --check-files
      Also check that all files, directories and programs it names exist
      (run this on the machine where the analysis will run).
  gwastoolkit show --config /path/to/project/config.yaml
      Show what will be analysed.
  gwastoolkit run --config /path/to/project/config.yaml --dry-run
      Show every job and command that would be run, without running anything.
  gwastoolkit run --config /path/to/project/config.yaml --slurm
      Run the analysis, submitting the jobs to SLURM.
  gwastoolkit find-variants --config /path/to/project/config.yaml --variants chr21:20235673:G:T
      Check whether a variant is in the genotype data, e.g. before conditioning on it.
  gwastoolkit make-gene-list
      Make the gene coordinate files for builds 37 and 38 (once per installation).
"""

logger = logging.getLogger("gwastoolkit")


# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------
def default_log_path(config_path: Path) -> Path:
    """Log file next to the configuration file: <YYYYMMDD>_<config name>.gwastoolkit.log."""
    today = datetime.now().strftime("%Y%m%d")
    return config_path.parent / f"{today}_{config_path.stem}.gwastoolkit.log"


def setup_logging(log_path: Optional[Path], verbose: bool) -> None:
    """Messages go to the screen, and to a log file (with timestamps) if one is given."""
    logger.setLevel(logging.DEBUG if verbose else logging.INFO)
    logger.handlers.clear()

    screen = logging.StreamHandler(sys.stdout)
    screen.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(screen)

    if log_path is not None:
        to_file = logging.FileHandler(log_path, mode="a", encoding="utf-8")
        to_file.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"))
        logger.addHandler(to_file)


# ------------------------------------------------------------------------------
# Commands
# ------------------------------------------------------------------------------
def command_validate(config: Config, args: argparse.Namespace) -> int:
    """Check the configuration; return 0 if it can be used, 1 if not."""
    logger.info("The configuration file is valid.")
    logger.info("  mode    : %s", config.analysis.mode)
    logger.info("  engine  : %s", config.analysis.engine)
    logger.info("  dataset : %s (%s)", config.analysis.dataset, config.active_dataset.build)

    for warning in collect_warnings(config):
        logger.warning("WARNING: %s", warning)

    if not args.check_files:
        logger.info("Files were not checked; add --check-files to check that they exist.")
        return 0

    problems = check_files(config)
    if not problems:
        # All files are there: also check that their contents fit the configuration.
        problems = check_inputs(config)
        if problems:
            logger.error("%d problem(s) with the contents of the input files:", len(problems))
            for problem in problems:
                logger.error("  * %s", problem)
            return 1
    if problems:
        logger.error("%d file(s), directories or programs were not found:", len(problems))
        for problem in problems:
            logger.error("  * %s", problem)
        return 1
    logger.info("All files, directories and programs were found, and their contents fit the configuration.")
    return 0


def command_datasets(config: Config, args: argparse.Namespace) -> int:
    """List the datasets in the registry, optionally for one study and/or build."""
    rows = []
    for name, dataset in config.datasets.items():
        if args.study and dataset.study.upper() != args.study.upper():
            continue
        if args.build and dataset.build != args.build:
            continue
        default = "*" if name == config.analysis.dataset else ""
        samples = f"{dataset.n_samples:,}" if dataset.n_samples else "-"
        rows.append([default, name, dataset.study, dataset.build, dataset.format, samples, dataset.description])

    if not rows:
        logger.error("No datasets match.")
        return 1

    header = ["", "DATASET", "STUDY", "BUILD", "FORMAT", "N", "DESCRIPTION"]
    # Column widths: the widest value per column (the description is last and not padded).
    widths = [max(len(row[column]) for row in [header] + rows) for column in range(len(header) - 1)]
    for row in [header] + rows:
        cells = [row[column].ljust(widths[column]) for column in range(len(widths))]
        logger.info("  ".join(cells + [row[-1]]).rstrip())
    logger.info("")
    logger.info("* = the dataset chosen in this configuration (analysis.dataset)")
    return 0


def command_show(config: Config, args: argparse.Namespace) -> int:
    """Show what will be analysed with this configuration."""
    analysis = config.analysis
    dataset = config.active_dataset
    references = config.active_references
    targets = config.targets

    def line(label: str, value) -> None:
        logger.info("%s: %s", label.ljust(26, "."), value if value not in ("", None) else "(not set)")

    logger.info("Analysis")
    line("  mode", analysis.mode)
    line("  engine", analysis.engine)
    line("  method", f"{config.method} (default for mode {analysis.mode})" if analysis.method == "auto" else config.method)
    scaling = {"RAW": "as they are", "STANDARDIZE": "quantile-normalised", "SCALE": "scaled to mean 0, variance 1"}
    line("  continuous phenotypes", f"{analysis.standardize} ({scaling[analysis.standardize]})")
    line("  phenotype file", analysis.phenotype_file)
    line("  covariate file", analysis.covariate_file)
    line("  sample file", config.sample_file)
    if analysis.exclusion_column:
        exclusion = f"{analysis.exclusion_name}: drop samples where {analysis.exclusion_column} = {analysis.exclusion_value}"
    else:
        exclusion = f"{analysis.exclusion_name}: no samples dropped"
    line("  exclusion", exclusion)
    line("  conditional analysis", analysis.condition_file if analysis.condition else "no")
    if analysis.mode == "VARIANT":
        line("  variants", targets.variant_file)
    elif analysis.mode == "REGION":
        line("  region", f"chr{targets.region.chr}:{targets.region.start:,}-{targets.region.end:,}")
    elif analysis.mode == "GENES":
        line("  genes", f"{targets.gene_file} (± {targets.range:,} bp)")

    logger.info("Dataset")
    line("  name", analysis.dataset)
    line("  study", f"{dataset.study} -- {config.active_study.description}")
    line("  description", dataset.description)
    line("  genome build", dataset.build)
    line("  format", dataset.format)
    line("  samples", f"{dataset.n_samples:,}" if dataset.n_samples else "unknown")
    line("  chromosomes", _chromosome_range(dataset.chromosomes))
    first = dataset.chromosomes[0]
    line(f"  chromosome {first} file", dataset.path_for(first))
    line("  chromosome X file", dataset.path_for("X") if dataset.path_chrx else "none")

    logger.info("References (%s)", dataset.build)
    line("  gene coordinates", config.reference_path(references.genes))
    line("  LD reference", config.reference_path(references.ld_reference))

    logger.info("Output")
    line("  project directory", config.project_dir)
    line("  SLURM e-mail", f"{config.slurm.email} on {config.slurm.mail_type}" if config.slurm.sbatch_options else "none")
    return 0


def snakemake_command(args: argparse.Namespace) -> List[str]:
    """The Snakemake command that `gwastoolkit run` executes."""
    command = ["snakemake", "--snakefile", str(SNAKEFILE), "--configfile", str(args.config)]
    if args.slurm:
        # The profile holds the SLURM settings, including the number of jobs.
        command += ["--profile", str(SLURM_PROFILE)]
    else:
        command += ["--cores", str(args.cores)]
    if args.dry_run:
        command += ["--dry-run", "--printshellcmds"]
    if args.snakemake_args:
        command += shlex.split(args.snakemake_args)
    return command


def command_run(config: Config, args: argparse.Namespace) -> int:
    """Run the workflow with Snakemake; return Snakemake's exit code."""
    if shutil.which("snakemake") is None:
        logger.error("The `snakemake` command was not found. Activate the environment first: "
                     "mamba activate gwastoolkit")
        return 1
    for warning in collect_warnings(config):
        logger.warning("WARNING: %s", warning)
    command = snakemake_command(args)
    logger.info("Running: %s", " ".join(shlex.quote(part) for part in command))
    return subprocess.call(command)


def _chromosome_range(chromosomes: List[str]) -> str:
    """Show a list of chromosomes compactly: '1-22' if consecutive, else '21, 22'."""
    numbers = [int(chromosome) for chromosome in chromosomes]
    if len(numbers) > 2 and numbers == list(range(numbers[0], numbers[-1] + 1)):
        return f"{numbers[0]}-{numbers[-1]}"
    return ", ".join(chromosomes)


def command_find_variants(config: Config, args: argparse.Namespace) -> int:
    """Check whether variants are present in the genotype data (see gwastoolkit/find_variants.py)."""
    # Let the tool write its messages through this command's logger (screen and log file).
    find_variants.logger = logger
    return find_variants.run(config, args)


COMMANDS = {
    "validate": command_validate, "datasets": command_datasets, "show": command_show, "run": command_run,
    "find-variants": command_find_variants,
}


# ------------------------------------------------------------------------------
# Command-line parsing
# ------------------------------------------------------------------------------
def build_parser() -> argparse.ArgumentParser:
    """Create the argument parser, with one sub-command per command."""
    # Options that every command accepts.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "-c", "--config", type=Path, default=DEFAULT_CONFIG, metavar="FILE",
        help="The configuration file (YAML). Default: the example configuration, %(default)s.",
    )
    common.add_argument(
        "--log", type=Path, default=None, metavar="FILE",
        help="Write a log file here. Default for `validate`: next to the configuration file, "
             "named <YYYYMMDD>_<config name>.gwastoolkit.log. Other commands write no log unless asked.",
    )
    common.add_argument("--no-log", action="store_true", help="Do not write a log file.")
    common.add_argument("-v", "--verbose", action="store_true", help="Print extra information.")

    parser = argparse.ArgumentParser(
        prog="gwastoolkit",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Association analyses on imputed genotype data: genome-wide (GWAS), per variant,\n"
                    "per region or per gene. All settings are in one configuration file.",
        epilog=f"{EXAMPLES}\n{COPYRIGHT}",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    commands = parser.add_subparsers(dest="command", metavar="<command>")

    validate = commands.add_parser(
        "validate", parents=[common],
        help="Check a configuration file.",
        description="Check a configuration file: unknown or misspelled settings, wrong values, a dataset "
                    "that is not in the registry, and settings that do not go together.",
    )
    validate.add_argument(
        "--check-files", action="store_true",
        help="Also check that the files, directories and programs named in the configuration exist "
             "on this machine, and that their contents fit: phenotypes, covariates and the exclusion "
             "column are in the sample file, the baseline phenotype is a value that occurs, and the "
             "conditioning file is well-formed. Only what the chosen mode, engine and dataset need is checked.",
    )

    datasets = commands.add_parser(
        "datasets", parents=[common],
        help="List the datasets in the registry.",
        description="List the imputed datasets in the registry of a configuration file. "
                    "The dataset chosen in the configuration is marked with *.",
    )
    datasets.add_argument("--study", metavar="NAME", help="Only datasets of this study, for example AEGS.")
    datasets.add_argument("--build", choices=["b37", "b38"], help="Only datasets on this genome build.")

    commands.add_parser(
        "show", parents=[common],
        help="Show what will be analysed.",
        description="Show the analysis, the dataset, the reference files and the output directory that "
                    "follow from a configuration file.",
    )

    run = commands.add_parser(
        "run", parents=[common],
        help="Run the analysis, or show what would be run.",
        description="Run the analysis in a configuration file through Snakemake. Steps whose results "
                    "already exist are not run again, so after a failure the same command continues "
                    "where it stopped. Paths in the configuration that are not absolute are taken "
                    "relative to the directory you run this command from.",
    )
    run.add_argument("-n", "--dry-run", action="store_true",
                     help="Show every job and command that would be run, without running anything.")
    run.add_argument("--slurm", action="store_true",
                     help="Submit the jobs to SLURM (settings in profiles/slurm/config.yaml). "
                          "Without this option everything runs on this machine.")
    run.add_argument("--cores", type=int, default=1, metavar="N",
                     help="Number of jobs to run at the same time on this machine. Default: %(default)s. "
                          "Not used with --slurm.")
    run.add_argument("--snakemake-args", default="", metavar="'ARGS'",
                     help="Extra options passed on to Snakemake, in quotes; for example "
                          "--snakemake-args '--forceall'.")

    find = commands.add_parser(
        "find-variants", parents=[common],
        help="Check whether variants are present in the genotype data.",
        description="Check, with bcftools, whether variants are present in the genotype data under the "
                    "identifiers you give. Use this before a conditional analysis: SNPTEST can only "
                    "condition on a variant that is in the data it reads. An identifier that holds its "
                    "position (chr21:20235673:G:T) is looked up directly; any other identifier (rs12345) "
                    "is looked for in the files of all chromosomes, which takes longer.",
    )
    find_variants.add_arguments(find)

    genes = commands.add_parser(
        "make-gene-list",
        help="Make the gene coordinate files for genome builds 37 and 38.",
        description="Make the gene coordinate files that mode GENES needs, for genome builds 37 and 38, "
                    "from the GENCODE gene annotation of the human reference genome. The release is fixed "
                    "and the download is checked against the published checksum, so everyone gets the same "
                    "files. Run this once per installation; it needs internet access (or --gtf).",
    )
    make_gene_list.add_arguments(genes)
    genes.add_argument("--log", type=Path, default=None, metavar="FILE", help="Write a log file here. Optional.")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    """Entry point of the `gwastoolkit` command; returns the exit code."""
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command is None:
        parser.print_help()
        return 1

    # This command needs no configuration file.
    if args.command == "make-gene-list":
        setup_logging(args.log, verbose=False)
        make_gene_list.logger = logger
        return make_gene_list.run(args)

    # Decide on the log file: `validate` writes one by default, the others only on request.
    log_path = args.log
    if log_path is None and args.command == "validate" and args.config.parent.is_dir():
        log_path = default_log_path(args.config)
    if args.no_log:
        log_path = None
    setup_logging(log_path, args.verbose)

    logger.debug("%s %s (%s)", VERSION_NAME, VERSION, VERSION_DATE)
    logger.debug("Configuration file: %s", args.config)

    try:
        config = load_config(args.config)
    except ConfigError as error:
        logger.error("The configuration file is NOT valid: %s", args.config)
        for message in error.messages:
            logger.error("  * %s", message)
        return 1

    exit_code = COMMANDS[args.command](config, args)
    if log_path is not None:
        logger.info("Log written to: %s", log_path)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
