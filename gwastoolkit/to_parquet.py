"""
Write a standard results table as a Parquet file.

Parquet is a binary table format. Compared with a gzipped text file it loads
many times faster, keeps the type of every column (text, whole number,
decimal number, missing), and lets a program read only the columns it needs.
It is read directly by pandas (`pandas.read_parquet`), polars, R (`arrow`) and
DuckDB; a pandas table can be handed straight to GWASLab.

Column types
------------
text            phenotype, engine, variant_id, chr, effect_allele, other_allele, alt_id, model_status
whole number    pos
decimal number  eaf, maf, mac, n, info, beta, se, z, p, hwe_p, avg_max_post_call, all_aa, all_ab, all_bb

Note: a decimal number cannot hold a p-value below about 5e-324; such p-values
become 0 in the Parquet file. The gzipped text table keeps them as written.

Usage
-----
    python -m gwastoolkit.to_parquet --help

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path

from gwastoolkit.schema import MISSING, STANDARD_COLUMNS

VERSION_NAME = "GWASToolKit to_parquet"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

TEXT_COLUMNS = ["phenotype", "engine", "variant_id", "chr", "effect_allele", "other_allele", "alt_id",
                "model_status"]
INTEGER_COLUMNS = ["pos"]

logger = logging.getLogger("gwastoolkit.to_parquet")


def to_parquet(input_path, output_path) -> int:
    """
    Convert a standard results table (tab-separated, may be gzipped) to Parquet.

    Returns the number of variants written.
    Raises ValueError if the input does not have the standard columns.
    """
    # Imported here, so that the rest of GWASToolKit also works without polars.
    import polars as pl

    types = {}
    for name in STANDARD_COLUMNS:
        if name in TEXT_COLUMNS:
            types[name] = pl.String
        elif name in INTEGER_COLUMNS:
            types[name] = pl.Int64
        else:
            types[name] = pl.Float64

    table = pl.read_csv(input_path, separator="\t", null_values=[MISSING], schema_overrides=types)
    if table.columns != STANDARD_COLUMNS:
        raise ValueError(f"{input_path} does not have the standard columns")
    table.write_parquet(output_path, compression="zstd")
    return table.height


def default_output_path(input_path: Path) -> Path:
    """Next to the input: <YYYYMMDD>_<input name>_annotated.parquet."""
    name = input_path.name
    for ending in (".gz", ".tsv", ".txt"):
        if name.endswith(ending):
            name = name[: -len(ending)]
    return input_path.parent / f"{datetime.now():%Y%m%d}_{name}_annotated.parquet"


def build_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        prog="python -m gwastoolkit.to_parquet",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Write a standard GWASToolKit results table as a Parquet file.",
        epilog="example:\n  python -m gwastoolkit.to_parquet --input BMI.summary.tsv.gz --output BMI.summary.parquet\n\n"
               "read the result in Python with:\n  import pandas; table = pandas.read_parquet('BMI.summary.parquet')\n\n"
               + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-i", "--input", type=Path, required=True, metavar="FILE",
                        help="Standard results table (tab-separated; may be gzipped).")
    parser.add_argument("-o", "--output", type=Path, default=None, metavar="FILE",
                        help="Parquet file to write. Default: next to the input, named "
                             "<YYYYMMDD>_<input name>_annotated.parquet.")
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
        n_variants = to_parquet(args.input, output)
    except ImportError:
        logger.error("The package `polars` is needed to write Parquet files; install it with: "
                     "mamba env update -f environment.yml")
        return 1
    except (ValueError, OSError) as error:
        logger.error("%s", error)
        return 1
    logger.info("Variants written: %d", n_variants)
    return 0


if __name__ == "__main__":
    sys.exit(main())
