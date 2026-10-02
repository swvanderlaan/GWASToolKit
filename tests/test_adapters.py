"""
Tests for the standard schema, the SNPTEST adapter, the merge step and the SNPTEST command.

The SNPTEST result files used here are written out in this file, following the
column layout SNPTEST v2.5 uses for quantitative and for binary phenotypes.

Run from the repository root with either of:
    python -m unittest discover -s tests -v
    pytest

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import importlib.util
import logging
import os
import tempfile
import unittest
from pathlib import Path

from gwastoolkit import engines
from gwastoolkit.adapters import snptest
from gwastoolkit.config import load_config
from gwastoolkit.merge import merge
from gwastoolkit.schema import STANDARD_COLUMNS, normalise_chromosome

REPOSITORY = Path(__file__).resolve().parent.parent
TEST_CONFIG = REPOSITORY / "tests" / "data" / "config.test.yaml"

# SNPTEST output for a quantitative phenotype (26 columns).
QUANTITATIVE = """\
# Analysis: "expected"
# Analysis properties: started at 2026-10-02 10:00:00
alternate_ids rsid chromosome position alleleA alleleB index average_maximum_posterior_call info cohort_1_AA cohort_1_AB cohort_1_BB cohort_1_NULL all_AA all_AB all_BB all_NULL all_total all_maf missing_data_proportion cohort_1_hwe frequentist_add_pvalue frequentist_add_info frequentist_add_beta_1 frequentist_add_se_1 comment
. chr1:10177:A:AC 01 10177 A AC 1 1 0.95 1290 49 2 0 1290 49 2 0 1341 0.0197614 0 0.0914172 0.567409 0.95 0.0778573 0.136111 NA
. chr1:10235:T:TA 01 10235 T TA 2 1 1 1341 0 0 0 1341 0 0 0 1341 0 0 1 NA NA NA NA NA
. chr1:20000:G:A 01 20000 G A 3 0.9 0.8 100 200 1041 0 100 200 1041 0 1341 0.149142 0 0.5 1.5e-320 0.8 -0.5 0.01 NA
--- rs123 NA 30000 C T 4 0.9 0.5 1000 300 41 0 1000 300 41 0 1341 0.142431 0 0.2 0.01 0.5 0.2 0.08 model_fit_error:failed_to_converge
# Completed successfully at 2026-10-02 10:05:00
"""

# SNPTEST output for a binary phenotype: extra cases_*/controls_* columns shift all positions.
BINARY = """\
# Analysis: "expected"
alternate_ids rsid chromosome position alleleA alleleB index average_maximum_posterior_call info cohort_1_AA cohort_1_AB cohort_1_BB cohort_1_NULL all_AA all_AB all_BB all_NULL all_total cases_AA cases_AB cases_BB cases_NULL cases_total controls_AA controls_AB controls_BB controls_NULL controls_total all_maf cases_maf controls_maf missing_data_proportion cohort_1_hwe cases_hwe controls_hwe het_OR het_OR_lower het_OR_upper hom_OR hom_OR_lower hom_OR_upper all_OR all_OR_lower all_OR_upper frequentist_add_pvalue frequentist_add_info frequentist_add_beta_1 frequentist_add_se_1 comment
. chr2:500:C:T 02 500 C T 1 0.98 0.9 600 300 100 0 600 300 100 0 1000 150 100 50 0 300 450 200 50 0 700 0.25 0.333333 0.214286 0 0.03 0.1 0.2 1.5 1.1 2.0 3.0 2.0 4.5 1.8 1.4 2.3 2.5e-06 0.9 0.587787 0.125 NA
"""


def read_table(path):
    """Read a standard table; returns a list of dicts (one per variant)."""
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        header = handle.readline().rstrip("\n").split("\t")
        return header, [dict(zip(header, line.rstrip("\n").split("\t"))) for line in handle]


class TestSchema(unittest.TestCase):
    def test_normalise_chromosome(self):
        for value, expected in (("chr1", "1"), ("01", "1"), ("1", "1"), ("22", "22"), ("chrX", "X"), ("23", "X"), ("x", "X")):
            self.assertEqual(normalise_chromosome(value), expected)


class TestSnptestAdapter(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def convert(self, text, **arguments):
        source = self.root / "result.out"
        source.write_text(text, encoding="ascii")
        target = self.root / "result.tsv.gz"
        n_variants = snptest.convert(source, target, **arguments)
        header, rows = read_table(target)
        self.assertEqual(header, STANDARD_COLUMNS)
        self.assertEqual(len(rows), n_variants)
        return rows

    def test_quantitative(self):
        rows = self.convert(QUANTITATIVE, phenotype="BMI", chromosome="1")
        self.assertEqual(len(rows), 4)
        first = rows[0]
        self.assertEqual((first["phenotype"], first["engine"]), ("BMI", "snptest"))
        self.assertEqual((first["variant_id"], first["chr"], first["pos"]), ("chr1:10177:A:AC", "1", "10177"))
        # Allele B is the effect allele.
        self.assertEqual((first["effect_allele"], first["other_allele"]), ("AC", "A"))
        # eaf = (2*2 + 49) / (2*1341); mac = 2 * 1341 * maf = 53.
        self.assertAlmostEqual(float(first["eaf"]), 53 / 2682, places=6)
        self.assertAlmostEqual(float(first["mac"]), 53, places=3)
        self.assertEqual(first["n"], "1341")
        self.assertAlmostEqual(float(first["z"]), 0.0778573 / 0.136111, places=4)
        self.assertEqual((first["p"], first["model_status"]), ("0.567409", "ok"))
        # The columns kept from v1.x: ALTID, AvgMaxPostCall and the genotype counts.
        self.assertEqual((first["alt_id"], first["avg_max_post_call"]), ("NA", "1"))
        self.assertEqual((first["all_aa"], first["all_ab"], first["all_bb"]), ("1290", "49", "2"))
        self.assertEqual((rows[2]["avg_max_post_call"], rows[3]["alt_id"]), ("0.9", "NA"))

    def test_monomorphic_variant_has_no_statistics(self):
        row = self.convert(QUANTITATIVE, phenotype="BMI")[1]
        self.assertEqual((row["beta"], row["se"], row["z"], row["p"]), ("NA", "NA", "NA", "NA"))
        self.assertEqual(float(row["mac"]), 0)

    def test_effect_allele_frequency_above_half(self):
        row = self.convert(QUANTITATIVE, phenotype="BMI")[2]
        self.assertAlmostEqual(float(row["eaf"]), (2 * 1041 + 200) / 2682, places=6)
        self.assertAlmostEqual(float(row["maf"]), 1 - (2 * 1041 + 200) / 2682, places=6)
        # A p-value too small for a floating point number is kept as SNPTEST wrote it.
        self.assertEqual(row["p"], "1.5e-320")
        self.assertAlmostEqual(float(row["z"]), -50, places=6)

    def test_missing_chromosome_and_comment(self):
        row = self.convert(QUANTITATIVE, phenotype="BMI", chromosome="chr1")[3]
        self.assertEqual((row["variant_id"], row["chr"]), ("rs123", "1"))
        self.assertEqual(row["model_status"], "model_fit_error:failed_to_converge")
        # Without a fallback chromosome it stays missing.
        self.assertEqual(self.convert(QUANTITATIVE, phenotype="BMI")[3]["chr"], "NA")

    def test_binary_layout(self):
        row = self.convert(BINARY, phenotype="T2D")[0]
        self.assertEqual((row["chr"], row["pos"], row["effect_allele"]), ("2", "500", "T"))
        self.assertEqual((row["beta"], row["se"], row["p"]), ("0.587787", "0.125", "2.5e-06"))
        self.assertEqual((row["info"], row["hwe_p"], row["n"]), ("0.9", "0.03", "1000"))
        self.assertAlmostEqual(float(row["eaf"]), 0.25, places=6)

    def test_not_snptest_output(self):
        for text in ("some other file\n1 2 3\n", "# only comments\n"):
            with self.assertRaises(snptest.SnptestFormatError):
                self.convert(text, phenotype="BMI")

    def test_command_line(self):
        logging.disable(logging.CRITICAL)  # keep the test output clean
        self.addCleanup(logging.disable, logging.NOTSET)
        source = self.root / "BMI.chr1.out"
        source.write_text(QUANTITATIVE, encoding="ascii")
        target = self.root / "out.tsv.gz"
        self.assertEqual(snptest.main(["--input", str(source), "--output", str(target), "--phenotype", "BMI"]), 0)
        self.assertEqual(len(read_table(target)[1]), 4)
        # Without --output: next to the input, date-prefixed, with the _annotated suffix.
        self.assertEqual(snptest.main(["--input", str(source), "--phenotype", "BMI"]), 0)
        self.assertEqual(len(list(self.root.glob("*_BMI.chr1_annotated.tsv.gz"))), 1)
        self.assertEqual(snptest.main(["--input", str(self.root / "missing.out"), "--phenotype", "BMI"]), 1)

    def test_merge(self):
        first = self.root / "a.tsv.gz"
        second = self.root / "b.tsv.gz"
        for text, target, phenotype in ((QUANTITATIVE, first, "BMI"), (BINARY, second, "BMI")):
            source = self.root / "x.out"
            source.write_text(text, encoding="ascii")
            snptest.convert(source, target, phenotype)
        merged = self.root / "merged.tsv.gz"
        self.assertEqual(merge([first, second], merged), 5)
        header, rows = read_table(merged)
        self.assertEqual(header, STANDARD_COLUMNS)
        self.assertEqual([row["chr"] for row in rows], ["1", "1", "1", "NA", "2"])
        with self.assertRaises(ValueError):
            plain = self.root / "plain.tsv"
            plain.write_text("a\tb\n1\t2\n", encoding="ascii")
            merge([plain], merged)


@unittest.skipUnless(importlib.util.find_spec("polars"), "polars is not installed")
class TestParquet(unittest.TestCase):
    def test_to_parquet(self):
        import polars as pl

        from gwastoolkit import to_parquet

        logging.disable(logging.CRITICAL)
        self.addCleanup(logging.disable, logging.NOTSET)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, table, target = root / "x.out", root / "x.tsv.gz", root / "x.parquet"
            source.write_text(QUANTITATIVE, encoding="ascii")
            snptest.convert(source, table, "BMI", "1")
            self.assertEqual(to_parquet.main(["--input", str(table), "--output", str(target)]), 0)

            result = pl.read_parquet(target)
            self.assertEqual(result.columns, STANDARD_COLUMNS)
            self.assertEqual(result.height, 4)
            # Text stays text (chromosome too), numbers are numbers, NA is missing.
            self.assertEqual(result.schema["chr"], pl.String)
            self.assertEqual(result.schema["pos"], pl.Int64)
            self.assertEqual(result.schema["p"], pl.Float64)
            self.assertEqual(result["pos"].to_list(), [10177, 10235, 20000, 30000])
            self.assertIsNone(result["beta"][1])
            self.assertAlmostEqual(result["beta"][2], -0.5)
            self.assertEqual(result["model_status"][3], "model_fit_error:failed_to_converge")

            plain = root / "plain.tsv"
            plain.write_text("a\tb\n1\t2\n", encoding="ascii")
            self.assertEqual(to_parquet.main(["--input", str(plain), "--output", str(target)]), 1)


class TestSnptestCommand(unittest.TestCase):
    def setUp(self):
        # The paths in the test configuration are relative to the repository root.
        self.previous_directory = os.getcwd()
        os.chdir(REPOSITORY)
        self.addCleanup(os.chdir, self.previous_directory)
        self.config = load_config(TEST_CONFIG)

    def test_default_command(self):
        command = engines.snptest_command(self.config, "BMI", "21", "out/BMI.chr21.out")
        self.assertEqual(
            command,
            "snptest -data tests/data/fake.chr21.vcf.gz tests/data/fake.sample -genotype_field GP "
            "-pheno BMI -frequentist 1 -method expected -use_raw_phenotypes -hwe -lower_sample_limit 10 "
            "-cov_names Age SEX PC1 PC2 -exclude_samples_where SELECTION=not_selected -o out/BMI.chr21.out",
        )

    def test_options_follow_the_configuration(self):
        analysis = self.config.analysis
        analysis.standardize = "STANDARDIZE"
        analysis.exclusion_column = analysis.exclusion_value = ""
        analysis.condition, analysis.condition_file = True, "tests/data/genelist.txt"
        command = engines.snptest_command(self.config, "BMI", "22", "o.out", variant_ranges=["100-200", "500-900"])
        self.assertIn("-quantile_normalise_phenotypes", command)
        self.assertNotIn("-use_raw_phenotypes", command)
        self.assertNotIn("-exclude_samples_where", command)
        self.assertIn("-condition_on FAKEGENE1 FAKEGENE2", command)
        self.assertIn("-range 100-200 500-900", command)

        # SCALE: neither option, so SNPTEST scales to mean 0 and variance 1.
        analysis.standardize = "SCALE"
        command = engines.snptest_command(self.config, "BMI", "22", "o.out")
        self.assertNotIn("phenotypes", command)

        analysis.method, analysis.baseline_phenotype = "newml", "control"
        command = engines.snptest_command(self.config, "T2D", "22", "o.out", genotypes="small file.bgen")
        self.assertIn("-method newml -baseline_phenotype control", command)
        # Paths with spaces are quoted.
        self.assertIn("-data 'small file.bgen'", command)

    def test_method_auto_is_newml_for_targeted_modes(self):
        self.config.analysis.mode = "REGION"
        command = engines.snptest_command(self.config, "BMI", "21", "o.out", variant_ranges=["100-200"])
        self.assertIn("-method newml -use_raw_phenotypes", command)
        self.assertNotIn("-baseline_phenotype", command)


class TestExtractCommand(unittest.TestCase):
    def test_index_decides_how_bcftools_reads(self):
        previous = os.getcwd()
        os.chdir(REPOSITORY)
        self.addCleanup(os.chdir, previous)
        config = load_config(TEST_CONFIG)
        with tempfile.TemporaryDirectory() as directory:
            genotypes = Path(directory) / "data.chr{chr}.vcf.gz"
            config.active_dataset.path = str(genotypes)
            # No index: read through the file.
            command = engines.bcftools_extract_command(config, "21", "regions.tsv", "out.vcf.gz")
            self.assertTrue(command.startswith("bcftools view --targets-file regions.tsv --output-type z"))
            self.assertTrue(command.endswith("data.chr21.vcf.gz"))
            # With an index: jump to the regions.
            Path(str(genotypes).replace("{chr}", "21") + ".tbi").touch()
            command = engines.bcftools_extract_command(config, "21", "regions.tsv", "out.vcf.gz")
            self.assertIn("--regions-file regions.tsv", command)


if __name__ == "__main__":
    unittest.main()
