#!/usr/bin/env python3
"""
A stand-in for SNPTEST, FOR TESTING THE WORKFLOW ONLY.

SNPTEST cannot be installed everywhere (for instance not through conda), so the
tests of the workflow use this script in its place. It accepts the SNPTEST
options that GWASToolKit uses and writes a file in the layout of SNPTEST's
`.out` files for a quantitative phenotype.

THIS IS NOT SNPTEST. The statistics are a plain linear regression of the
phenotype on the dosage, WITHOUT covariates, also for binary phenotypes. Never
use its output for anything but testing that the workflow steps fit together.

Supported options: -data <vcf> <sample>, -pheno <name>, -o <file>,
-exclude_samples_where <column>=<value> (a single '=', as SNPTEST v2.5.6 requires), -range <start-end> [<start-end> ...].
All other options are accepted and ignored.

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import math
import sys

VERSION_NAME = "fake_snptest"
VERSION = "1.0.0"
VERSION_DATE = "2026-10-02"

COLUMNS = [
    "alternate_ids", "rsid", "chromosome", "position", "alleleA", "alleleB", "index",
    "average_maximum_posterior_call", "info", "cohort_1_AA", "cohort_1_AB", "cohort_1_BB", "cohort_1_NULL",
    "all_AA", "all_AB", "all_BB", "all_NULL", "all_total", "all_maf", "missing_data_proportion",
    "cohort_1_hwe", "frequentist_add_pvalue", "frequentist_add_info", "frequentist_add_beta_1",
    "frequentist_add_se_1", "comment",
]


def main(argv) -> int:
    if "-help" in argv or "--help" in argv or "-h" in argv:
        print(__doc__)
        return 0

    def option(name, n_values=1):
        """The value(s) following an option, or None if the option is not given."""
        if name not in argv:
            return None
        position = argv.index(name)
        values = argv[position + 1: position + 1 + n_values]
        return values[0] if n_values == 1 else values

    data = option("-data", 2)
    phenotype = option("-pheno")
    output = option("-o")
    exclusion = option("-exclude_samples_where")
    # -range takes any number of 'start-end' values, up to the next option.
    ranges = []
    if "-range" in argv:
        for value in argv[argv.index("-range") + 1:]:
            if value.startswith("-"):
                break
            start, end = value.split("-")
            ranges.append((int(start), int(end)))
    if not data or len(data) != 2 or not phenotype or not output:
        print("fake_snptest: -data <vcf> <sample>, -pheno <name> and -o <file> are required", file=sys.stderr)
        return 1
    vcf_path, sample_path = data

    # Read the sample file: which samples to use, and their phenotype.
    with open(sample_path, "r", encoding="ascii") as handle:
        lines = handle.read().splitlines()
    header = lines[0].split()
    if phenotype not in header:
        print(f"fake_snptest: phenotype {phenotype} is not in the sample file", file=sys.stderr)
        return 1
    phenotype_column = header.index(phenotype)
    # Like SNPTEST: method newml only takes binary and discrete phenotypes.
    phenotype_type = lines[1].split()[phenotype_column]
    if option("-method") == "newml" and phenotype_type not in ("B", "D"):
        print(f"!! Error in function: PerVariantComputationManager::get_phenotypes(), argument(s): "
              f"phenotype_spec={phenotype}:{phenotype_type}: Expected a discrete phenotype (of type B or D)..",
              file=sys.stderr)
        return 255
    exclude_column = exclude_value = None
    if exclusion:
        # Like SNPTEST v2.5.6: only `column=value` or `column="value"`, with a single '='.
        name, _, exclude_value = exclusion.partition("=")
        exclude_value = exclude_value.strip('"')
        if not name or not exclude_value or exclude_value.startswith("=") or " " in exclusion or name not in header:
            print(f'!! Error in function: genfile::SampleFilter::create(), argument(s): spec="{exclusion}"',
                  file=sys.stderr)
            return 255
        exclude_column = header.index(name)
    values = []  # per sample: the phenotype, or None if the sample is not used
    for line in lines[2:]:
        fields = line.split()
        excluded = exclude_column is not None and fields[exclude_column] == exclude_value
        missing = fields[phenotype_column] == "NA"
        values.append(None if excluded or missing else float(fields[phenotype_column]))
    used = [index for index, value in enumerate(values) if value is not None]
    y = [values[index] for index in used]
    n = len(y)
    mean_y = sum(y) / n

    rows = []
    with gzip.open(vcf_path, "rt", encoding="ascii") as handle:
        for index, line in enumerate(line for line in handle if not line.startswith("#")):
            fields = line.rstrip("\n").split("\t")
            if ranges and not any(start <= int(fields[1]) <= end for start, end in ranges):
                continue
            genotypes = [fields[9 + sample].split(":") for sample in used]
            dosage = [float(genotype[1]) for genotype in genotypes]
            probabilities = [[float(p) for p in genotype[2].split(",")] for genotype in genotypes]
            n_aa, n_ab, n_bb = (sum(p[k] for p in probabilities) for k in range(3))
            frequency = sum(dosage) / (2 * n)
            info = fields[7].split("R2=")[1].split(";")[0]

            # Linear regression of the phenotype on the dosage.
            mean_x = sum(dosage) / n
            sxx = sum((x - mean_x) ** 2 for x in dosage)
            if sxx > 0:
                beta = sum((x - mean_x) * (v - mean_y) for x, v in zip(dosage, y)) / sxx
                residual = sum((v - mean_y - beta * (x - mean_x)) ** 2 for x, v in zip(dosage, y)) / (n - 2)
                se = math.sqrt(residual / sxx)
                p_value = math.erfc(abs(beta / se) / math.sqrt(2))
                statistics = [f"{p_value:.6g}", info, f"{beta:.6g}", f"{se:.6g}", "NA"]
            else:
                statistics = ["NA", "NA", "NA", "NA", "no_variation"]

            counts = [f"{n_aa:.3f}", f"{n_ab:.3f}", f"{n_bb:.3f}", "0"]
            rows.append(
                [".", fields[2], fields[0].replace("chr", "").zfill(2), fields[1], fields[3], fields[4], str(index + 1),
                 "1", info] + counts + counts
                + [str(n), f"{min(frequency, 1 - frequency):.6g}", "0", "1"] + statistics
            )

    with open(output, "w", encoding="ascii") as handle:
        handle.write("# Analysis: \"fake_snptest\" -- NOT SNPTEST, for testing the GWASToolKit workflow only\n")
        handle.write(" ".join(COLUMNS) + "\n")
        for row in rows:
            handle.write(" ".join(row) + "\n")
        handle.write("# Completed successfully at 2026-10-02 00:00:00\n")
    print(f"fake_snptest: {len(rows)} variants, {n} samples, phenotype {phenotype} -> {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
