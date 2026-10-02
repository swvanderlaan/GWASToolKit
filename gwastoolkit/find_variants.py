"""
Check whether variants are present in the genotype data, using bcftools.

Use this before a conditional analysis: SNPTEST can only condition on a variant
that is in the genotype file it reads, under exactly the identifier you give.

Variants are looked up by IDENTIFIER (the ID column of the VCF files):
  * An identifier that holds its position, such as chr21:20235673:G:T or
    21:20235673, is only looked for on that chromosome, at that position. With
    an index next to the VCF file (.tbi or .csi) this takes a moment.
  * Any other identifier, such as rs12345, is looked for in the files of all
    chromosomes of the dataset, which means reading through all of them.

Usage
-----
    gwastoolkit find-variants --help
    python -m gwastoolkit.find_variants --help

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import logging
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from gwastoolkit.config import CONDITION_MODELS, Config, ConfigError, load_config, read_list
from gwastoolkit.schema import normalise_chromosome

VERSION_NAME = "GWASToolKit find_variants"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

# An identifier that starts with chromosome:position, with or without 'chr'.
POSITIONAL_ID = re.compile(r"^(?:chr)?([0-9]{1,2}|X):([0-9]+)(?::|$)", re.IGNORECASE)

logger = logging.getLogger("gwastoolkit.find_variants")


class BcftoolsError(Exception):
    """Raised when bcftools cannot be run or fails."""


def variants_from_condition_file(path) -> List[str]:
    """The variants in a conditioning file: everything except the model words (add, dom, ...)."""
    return [word for word in read_list(path) if word not in CONDITION_MODELS]


def query(bcftools: str, vcf_path: str, identifiers: List[str], position: Optional[str] = None) -> List[List[str]]:
    """
    Ask bcftools for the variants with the given identifiers in one VCF file.

    Parameters
    ----------
    bcftools : str
        The bcftools program.
    vcf_path : str
        The VCF file to look in.
    identifiers : list of str
        The identifiers to look for.
    position : str, optional
        Restrict the search to 'chromosome:position' (as named in the file).

    Returns
    -------
    list of [chromosome, position, identifier, ref, alt]
    """
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as handle:
        handle.write("\n".join(identifiers) + "\n")
        id_file = handle.name
    command = [bcftools, "query", "--include", f"ID=@{id_file}", "--format", "%CHROM\t%POS\t%ID\t%REF\t%ALT\n"]
    if position:
        # With an index bcftools jumps to the position; without one it reads through the file.
        has_index = os.path.isfile(vcf_path + ".tbi") or os.path.isfile(vcf_path + ".csi")
        command += ["--regions" if has_index else "--targets", position]
    command.append(vcf_path)
    logger.debug("Running: %s", " ".join(command))
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=False)
    except FileNotFoundError as error:
        raise BcftoolsError(f"bcftools was not found ({bcftools}); activate the environment first") from error
    finally:
        os.unlink(id_file)
    if result.returncode != 0:
        raise BcftoolsError(f"bcftools failed on {vcf_path}: {result.stderr.strip()}")
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def find_variants(config: Config, identifiers: List[str]) -> Dict[str, List[List[str]]]:
    """
    Look for variants in the dataset chosen in the configuration.

    Returns, per identifier, the matching records ([chromosome, position,
    identifier, ref, alt]); an empty list if the variant was not found.
    """
    dataset = config.active_dataset
    available = dataset.chromosomes + (["X"] if dataset.path_chrx else [])
    found: Dict[str, List[List[str]]] = {identifier: [] for identifier in identifiers}

    # Split the identifiers into those that tell us where to look, and the rest.
    by_chromosome: Dict[str, List[Tuple[str, str]]] = {}
    anywhere: List[str] = []
    for identifier in found:
        match = POSITIONAL_ID.match(identifier)
        if match:
            chromosome = normalise_chromosome(match.group(1))
            by_chromosome.setdefault(chromosome, []).append((identifier, match.group(2)))
        else:
            anywhere.append(identifier)

    for chromosome, items in by_chromosome.items():
        if chromosome not in available:
            logger.warning("Chromosome %s is not in dataset %s.", chromosome, config.analysis.dataset)
            continue
        vcf_path = dataset.path_for(chromosome)
        for identifier, position in items:
            contig = f"{dataset.contig_prefix}{chromosome}"
            for record in query(config.site.bcftools, vcf_path, [identifier], f"{contig}:{position}"):
                found[record[2]].append(record)

    if anywhere:
        logger.info("Looking for %d identifier(s) without a position in all %d chromosome files; "
                    "this reads through every file.", len(anywhere), len(available))
        for chromosome in available:
            for record in query(config.site.bcftools, dataset.path_for(chromosome), anywhere):
                found[record[2]].append(record)
    return found


def report(found: Dict[str, List[List[str]]], output: Optional[Path] = None) -> int:
    """Print (and optionally write) the result; returns the number of variants not found."""
    lines = ["variant\tstatus\tchr\tpos\tref\talt"]
    missing = 0
    for identifier, records in found.items():
        if not records:
            missing += 1
            lines.append(f"{identifier}\tNOT_FOUND\tNA\tNA\tNA\tNA")
        for chromosome, position, _, ref, alt in records:
            lines.append(f"{identifier}\tfound\t{chromosome}\t{position}\t{ref}\t{alt}")
    for line in lines:
        logger.info(line.expandtabs(24))
    if output:
        output.write_text("\n".join(lines) + "\n", encoding="utf-8")
        logger.info("Written: %s", output)
    logger.info("")
    logger.info("%d of %d variant(s) found.", len(found) - missing, len(found))
    return missing


def add_arguments(parser: argparse.ArgumentParser) -> None:
    """The options of this tool (shared by `gwastoolkit find-variants` and `python -m`)."""
    parser.add_argument("--variants", nargs="+", default=[], metavar="ID",
                        help="Identifiers to look for, for example chr21:20235673:G:T rs12345.")
    parser.add_argument("--file", type=Path, default=None, metavar="FILE",
                        help="File with identifiers, separated by spaces or new lines. A conditioning file "
                             "can be given as it is: the model words (add, dom, rec, het, gen) are skipped. "
                             "Default, if no variants are given: analysis.condition_file of the configuration.")
    parser.add_argument("--dataset", default=None, metavar="NAME",
                        help="Look in this dataset of the registry. Default: analysis.dataset of the configuration.")
    parser.add_argument("-o", "--output", type=Path, default=None, metavar="FILE",
                        help="Also write the result to this tab-separated file. Optional.")


def run(config: Config, args: argparse.Namespace) -> int:
    """Run the check with parsed arguments; returns the exit code (0: all found, 1: not all or an error)."""
    if args.dataset:
        if args.dataset not in config.datasets:
            logger.error("Dataset '%s' is not in the registry; see `gwastoolkit datasets`.", args.dataset)
            return 1
        config.analysis.dataset = args.dataset

    identifiers = list(args.variants)
    source = args.file
    if source is None and not identifiers and config.analysis.condition_file:
        source = Path(config.analysis.condition_file)
    if source is not None:
        if not source.is_file():
            logger.error("File not found: %s", source)
            return 1
        identifiers += variants_from_condition_file(source)
    identifiers = list(dict.fromkeys(identifiers))  # drop doubles, keep the order
    if not identifiers:
        logger.error("No variants given: use --variants or --file, or set analysis.condition_file.")
        return 1

    logger.info("Dataset: %s", config.analysis.dataset)
    try:
        found = find_variants(config, identifiers)
    except (BcftoolsError, ValueError) as error:
        logger.error("%s", error)
        return 1
    return 1 if report(found, args.output) else 0


def main(argv=None) -> int:
    """Entry point of `python -m gwastoolkit.find_variants`; returns the exit code."""
    parser = argparse.ArgumentParser(
        prog="python -m gwastoolkit.find_variants",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Check whether variants are present in the genotype data, using bcftools.\n"
                    "Use this before a conditional analysis.",
        epilog="examples:\n"
               "  python -m gwastoolkit.find_variants --config config.yaml --variants chr21:20235673:G:T\n"
               "  python -m gwastoolkit.find_variants --config config.yaml --file conditionvariants.txt\n\n"
               + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-c", "--config", type=Path, required=True, metavar="FILE",
                        help="The configuration file (YAML).")
    add_arguments(parser)
    parser.add_argument("--log", type=Path, default=None, metavar="FILE",
                        help="Also write messages to this log file. Optional.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print the bcftools commands.")
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    args = parser.parse_args(argv)

    logger.setLevel(logging.DEBUG if args.verbose else logging.INFO)
    logger.handlers.clear()
    screen = logging.StreamHandler(sys.stdout)
    screen.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(screen)
    if args.log:
        to_file = logging.FileHandler(args.log, mode="a", encoding="utf-8")
        to_file.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"))
        logger.addHandler(to_file)

    try:
        config = load_config(args.config)
    except ConfigError as error:
        logger.error("The configuration file is NOT valid: %s", args.config)
        for message in error.messages:
            logger.error("  * %s", message)
        return 1
    return run(config, args)


if __name__ == "__main__":
    sys.exit(main())
