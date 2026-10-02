"""
Make the gene coordinate files for genome builds 37 and 38, reproducibly.

Mode GENES needs to know where genes lie. This tool makes that list from the
GENCODE gene annotation of the human reference genome (https://www.gencodegenes.org),
for a FIXED release, so that everyone who runs it gets the same file.

Source per build (release 47 by default; change with --release)
---------------------------------------------------------------
b38  GENCODE annotation on GRCh38:
     .../release_47/gencode.v47.annotation.gtf.gz
b37  The SAME release, with coordinates mapped to GRCh37 by GENCODE:
     .../release_47/GRCh37_mapping/gencode.v47lift37.annotation.gtf.gz
     Both builds therefore hold the same set of genes (a few genes that cannot
     be mapped to GRCh37 are missing from the b37 list).

What is made (in --output, default <repository>/RESOURCES)
---------------------------------------------------------
genes.gencode_v47.b38.txt.gz
genes.gencode_v47lift37.b37.txt.gz
    (With --gene-types the types are part of the name, for example
    genes.gencode_v47.protein_coding.b38.txt.gz, so lists with different
    filters can be kept side by side.)
    No header; six columns separated by a space:
        chromosome start end symbol gene_id gene_type
    for example: 19 11089463 11133820 LDLR ENSG00000130164.14 protein_coding
    Positions are 1-based and inclusive. Chromosomes 1-22 and X, without 'chr'.
    Sorted by chromosome and start. GWASToolKit reads the first four columns.
<the same name>.info.txt
    Where the list came from: address, release, checksum of the downloaded
    file, date, number of genes. Keep it with the list.
downloads/
    The downloaded annotation files; they are used again on a next run.

Reproducibility
---------------
The downloaded file is checked against the MD5 checksum that GENCODE publishes
for the release. The gene list is written so that the same annotation file
always gives a byte-for-byte identical list.

Usage
-----
    gwastoolkit make-gene-list --help
    python -m gwastoolkit.make_gene_list --help

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import gzip
import hashlib
import logging
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple

from gwastoolkit.schema import normalise_chromosome, open_text
from gwastoolkit.targets import chromosome_order

VERSION_NAME = "GWASToolKit make_gene_list"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

REPOSITORY = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT = REPOSITORY / "RESOURCES"
DEFAULT_RELEASE = "47"
GENCODE = "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human"
# The chromosomes kept: the autosomes and X.
CHROMOSOMES = [str(number) for number in range(1, 23)] + ["X"]

logger = logging.getLogger("gwastoolkit.make_gene_list")


class GeneListError(Exception):
    """Raised when a gene list cannot be made."""


def source(build: str, release: str) -> Tuple[str, str]:
    """The directory (address) and file name of the GENCODE annotation for a build and release."""
    if build == "b38":
        return f"{GENCODE}/release_{release}", f"gencode.v{release}.annotation.gtf.gz"
    return f"{GENCODE}/release_{release}/GRCh37_mapping", f"gencode.v{release}lift37.annotation.gtf.gz"


def filter_label(gene_types: Optional[List[str]]) -> str:
    """The part of the file name that says which gene types were kept; empty for all types."""
    if not gene_types:
        return ""
    return "." + "+".join(sorted(re.sub(r"[^A-Za-z0-9_-]", "_", gene_type) for gene_type in gene_types))


def list_name(build: str, release: str, gene_types: Optional[List[str]] = None) -> str:
    """
    The name of the gene list for a build and release.

    A list restricted to some gene types says so in its name, for example
    genes.gencode_v47.protein_coding.b38.txt.gz or genes.gencode_v47.lncRNA+protein_coding.b38.txt.gz.
    """
    label = f"v{release}" if build == "b38" else f"v{release}lift37"
    return f"genes.gencode_{label}{filter_label(gene_types)}.{build}.txt.gz"


def md5_of(path: Path) -> str:
    """The MD5 checksum of a file."""
    digest = hashlib.md5()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def download(directory_url: str, file_name: str, downloads: Path) -> Tuple[Path, str]:
    """
    Download an annotation file (unless it is already there) and check it.

    Returns the path of the file and a line describing how it was checked.
    Raises GeneListError if the download fails or the checksum does not match.
    """
    downloads.mkdir(parents=True, exist_ok=True)
    target = downloads / file_name
    url = f"{directory_url}/{file_name}"

    if target.is_file():
        logger.info("Already downloaded: %s", target)
    else:
        logger.info("Downloading %s", url)
        partial = target.with_suffix(target.suffix + ".part")
        try:
            with urllib.request.urlopen(url, timeout=120) as response, open(partial, "wb") as handle:
                for block in iter(lambda: response.read(1 << 20), b""):
                    handle.write(block)
        except (urllib.error.URLError, OSError) as error:
            partial.unlink(missing_ok=True)
            raise GeneListError(
                f"could not download {url}: {error}. Without internet access, download the file elsewhere "
                "and give it with --gtf."
            ) from error
        partial.rename(target)

    # Compare with the checksum GENCODE publishes for this release.
    md5 = md5_of(target)
    try:
        with urllib.request.urlopen(f"{directory_url}/MD5SUMS", timeout=60) as response:
            published = dict(
                (name, checksum) for checksum, name in
                (line.split() for line in response.read().decode().splitlines() if len(line.split()) == 2)
            )
    except (urllib.error.URLError, OSError):
        logger.warning("The published checksums could not be read; the download was not verified.")
        return target, f"md5 {md5} (not compared with the published checksum)"
    if file_name not in published:
        logger.warning("No published checksum for %s; the download was not verified.", file_name)
        return target, f"md5 {md5} (no published checksum)"
    if published[file_name] != md5:
        raise GeneListError(
            f"{target} does not match the published checksum (the download may be incomplete). "
            "Delete the file and run again."
        )
    logger.info("Checksum matches the one published by GENCODE.")
    return target, f"md5 {md5} (matches the published checksum)"


def read_genes(gtf_path: Path, gene_types: Optional[List[str]] = None) -> List[Tuple[str, int, int, str, str, str]]:
    """
    Read the genes from a GTF annotation file (GENCODE or Ensembl).

    Only lines of type 'gene' on chromosomes 1-22 and X are used. Returns, sorted
    by chromosome and start: (chromosome, start, end, symbol, gene_id, gene_type).
    """
    attribute = re.compile(r'(\S+) "([^"]*)"')
    genes = []
    with open_text(gtf_path, "rt") as handle:
        for line in handle:
            if line.startswith("#"):
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 9 or fields[2] != "gene":
                continue
            chromosome = normalise_chromosome(fields[0])
            if chromosome not in CHROMOSOMES:
                continue  # chromosome Y, the mitochondrion, unplaced sequences
            attributes = dict(attribute.findall(fields[8]))
            # GENCODE says gene_type, Ensembl says gene_biotype.
            gene_type = attributes.get("gene_type") or attributes.get("gene_biotype") or "NA"
            if gene_types and gene_type not in gene_types:
                continue
            gene_id = attributes.get("gene_id", "NA")
            symbol = attributes.get("gene_name") or gene_id
            genes.append((chromosome, int(fields[3]), int(fields[4]), symbol, gene_id, gene_type))
    if not genes:
        raise GeneListError(f"no genes found in {gtf_path}; is it a GTF annotation file?")
    return sorted(genes, key=lambda gene: (chromosome_order(gene[0]), gene[1], gene[2], gene[3], gene[4]))


def write_gene_list(genes, path: Path) -> None:
    """Write the gene list; the same genes always give a byte-for-byte identical file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with gzip.GzipFile(path, "wb", mtime=0) as handle:
        for gene in genes:
            handle.write((" ".join(str(value) for value in gene) + "\n").encode("utf-8"))


def make_gene_list(build: str, release: str, output: Path, gtf: Optional[Path] = None,
                   gene_types: Optional[List[str]] = None) -> Path:
    """Make the gene list (and its .info.txt) for one build; returns the path of the list."""
    directory_url, file_name = source(build, release)
    if gtf is None:
        gtf_path, checked = download(directory_url, file_name, output / "downloads")
        origin = f"{directory_url}/{file_name}"
        path = output / list_name(build, release, gene_types)
    else:
        if not gtf.is_file():
            raise GeneListError(f"file not found: {gtf}")
        gtf_path, checked, origin = gtf, f"md5 {md5_of(gtf)}", f"{gtf} (given with --gtf)"
        name = gtf.name
        for ending in (".gz", ".gtf"):
            name = name[: -len(ending)] if name.endswith(ending) else name
        path = output / f"genes.{name}{filter_label(gene_types)}.{build}.txt.gz"

    logger.info("Reading genes from %s", gtf_path)
    genes = read_genes(gtf_path, gene_types)
    write_gene_list(genes, path)

    n_protein_coding = sum(1 for gene in genes if gene[5] == "protein_coding")
    info = [
        f"gene list        : {path.name}",
        f"genome build     : {build}",
        f"source           : {origin}",
        f"source checksum  : {checked}",
        f"gene types kept  : {', '.join(gene_types) if gene_types else 'all'}",
        f"chromosomes kept : 1-22 and X",
        f"genes            : {len(genes):,} ({n_protein_coding:,} protein coding)",
        f"columns          : chromosome start end symbol gene_id gene_type (1-based, inclusive; no header)",
        f"gene list md5    : {md5_of(path)}",
        f"made on          : {datetime.now():%Y-%m-%d} with {VERSION_NAME} {VERSION}",
    ]
    Path(str(path)[: -len(".txt.gz")] + ".info.txt").write_text("\n".join(info) + "\n", encoding="utf-8")
    logger.info("Written: %s (%s genes)", path, f"{len(genes):,}")
    return path


def add_arguments(parser: argparse.ArgumentParser) -> None:
    """The options of this tool (shared by `gwastoolkit make-gene-list` and `python -m`)."""
    parser.add_argument("--build", choices=["b37", "b38", "both"], default="both",
                        help="Genome build to make the list for. Default: %(default)s.")
    parser.add_argument("--release", default=DEFAULT_RELEASE, metavar="N",
                        help="GENCODE release. Keep this fixed within a project. Default: %(default)s.")
    parser.add_argument("-o", "--output", type=Path, default=DEFAULT_OUTPUT, metavar="DIR",
                        help="Output directory. Default: %(default)s.")
    parser.add_argument("--gtf", type=Path, default=None, metavar="FILE",
                        help="Use this GTF annotation file (GENCODE or Ensembl; may be gzipped) and do not "
                             "download anything. Needs --build b37 or --build b38 to say which build it is.")
    parser.add_argument("--gene-types", nargs="+", default=None, metavar="TYPE",
                        help="Keep only genes of these types, for example protein_coding lncRNA. The types "
                             "become part of the file name (genes.gencode_v47.protein_coding.b38.txt.gz). "
                             "Default: all types.")


def run(args: argparse.Namespace) -> int:
    """Make the gene list(s) with parsed arguments; returns the exit code."""
    if args.gtf is not None and args.build == "both":
        logger.error("With --gtf, say which build the file is: --build b37 or --build b38.")
        return 1
    builds = ["b37", "b38"] if args.build == "both" else [args.build]
    try:
        paths = [make_gene_list(build, args.release, args.output, args.gtf, args.gene_types) for build in builds]
    except GeneListError as error:
        logger.error("%s", error)
        return 1
    logger.info("")
    logger.info("Set in the `references` section of your configuration:")
    for build, path in zip(builds, paths):
        logger.info("  %s:  genes: \"%s\"", build, path)
    return 0


def main(argv=None) -> int:
    """Entry point of `python -m gwastoolkit.make_gene_list`; returns the exit code."""
    parser = argparse.ArgumentParser(
        prog="python -m gwastoolkit.make_gene_list",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Make the gene coordinate files for genome builds 37 and 38 from the GENCODE gene\n"
                    "annotation of the human reference genome, for a fixed release.",
        epilog="examples:\n"
               "  python -m gwastoolkit.make_gene_list\n"
               "      Download GENCODE release 47 and make the lists for b37 and b38 in RESOURCES/.\n"
               "  python -m gwastoolkit.make_gene_list --build b38 --gtf gencode.v47.annotation.gtf.gz\n"
               "      Make the b38 list from a file you already have; nothing is downloaded.\n\n" + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    add_arguments(parser)
    parser.add_argument("--log", type=Path, default=None, metavar="FILE",
                        help="Also write messages to this log file. Optional.")
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    args = parser.parse_args(argv)

    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    screen = logging.StreamHandler(sys.stdout)
    screen.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(screen)
    if args.log:
        to_file = logging.FileHandler(args.log, mode="a", encoding="utf-8")
        to_file.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"))
        logger.addHandler(to_file)
    logger.info("%s %s (%s)", VERSION_NAME, VERSION, VERSION_DATE)
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
