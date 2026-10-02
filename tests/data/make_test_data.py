#!/usr/bin/env python3
"""
Create a small FAKE imputed genotype dataset for testing GWASToolKit.

Nothing in this dataset is real: samples, genotypes, positions, genes and
phenotypes are all simulated. It is small enough to keep in the repository and
is fully reproducible: the same --seed always gives the same files.

What is made (in --output, default: the directory of this script)
------------------------------------------------------------------
fake.chr21.vcf.gz, fake.chr22.vcf.gz
    "Imputed" genotypes in the layout of the TOPMed/Michigan imputation
    servers: phased GT, dosage (DS) and genotype probabilities (GP) per sample;
    AF, MAF, R2 and TYPED/IMPUTED per variant. Chromosomes are named 'chr21'
    and 'chr22' (build 38 style). The files are BGZF-compressed, so they can be
    read with gzip and indexed with tabix/bcftools.
fake.sample
    SNPTEST sample file with covariates (Age, SEX, PC1-PC4), the SELECTION
    column used for exclusions, and three phenotypes:
      BMI    quantitative; one variant on chr21 has a real effect.
      T2D    binary (0/1);  one variant on chr22 has a real effect.
      NULLQT quantitative; no genetic effect at all.
phenotypes.txt, covariates.txt
    The phenotype and covariate lists, in the format GWASToolKit expects.
variantlist.txt
    Variants for the VARIANT mode: `variant_id chromosome position`.
genelist.txt, genes.fake_b38.txt.gz
    Two fake genes for the GENES mode, and their coordinates
    (`chromosome start end symbol`, the PLINK gene-list layout).
truth.txt
    The planted effects, to check that an analysis finds them.

How the genotypes are simulated
-------------------------------
1. Each variant gets an allele frequency (many rare, some common).
2. Common variants (frequency of 5% or more): a small set of "founder"
   haplotypes is drawn, and every sample haplotype is a mosaic of founders,
   switching founder now and then along the chromosome. Neighbouring common
   variants are therefore correlated (LD), as in real data.
   Rare variants are given to random haplotypes, independent of their neighbours.
3. Imputation is mimicked per variant with an imputation quality R2 between
   0.2 and 1: the imputed haplotype dosage is q * true allele + (1 - q) *
   allele frequency, with q = sqrt(R2). About 15% of the variants are
   "genotyped" (R2 = 1).

Usage
-----
    python tests/data/make_test_data.py --help
    python tests/data/make_test_data.py            # recreate the default dataset

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import argparse
import gzip
import logging
import math
import random
import struct
import sys
import zlib
from datetime import datetime
from pathlib import Path

VERSION_NAME = "make_test_data"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COPYRIGHT = (
    "The MIT License (MIT). Copyright (c) 2010-2026 Sander W. van der Laan | "
    "s.w.vanderlaan [at] gmail [dot] com."
)

# The two fake chromosomes: name, position of the first variant, fake gene symbol.
CHROMOSOMES = [("21", 20_000_000, "FAKEGENE1"), ("22", 30_000_000, "FAKEGENE2")]
# Planted effects: BMI changes by this many units per allele (chr21);
# the odds of T2D are multiplied by exp(this) per allele (chr22).
BMI_EFFECT_PER_ALLELE = 2.0
T2D_LOG_ODDS_PER_ALLELE = 1.0
N_FOUNDERS = 24
FOUNDER_SWITCH_PROBABILITY = 0.03
FRACTION_GENOTYPED = 0.15

logger = logging.getLogger(VERSION_NAME)


# ------------------------------------------------------------------------------
# Writing BGZF (the block-gzip format that tabix and bcftools need)
# ------------------------------------------------------------------------------
def bgzf_block(data: bytes) -> bytes:
    """Compress up to 64 kb of data into one BGZF block."""
    compressor = zlib.compressobj(6, zlib.DEFLATED, -15)
    compressed = compressor.compress(data) + compressor.flush()
    block_size = 18 + len(compressed) + 8  # header + data + trailer
    header = (
        b"\x1f\x8b\x08\x04"            # gzip magic, deflate, 'extra field present'
        + struct.pack("<I", 0)          # modification time: 0, so output is reproducible
        + b"\x00\xff"                   # extra flags, operating system: unknown
        + struct.pack("<H", 6)          # length of the extra field
        + b"BC" + struct.pack("<H", 2)  # BGZF sub-field
        + struct.pack("<H", block_size - 1)
    )
    trailer = struct.pack("<II", zlib.crc32(data), len(data))
    return header + compressed + trailer


def write_bgzf(path: Path, text: str) -> None:
    """Write text to a BGZF-compressed file (readable with plain gzip too)."""
    data = text.encode("ascii")
    with open(path, "wb") as handle:
        for start in range(0, len(data), 0xFF00):
            handle.write(bgzf_block(data[start:start + 0xFF00]))
        handle.write(bgzf_block(b""))  # the empty block that marks the end of a BGZF file


# ------------------------------------------------------------------------------
# Simulation
# ------------------------------------------------------------------------------
def draw_allele_frequency(rng: random.Random) -> float:
    """Allele frequency of the ALT allele: 60% of variants are rare-ish, 40% common."""
    if rng.random() < 0.6:
        return rng.uniform(0.005, 0.05)
    return rng.uniform(0.05, 0.5)


def simulate_chromosome(rng: random.Random, n_samples: int, n_variants: int, first_position: int):
    """
    Simulate one chromosome.

    Returns a list of variants; each variant is a dict with its position,
    alleles, imputation quality, the true alleles per haplotype ('truth') and
    the imputed dosage per haplotype ('dosage'). Haplotypes 2*i and 2*i+1
    belong to sample i.
    """
    n_haplotypes = 2 * n_samples

    # Positions: 200 to 3,000 bp apart.
    positions = []
    position = first_position
    for _ in range(n_variants):
        position += rng.randint(200, 3000)
        positions.append(position)

    frequencies = [draw_allele_frequency(rng) for _ in range(n_variants)]
    # Founder haplotypes: founders[f][v] is the allele (0/1) of founder f at variant v.
    founders = [[1 if rng.random() < frequencies[v] else 0 for v in range(n_variants)] for _ in range(N_FOUNDERS)]

    # Each sample haplotype copies a founder, and switches founder now and then.
    truth = [[0] * n_haplotypes for _ in range(n_variants)]
    for haplotype in range(n_haplotypes):
        founder = rng.randrange(N_FOUNDERS)
        for v in range(n_variants):
            if rng.random() < FOUNDER_SWITCH_PROBABILITY:
                founder = rng.randrange(N_FOUNDERS)
            truth[v][haplotype] = founders[founder][v]
    # Rare variants: too rare to be carried by a founder, so hand them out to random haplotypes.
    for v in range(n_variants):
        if frequencies[v] < 0.05:
            truth[v] = [1 if rng.random() < frequencies[v] else 0 for _ in range(n_haplotypes)]

    variants = []
    for v in range(n_variants):
        ref, alt = rng.choice([("A", "G"), ("G", "A"), ("C", "T"), ("T", "C"), ("A", "C"), ("G", "T")])
        genotyped = rng.random() < FRACTION_GENOTYPED
        # R2 is the squared correlation between imputed and true alleles, hence the square root.
        quality = 1.0 if genotyped else math.sqrt(rng.uniform(0.2, 1.0))
        observed_frequency = sum(truth[v]) / n_haplotypes
        # Imputed haplotype dosage: pulled towards the allele frequency when quality is low.
        dosage = [quality * allele + (1 - quality) * observed_frequency for allele in truth[v]]
        variants.append({
            "position": positions[v], "ref": ref, "alt": alt, "genotyped": genotyped,
            "truth": truth[v], "dosage": dosage, "frequency": observed_frequency,
        })
    # Variants where nobody carries the ALT allele are not informative; drop them.
    return [variant for variant in variants if 0 < variant["frequency"] < 1]


def imputation_r2(variant) -> float:
    """Imputation quality as the imputation servers report it: var(dosage) / (p * (1 - p))."""
    dosage = variant["dosage"]
    p = sum(dosage) / len(dosage)
    if p <= 0 or p >= 1:
        return 0.0
    variance = sum((d - p) ** 2 for d in dosage) / len(dosage)
    return min(1.0, variance / (p * (1 - p)))


def pick_causal_variant(variants):
    """The common (MAF > 0.2), well-imputed variant closest to the middle of the chromosome."""
    middle = len(variants) // 2
    candidates = [
        index for index, variant in enumerate(variants)
        if 0.2 < variant["frequency"] < 0.8 and imputation_r2(variant) > 0.8
    ]
    return min(candidates, key=lambda index: abs(index - middle))


def vcf_text(chromosome: str, variants, sample_ids) -> str:
    """Format the variants of one chromosome as a VCF file (as text)."""
    contig = f"chr{chromosome}"
    lines = [
        "##fileformat=VCFv4.2",
        "##source=GWASToolKit make_test_data.py -- FAKE, SIMULATED DATA; NOT FROM REAL PEOPLE",
        f"##contig=<ID={contig}>",
        '##INFO=<ID=AF,Number=1,Type=Float,Description="Estimated alternate allele frequency">',
        '##INFO=<ID=MAF,Number=1,Type=Float,Description="Estimated minor allele frequency">',
        '##INFO=<ID=R2,Number=1,Type=Float,Description="Estimated imputation accuracy (R-square)">',
        '##INFO=<ID=IMPUTED,Number=0,Type=Flag,Description="Marker was imputed">',
        '##INFO=<ID=TYPED,Number=0,Type=Flag,Description="Marker was genotyped">',
        '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
        '##FORMAT=<ID=DS,Number=1,Type=Float,Description="Estimated alternate allele dosage: [P(0/1)+2*P(1/1)]">',
        '##FORMAT=<ID=GP,Number=3,Type=Float,Description="Estimated posterior probabilities for genotypes 0/0, 0/1 and 1/1">',
        "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t" + "\t".join(sample_ids),
    ]
    for variant in variants:
        dosage = variant["dosage"]
        frequency = sum(dosage) / len(dosage)
        info = ";".join([
            f"AF={frequency:.5f}",
            f"MAF={min(frequency, 1 - frequency):.5f}",
            f"R2={imputation_r2(variant):.5f}",
            "TYPED" if variant["genotyped"] else "IMPUTED",
        ])
        genotypes = []
        for sample in range(len(sample_ids)):
            a, b = dosage[2 * sample], dosage[2 * sample + 1]
            # Probabilities of 0, 1 and 2 copies of the ALT allele; rounded so they sum to 1.
            p_het = round(a * (1 - b) + b * (1 - a), 3)
            p_hom_alt = round(a * b, 3)
            p_hom_ref = max(0.0, round(1 - p_het - p_hom_alt, 3))
            genotypes.append(
                f"{round(a)}|{round(b)}:{p_het + 2 * p_hom_alt:.3f}:{p_hom_ref:.3f},{p_het:.3f},{p_hom_alt:.3f}"
            )
        variant_id = f"{contig}:{variant['position']}:{variant['ref']}:{variant['alt']}"
        lines.append("\t".join(
            [contig, str(variant["position"]), variant_id, variant["ref"], variant["alt"], ".", "PASS", info, "GT:DS:GP"]
            + genotypes
        ))
    return "\n".join(lines) + "\n"


def simulate_samples(rng: random.Random, n_samples: int, bmi_alleles, t2d_alleles):
    """
    Simulate covariates and phenotypes; returns one dict per sample.

    `bmi_alleles` and `t2d_alleles` give, per sample, the true number of ALT
    alleles (0, 1 or 2) at the causal variant of each phenotype.
    """
    samples = []
    for index in range(n_samples):
        age = round(rng.gauss(65, 9))
        sex = rng.choice([1, 2])  # 1 = male, 2 = female
        pcs = [rng.gauss(0, 0.02) for _ in range(4)]
        bmi = 26 + BMI_EFFECT_PER_ALLELE * bmi_alleles[index] + 0.02 * (age - 65) - 0.6 * (sex - 1) + rng.gauss(0, 3.5)
        log_odds = -1.4 + T2D_LOG_ODDS_PER_ALLELE * t2d_alleles[index] + 0.03 * (age - 65)
        t2d = 1 if rng.random() < 1 / (1 + math.exp(-log_odds)) else 0
        samples.append({
            "id": f"FAKE{index + 1:04d}",
            "Age": str(age),
            "SEX": str(sex),
            "PC1": f"{pcs[0]:.5f}", "PC2": f"{pcs[1]:.5f}", "PC3": f"{pcs[2]:.5f}", "PC4": f"{pcs[3]:.5f}",
            "SELECTION": "selected",
            "BMI": f"{bmi:.2f}",
            "T2D": str(t2d),
            "NULLQT": f"{rng.gauss(0, 1):.4f}",
        })
    # A few samples are to be excluded, and a few phenotype values are missing.
    for sample in rng.sample(samples, k=max(1, n_samples // 40)):
        sample["SELECTION"] = "not_selected"
    for phenotype in ("BMI", "T2D", "NULLQT"):
        for sample in rng.sample(samples, k=max(1, n_samples // 50)):
            sample[phenotype] = "NA"
    return samples


def sample_file_text(samples) -> str:
    """Format the samples as a SNPTEST sample file (two header lines, then one line per sample)."""
    # Column types: 0 = identifier/missingness, D = discrete covariate,
    # C = continuous covariate, P = continuous phenotype, B = binary phenotype.
    columns = [("Age", "C"), ("SEX", "D"), ("PC1", "C"), ("PC2", "C"), ("PC3", "C"), ("PC4", "C"),
               ("SELECTION", "D"), ("BMI", "P"), ("T2D", "B"), ("NULLQT", "P")]
    lines = [
        "ID_1 ID_2 missing " + " ".join(name for name, _ in columns),
        "0 0 0 " + " ".join(kind for _, kind in columns),
    ]
    for sample in samples:
        lines.append(f"{sample['id']} {sample['id']} 0 " + " ".join(sample[name] for name, _ in columns))
    return "\n".join(lines) + "\n"


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
def make_dataset(output: Path, n_samples: int, n_variants: int, seed: int) -> None:
    """Simulate the dataset and write all files to `output`."""
    rng = random.Random(seed)
    sample_ids = [f"FAKE{index + 1:04d}" for index in range(n_samples)]

    chromosomes = {}
    causal = {}
    for chromosome, first_position, _ in CHROMOSOMES:
        variants = simulate_chromosome(rng, n_samples, n_variants, first_position)
        chromosomes[chromosome] = variants
        causal[chromosome] = variants[pick_causal_variant(variants)]
        logger.info("Chromosome %s: %d variants simulated.", chromosome, len(variants))

    def alleles_per_sample(variant):
        return [variant["truth"][2 * s] + variant["truth"][2 * s + 1] for s in range(n_samples)]

    samples = simulate_samples(rng, n_samples, alleles_per_sample(causal["21"]), alleles_per_sample(causal["22"]))

    def variant_id(chromosome, variant):
        return f"chr{chromosome}:{variant['position']}:{variant['ref']}:{variant['alt']}"

    # Genotypes.
    for chromosome, variants in chromosomes.items():
        path = output / f"fake.chr{chromosome}.vcf.gz"
        write_bgzf(path, vcf_text(chromosome, variants, sample_ids))
        logger.info("Written: %s (%.0f kb)", path, path.stat().st_size / 1024)

    # Samples, phenotype list and covariate list.
    (output / "fake.sample").write_text(sample_file_text(samples), encoding="ascii")
    (output / "phenotypes.txt").write_text("BMI\nT2D\nNULLQT\n", encoding="ascii")
    (output / "covariates.txt").write_text("Age SEX PC1 PC2\n", encoding="ascii")

    # Variant list: the two causal variants plus four others spread over both chromosomes.
    listed = []
    for chromosome, variants in chromosomes.items():
        picks = [causal[chromosome], variants[len(variants) // 5], variants[4 * len(variants) // 5]]
        listed += [(variant_id(chromosome, variant), f"chr{chromosome}", variant["position"]) for variant in picks]
    (output / "variantlist.txt").write_text(
        "".join(f"{name}\t{chromosome}\t{position}\n" for name, chromosome, position in listed), encoding="ascii"
    )

    # Fake genes: a 40 kb gene around each causal variant.
    gene_lines = []
    for chromosome, _, symbol in CHROMOSOMES:
        position = causal[chromosome]["position"]
        gene_lines.append(f"{chromosome} {position - 20000} {position + 20000} {symbol}\n")
    with gzip.GzipFile(output / "genes.fake_b38.txt.gz", "wb", mtime=0) as handle:
        handle.write("".join(gene_lines).encode("ascii"))
    (output / "genelist.txt").write_text("".join(f"{symbol}\n" for _, _, symbol in CHROMOSOMES), encoding="ascii")

    # The truth, to check results against.
    truth_lines = ["phenotype\tvariant_id\tchr\tpos\teffect_allele\ttrue_effect\tscale\tgene\n"]
    for phenotype, chromosome, effect, scale in (
        ("BMI", "21", BMI_EFFECT_PER_ALLELE, "units per allele"),
        ("T2D", "22", T2D_LOG_ODDS_PER_ALLELE, "log odds per allele"),
    ):
        variant = causal[chromosome]
        gene = next(symbol for name, _, symbol in CHROMOSOMES if name == chromosome)
        truth_lines.append(
            f"{phenotype}\t{variant_id(chromosome, variant)}\tchr{chromosome}\t{variant['position']}\t"
            f"{variant['alt']}\t{effect}\t{scale}\t{gene}\n"
        )
    truth_lines.append("NULLQT\tnone\tNA\tNA\tNA\t0\tno genetic effect\tNA\n")
    (output / "truth.txt").write_text("".join(truth_lines), encoding="ascii")

    logger.info("Written: fake.sample, phenotypes.txt, covariates.txt, variantlist.txt, genelist.txt, "
                "genes.fake_b38.txt.gz and truth.txt in %s", output)
    logger.info("Causal variant for BMI: %s", variant_id("21", causal["21"]))
    logger.info("Causal variant for T2D: %s", variant_id("22", causal["22"]))


def build_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        prog="make_test_data.py",
        description=f"{VERSION_NAME} {VERSION} ({VERSION_DATE}).\n"
                    "Create a small FAKE imputed genotype dataset (two chromosomes, VCF with GT:DS:GP,\n"
                    "a SNPTEST sample file and target lists) for testing GWASToolKit.",
        epilog="example:\n  python tests/data/make_test_data.py --samples 500 --variants 300 --seed 20261002\n\n"
               + COPYRIGHT,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-o", "--output", type=Path, default=Path(__file__).resolve().parent, metavar="DIR",
                        help="Output directory. Default: the directory of this script.")
    parser.add_argument("-n", "--samples", type=int, default=500, help="Number of samples. Default: %(default)s.")
    parser.add_argument("-m", "--variants", type=int, default=300,
                        help="Number of variants to simulate per chromosome. Default: %(default)s.")
    parser.add_argument("-s", "--seed", type=int, default=20261002,
                        help="Seed of the random number generator; the same seed gives the same files. "
                             "Default: %(default)s.")
    parser.add_argument("--log", action="store_true",
                        help="Also write a log file, <YYYYMMDD>_make_test_data.log, in the output directory.")
    parser.add_argument("-V", "--version", action="version", version=f"%(prog)s {VERSION} ({VERSION_DATE})")
    return parser


def main(argv=None) -> int:
    """Entry point; returns the exit code."""
    args = build_parser().parse_args(argv)
    if args.samples < 50 or args.variants < 50:
        print("error: use at least 50 samples and 50 variants.", file=sys.stderr)
        return 1
    args.output.mkdir(parents=True, exist_ok=True)

    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    screen = logging.StreamHandler(sys.stdout)
    screen.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(screen)
    if args.log:
        log_path = args.output / f"{datetime.now():%Y%m%d}_make_test_data.log"
        to_file = logging.FileHandler(log_path, mode="a", encoding="utf-8")
        to_file.setFormatter(logging.Formatter("%(asctime)s %(levelname)-8s %(message)s", "%Y-%m-%d %H:%M:%S"))
        logger.addHandler(to_file)

    logger.info("%s %s (%s)", VERSION_NAME, VERSION, VERSION_DATE)
    logger.info("Samples: %d; variants per chromosome: %d; seed: %d", args.samples, args.variants, args.seed)
    make_dataset(args.output, args.samples, args.variants, args.seed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
