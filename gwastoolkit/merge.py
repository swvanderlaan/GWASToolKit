"""
Merge standard results tables into one, for example the tables of all
chromosomes of one phenotype.

The tables are written one after the other, in the order given; the header is
written once. All input tables must have the standard columns.

Usage
-----
    python -m gwastoolkit.merge --help

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import logging
import sys
from pathlib import Path
from typing import List

from gwastoolkit.schema import STANDARD_COLUMNS, open_text

VERSION_NAME = "GWASToolKit merge"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

logger = logging.getLogger("gwastoolkit.merge")


def merge(input_paths: List, output_path) -> int:
    """
    Write the rows of all input tables to one output table.

    Returns the number of rows (variants) written.
    Raises ValueError if an input table does not have the standard columns.
    """
    expected_header = "\t".join(STANDARD_COLUMNS)
    n_rows = 0
    with open_text(output_path, "wt") as target:
        target.write(expected_header + "\n")
        for path in input_paths:
            with open_text(path, "rt") as source:
                header = source.readline().rstrip("\n")
                if header != expected_header:
                    raise ValueError(f"{path} does not have the standard columns")
                for line in source:
                    target.write(line)
                    n_rows += 1
    return n_rows


def build_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        prog="python -m gwastoolkit.merge",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Merge standard GWASToolKit results tables into one table.",
        epilog="example:\n  python -m gwastoolkit.merge --input BMI.chr21.tsv.gz BMI.chr22.tsv.gz "
               "--output BMI.summary.tsv.gz\n\n" + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-i", "--input", type=Path, required=True, nargs="+", metavar="FILE",
                        help="Standard tables to merge, in the order they should appear.")
    parser.add_argument("-o", "--output", type=Path, required=True, metavar="FILE",
                        help="Merged table to write (gzipped if the name ends in .gz).")
    parser.add_argument("--log", type=Path, default=None, metavar="FILE",
                        help="Also write messages to this log file. Optional.")
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    return parser


def main(argv=None) -> int:
    """Entry point; returns the exit code."""
    args = build_parser().parse_args(argv)

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
    logger.info("Merging %d table(s) into %s", len(args.input), args.output)
    try:
        n_rows = merge(args.input, args.output)
    except (ValueError, OSError) as error:
        logger.error("%s", error)
        return 1
    logger.info("Variants written: %d", n_rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
