"""
What to analyse: the "targets" of each mode.

A target is a named set of regions on ONE chromosome. The workflow runs the
association engine once per target, chromosome and phenotype.

Mode      Targets
--------  ---------------------------------------------------------------
GWAS      one target, 'gwas', on every chromosome of the dataset (whole chromosomes)
VARIANT   one target, 'variants', on every chromosome that has variants in
          the variant list; one region of a single base pair per variant
REGION    one target named after the region, e.g. 'chr1_154376264_154476264'
GENES     one target per gene, named after the gene: the gene plus `targets.range`
          base pairs on either side

For the modes VARIANT, REGION and GENES the regions are extracted from the
genotype data ONCE, into a small file, and the engine runs on that small file.
(GWASToolKit v1.x started one job per variant or gene, each reading a whole chromosome.)

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import os
import re
from dataclasses import dataclass, field
from typing import Dict, List, Tuple

from gwastoolkit.config import Config, read_list
from gwastoolkit.schema import normalise_chromosome, open_text

VERSION_NAME = "GWASToolKit targets"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

# Names that a column with the chromosome or the position may have in a variant list with a header.
CHROMOSOME_NAMES = {"chr", "chrom", "chromosome"}
POSITION_NAMES = {"bp", "pos", "position"}


class TargetError(Exception):
    """Raised when the targets cannot be made; holds a list of readable messages."""

    def __init__(self, messages: List[str]):
        self.messages = messages
        super().__init__("\n".join(messages))


@dataclass
class Target:
    """A named set of regions on one chromosome. No regions means: the whole chromosome."""

    name: str
    chromosome: str
    regions: List[Tuple[int, int]] = field(default_factory=list)  # (start, end), 1-based, inclusive

    @property
    def ranges(self) -> List[str]:
        """The regions as SNPTEST wants them for -range: ['100-200', '500-900']."""
        return [f"{start}-{end}" for start, end in self.regions]

    def regions_text(self, contig_prefix: str) -> str:
        """The regions as a file for bcftools: chromosome, start, end (tab-separated)."""
        contig = f"{contig_prefix}{self.chromosome}"
        return "".join(f"{contig}\t{start}\t{end}\n" for start, end in self.regions)


def merge_regions(regions: List[Tuple[int, int]]) -> List[Tuple[int, int]]:
    """Sort regions and join those that overlap or touch, so no variant is extracted twice."""
    merged: List[Tuple[int, int]] = []
    for start, end in sorted(regions):
        if merged and start <= merged[-1][1] + 1:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))
    return merged


def chromosome_order(chromosome: str) -> int:
    """Sorting key: 1, 2, ..., 22, X."""
    return 23 if chromosome == "X" else int(chromosome)


def safe_name(name: str) -> str:
    """Make a name usable in file names: anything but letters, digits, '_' and '-' becomes '_'."""
    return re.sub(r"[^A-Za-z0-9_-]", "_", name)


def read_variant_list(path) -> List[Tuple[str, int]]:
    """
    Read a variant list; returns (chromosome, position) per variant.

    Two layouts are accepted:
      * without a header: `variant_id chromosome position`
      * with a header naming the columns; the chromosome column is called
        chr/chrom/chromosome and the position column bp/pos/position
        (e.g. `RSID VariantID Chr BP REF ALT`).
    Variants are found by POSITION, not by identifier, so the list works
    whatever identifiers the genotype data use.
    """
    variants = []
    chromosome_column, position_column = 1, 2
    problems = []
    with open(path, "r", encoding="utf-8") as handle:
        for number, line in enumerate(handle, start=1):
            fields = line.split()
            if not fields or line.startswith("#"):
                continue
            lowered = [value.lower() for value in fields]
            if not variants and CHROMOSOME_NAMES & set(lowered) and POSITION_NAMES & set(lowered):
                # A header line: find the columns by name.
                chromosome_column = next(i for i, value in enumerate(lowered) if value in CHROMOSOME_NAMES)
                position_column = next(i for i, value in enumerate(lowered) if value in POSITION_NAMES)
                continue
            if len(fields) <= max(chromosome_column, position_column) or not fields[position_column].isdigit():
                problems.append(f"{path}, line {number}: expected `variant_id chromosome position`")
                continue
            variants.append((normalise_chromosome(fields[chromosome_column]), int(fields[position_column])))
    if not variants and not problems:
        problems.append(f"{path}: no variants found")
    if problems:
        raise TargetError(problems)
    return variants


def read_gene_coordinates(path) -> Dict[str, List[Tuple[str, int, int]]]:
    """Read gene coordinates (`chromosome start end symbol`); returns per symbol its (chromosome, start, end)."""
    genes: Dict[str, List[Tuple[str, int, int]]] = {}
    with open_text(path, "rt") as handle:
        for line in handle:
            fields = line.split()
            if len(fields) < 4 or not fields[1].isdigit() or not fields[2].isdigit():
                continue
            genes.setdefault(fields[3], []).append((normalise_chromosome(fields[0]), int(fields[1]), int(fields[2])))
    return genes


def load_targets(config: Config) -> List[Target]:
    """
    Make the targets for the mode in the configuration.

    Raises TargetError if a target file cannot be used, a gene is unknown, or a
    target lies on a chromosome the dataset has no data for.
    """
    mode = config.analysis.mode
    dataset = config.active_dataset
    available = dataset.chromosomes + (["X"] if dataset.path_chrx else [])
    problems: List[str] = []

    # Collect regions per (target name, chromosome).
    collected: Dict[Tuple[str, str], List[Tuple[int, int]]] = {}

    if mode == "GWAS":
        return [Target("gwas", chromosome) for chromosome in dataset.chromosomes]

    if mode == "VARIANT":
        for chromosome, position in read_variant_list(config.targets.variant_file):
            collected.setdefault(("variants", chromosome), []).append((position, position))

    elif mode == "REGION":
        region = config.targets.region
        name = f"chr{region.chr}_{region.start}_{region.end}"
        collected[(name, region.chr)] = [(max(1, region.start), region.end)]

    elif mode == "GENES":
        genes_path = config.reference_path(config.active_references.genes)
        if not genes_path:
            raise TargetError([
                f"references.{dataset.build}.genes is empty: mode GENES needs gene coordinates for build {dataset.build}"
            ])
        if not os.path.isfile(genes_path):
            raise TargetError([
                f"gene coordinates not found: {genes_path}. Make them with `gwastoolkit make-gene-list`, "
                f"or set references.{dataset.build}.genes to your own file."
            ])
        coordinates = read_gene_coordinates(genes_path)
        extra = config.targets.range
        for symbol in read_list(config.targets.gene_file):
            if symbol not in coordinates:
                problems.append(f"gene {symbol} is not in the gene coordinates ({genes_path})")
                continue
            # A gene listed more than once (e.g. several transcripts): take the widest span.
            chromosomes = {chromosome for chromosome, _, _ in coordinates[symbol]}
            if len(chromosomes) > 1:
                problems.append(f"gene {symbol} is listed on more than one chromosome ({genes_path})")
                continue
            start = min(start for _, start, _ in coordinates[symbol])
            end = max(end for _, _, end in coordinates[symbol])
            collected[(safe_name(symbol), chromosomes.pop())] = [(max(1, start - extra), end + extra)]

    targets = []
    for (name, chromosome), regions in collected.items():
        if chromosome not in available:
            problems.append(
                f"target {name}: chromosome {chromosome} is not in dataset {config.analysis.dataset} "
                f"(available: {', '.join(available)})"
            )
            continue
        targets.append(Target(name, chromosome, merge_regions(regions)))
    if problems:
        raise TargetError(problems)
    if not targets:
        raise TargetError([f"no targets to analyse for mode {mode}"])
    return sorted(targets, key=lambda target: (target.name, chromosome_order(target.chromosome)))
