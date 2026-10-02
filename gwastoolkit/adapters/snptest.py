"""
Convert SNPTEST results (`.out` files) to the standard results table.

Columns are found BY NAME, never by position: SNPTEST writes different columns
for quantitative and binary phenotypes (binary adds cases_*/controls_* columns)
and for different methods, so positions cannot be relied on.

How the standard columns are filled
-----------------------------------
variant_id     `rsid` (for VCF input this is the ID column of the VCF);
               `alternate_ids` if rsid is missing.
chr            `chromosome`; if SNPTEST reports NA, the value given with --chromosome.
effect_allele  `alleleB` -- SNPTEST's beta is per copy of allele B.
other_allele   `alleleA`
eaf            (2 * all_BB + all_AB) / (2 * (all_AA + all_AB + all_BB))
maf            the smaller of eaf and 1 - eaf
mac            2 * (all_AA + all_AB + all_BB) * maf
n              `all_total`
info           `info`, or `all_info` (method newml)
beta, se       `frequentist_add_beta_1`, `frequentist_add_se_1` (the first
               column whose name starts with that, as newml adds a suffix)
p              `frequentist_add_pvalue`; for newml the likelihood ratio test,
               `frequentist_add_lrt_pvalue`
hwe_p          `cohort_1_hwe`
alt_id         `alternate_ids`
avg_max_post_call  `average_maximum_posterior_call`
all_aa, all_ab, all_bb  `all_AA`, `all_AB`, `all_BB` (A = other allele, B = effect allele)
model_status   'ok' if `comment` is NA, else the comment of SNPTEST

Usage
-----
    python -m gwastoolkit.adapters.snptest --help

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from gwastoolkit.schema import (
    MISSING, STANDARD_COLUMNS, format_number, is_missing, normalise_chromosome, open_text, to_float,
)

VERSION_NAME = "GWASToolKit SNPTEST adapter"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

logger = logging.getLogger("gwastoolkit.adapters.snptest")

# Columns that every SNPTEST result file must have.
REQUIRED_COLUMNS = ["rsid", "position", "alleleA", "alleleB", "all_AA", "all_AB", "all_BB", "all_total"]


class SnptestFormatError(Exception):
    """Raised when a file does not look like SNPTEST output."""


def _find_column(header: List[str], names: List[str], prefixes: List[str] = ()) -> Optional[int]:
    """Position of the first column with one of the names, else the first starting with one of the prefixes."""
    for name in names:
        if name in header:
            return header.index(name)
    for prefix in prefixes:
        for position, column in enumerate(header):
            if column.startswith(prefix):
                return position
    return None


def convert(input_path, output_path, phenotype: str, chromosome: Optional[str] = None) -> int:
    """
    Convert one SNPTEST result file to the standard table.

    Parameters
    ----------
    input_path : str or Path
        SNPTEST `.out` file (may be gzipped).
    output_path : str or Path
        Standard table to write (tab-separated; gzipped if the name ends in .gz).
    phenotype : str
        Name of the phenotype, written to the `phenotype` column.
    chromosome : str, optional
        Chromosome to use when SNPTEST reports NA for it.

    Returns
    -------
    int
        The number of variants written.
    """
    fallback_chromosome = normalise_chromosome(chromosome) if chromosome else MISSING
    n_variants = 0
    header = None

    with open_text(input_path, "rt") as source, open_text(output_path, "wt") as target:
        target.write("\t".join(STANDARD_COLUMNS) + "\n")
        for line in source:
            # SNPTEST starts and ends its files with comment lines.
            if line.startswith("#") or not line.strip():
                continue
            fields = line.split()

            if header is None:
                # The first line that is not a comment holds the column names.
                header = fields
                missing = [name for name in REQUIRED_COLUMNS if name not in header]
                if missing:
                    raise SnptestFormatError(
                        f"{input_path} does not look like SNPTEST output; missing column(s): {', '.join(missing)}"
                    )
                column = {name: header.index(name) for name in REQUIRED_COLUMNS}
                # Columns that differ between methods, or that may be absent.
                optional = {
                    "alternate_ids": _find_column(header, ["alternate_ids"]),
                    "chromosome": _find_column(header, ["chromosome"]),
                    "info": _find_column(header, ["info", "all_info"]),
                    "beta": _find_column(header, ["frequentist_add_beta_1"], ["frequentist_add_beta_1"]),
                    "se": _find_column(header, ["frequentist_add_se_1"], ["frequentist_add_se_1"]),
                    "p": _find_column(header, ["frequentist_add_pvalue", "frequentist_add_lrt_pvalue"]),
                    "hwe": _find_column(header, ["cohort_1_hwe", "all_hwe"]),
                    "post_call": _find_column(header, ["average_maximum_posterior_call"]),
                    "comment": _find_column(header, ["comment"]),
                }
                continue

            if len(fields) != len(header):
                raise SnptestFormatError(
                    f"{input_path}: a line has {len(fields)} values where the header has {len(header)} columns"
                )

            def value(name: str) -> str:
                position = optional[name]
                return MISSING if position is None else fields[position]

            # Identifier and position.
            variant_id = fields[column["rsid"]]
            if is_missing(variant_id):
                variant_id = value("alternate_ids")
            chromosome_value = value("chromosome")
            chromosome_text = fallback_chromosome if is_missing(chromosome_value) else normalise_chromosome(chromosome_value)

            # Allele frequency of allele B, from the (expected) genotype counts.
            n_aa = to_float(fields[column["all_AA"]])
            n_ab = to_float(fields[column["all_AB"]])
            n_bb = to_float(fields[column["all_BB"]])
            eaf = maf = mac = None
            if None not in (n_aa, n_ab, n_bb) and (n_aa + n_ab + n_bb) > 0:
                n_called = n_aa + n_ab + n_bb
                eaf = (2 * n_bb + n_ab) / (2 * n_called)
                maf = min(eaf, 1 - eaf)
                mac = 2 * n_called * maf

            # Effect size, and the z-score that follows from it.
            beta, se = to_float(value("beta")), to_float(value("se"))
            z = beta / se if beta is not None and se not in (None, 0) else None

            comment = value("comment")
            row = {
                "phenotype": phenotype,
                "engine": "snptest",
                "variant_id": variant_id,
                "chr": chromosome_text,
                "pos": fields[column["position"]],
                "effect_allele": fields[column["alleleB"]],
                "other_allele": fields[column["alleleA"]],
                "eaf": format_number(eaf),
                "maf": format_number(maf),
                "mac": format_number(mac),
                "n": format_number(to_float(fields[column["all_total"]])),
                "info": format_number(to_float(value("info"))),
                "beta": format_number(beta),
                "se": format_number(se),
                "z": format_number(z),
                # The p-value is copied as SNPTEST wrote it, so very small values keep their precision.
                "p": MISSING if to_float(value("p")) is None else value("p"),
                "hwe_p": format_number(to_float(value("hwe"))),
                "alt_id": MISSING if is_missing(value("alternate_ids")) else value("alternate_ids"),
                "avg_max_post_call": format_number(to_float(value("post_call"))),
                "all_aa": format_number(n_aa),
                "all_ab": format_number(n_ab),
                "all_bb": format_number(n_bb),
                "model_status": "ok" if is_missing(comment) else comment,
            }
            target.write("\t".join(row[name] for name in STANDARD_COLUMNS) + "\n")
            n_variants += 1

    if header is None:
        raise SnptestFormatError(f"{input_path} holds no results (SNPTEST may have failed; check its log)")
    return n_variants


def default_output_path(input_path: Path) -> Path:
    """Next to the input: <YYYYMMDD>_<input name>_annotated.tsv.gz."""
    name = input_path.name
    for ending in (".gz", ".out", ".txt"):
        if name.endswith(ending):
            name = name[: -len(ending)]
    return input_path.parent / f"{datetime.now():%Y%m%d}_{name}_annotated.tsv.gz"


def build_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        prog="python -m gwastoolkit.adapters.snptest",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Convert a SNPTEST result file (.out) to the standard GWASToolKit results table.",
        epilog="example:\n  python -m gwastoolkit.adapters.snptest --input BMI.chr21.out --phenotype BMI "
               "--chromosome 21\n\n" + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-i", "--input", type=Path, required=True, metavar="FILE",
                        help="SNPTEST result file (.out); may be gzipped.")
    parser.add_argument("-o", "--output", type=Path, default=None, metavar="FILE",
                        help="Standard table to write. Default: next to the input, named "
                             "<YYYYMMDD>_<input name>_annotated.tsv.gz.")
    parser.add_argument("-p", "--phenotype", required=True, help="Name of the phenotype that was analysed.")
    parser.add_argument("-c", "--chromosome", default=None,
                        help="Chromosome to use if SNPTEST reports NA for it. Optional.")
    parser.add_argument("--log", type=Path, default=None, metavar="FILE",
                        help="Also write messages to this log file. Optional.")
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    return parser


def main(argv=None) -> int:
    """Entry point; returns the exit code."""
    args = build_parser().parse_args(argv)
    output = args.output or default_output_path(args.input)

    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    screen = logging.StreamHandler(sys.stdout)
    screen.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"))
    logger.addHandler(screen)
    if args.log:
        to_file = logging.FileHandler(args.log, mode="a", encoding="utf-8")
        to_file.setFormatter(screen.formatter)
        logger.addHandler(to_file)

    logger.info("%s %s (%s)", VERSION_NAME, VERSION, VERSION_DATE)
    logger.info("Input : %s", args.input)
    logger.info("Output: %s", output)
    try:
        n_variants = convert(args.input, output, args.phenotype, args.chromosome)
    except (SnptestFormatError, OSError) as error:
        logger.error("%s", error)
        return 1
    logger.info("Variants written: %d", n_variants)
    return 0


if __name__ == "__main__":
    sys.exit(main())
