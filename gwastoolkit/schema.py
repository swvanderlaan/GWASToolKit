"""
The standard results table of GWASToolKit.

Every association engine (SNPTEST, PLINK, REGENIE) writes its results in its
own layout. An "adapter" per engine converts those results to the one layout
defined here, so that every later step (merging, QC, plots, clumping) works the
same way whatever engine was used.

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import io
import math

VERSION_NAME = "GWASToolKit standard schema"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

# The columns of the standard table, in order.
STANDARD_COLUMNS = [
    "phenotype",      # name of the phenotype
    "engine",         # snptest, plink2, plink1 or regenie
    "variant_id",     # as in the genotype data, e.g. chr1:12345:A:G or rs123
    "chr",            # chromosome without 'chr' prefix or leading zero: 1-22, X
    "pos",            # base pair position
    "effect_allele",  # the allele that `beta` and `eaf` refer to
    "other_allele",   # the other allele
    "eaf",            # frequency of the effect allele
    "maf",            # minor allele frequency
    "mac",            # minor allele count
    "n",              # number of samples analysed
    "info",           # imputation quality
    "beta",           # effect size per effect allele (log odds for binary phenotypes)
    "se",             # standard error of beta
    "z",              # beta / se
    "p",              # p-value
    "hwe_p",          # Hardy-Weinberg equilibrium p-value
    # Columns kept from GWASToolKit v1.x; NA for engines that do not report them.
    # In the genotype counts, A is the other allele and B the effect allele.
    "alt_id",             # second identifier of the variant, if the data have one (v1.x: ALTID)
    "avg_max_post_call",  # average maximum posterior genotype probability (v1.x: AvgMaxPostCall)
    "all_aa",             # (expected) number of samples with genotype AA: no effect allele
    "all_ab",             # (expected) number of samples with genotype AB: one effect allele
    "all_bb",             # (expected) number of samples with genotype BB: two effect alleles
    "model_status",   # 'ok', or the message of the engine if something was wrong
]

MISSING = "NA"
# How the engines write a missing value.
MISSING_VALUES = {"", "NA", "na", "NaN", "nan", "-nan", "inf", "-inf", ".", "---"}


def is_missing(value: str) -> bool:
    """True if a value from an engine's output means 'missing'."""
    return value in MISSING_VALUES


def to_float(value: str):
    """Convert text to a number; returns None for missing or unreadable values."""
    if is_missing(value):
        return None
    try:
        number = float(value)
    except ValueError:
        return None
    return number if math.isfinite(number) else None


def format_number(number) -> str:
    """Write a number with six significant digits, or NA if there is none."""
    return MISSING if number is None else f"{number:.6g}"


def normalise_chromosome(value: str) -> str:
    """'chr1', '01' and '1' all become '1'; '23' and 'chrX' become 'X'."""
    text = str(value).strip()
    if text.lower().startswith("chr"):
        text = text[3:]
    text = text.lstrip("0").upper()
    return "X" if text == "23" else text


def open_text(path, mode: str = "rt"):
    """Open a text file for reading or writing; files ending in .gz are (de)compressed."""
    writing = "w" in mode
    if str(path).endswith(".gz"):
        if writing:
            # mtime=0: the same content always gives the same compressed file.
            return io.TextIOWrapper(gzip.GzipFile(path, "wb", mtime=0), encoding="utf-8", newline="\n")
        return gzip.open(path, "rt", encoding="utf-8")
    return open(path, "w" if writing else "r", encoding="utf-8")
