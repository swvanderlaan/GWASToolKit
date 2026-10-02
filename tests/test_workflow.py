"""
Tests for the Snakemake workflow, run on the fake test dataset.

SNPTEST is replaced by tests/stubs/fake_snptest.py (a stand-in that writes
files in SNPTEST's layout), so these tests check that the steps of the workflow
fit together -- not SNPTEST itself. They are skipped if Snakemake is not installed.
bcftools (for extracting targets) and polars (for Parquet) must be installed too;
all three are in environment.yml.

Run from the repository root with either of:
    python -m unittest discover -s tests -v
    pytest

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import polars as pl
import yaml

REPOSITORY = Path(__file__).resolve().parent.parent
TEST_CONFIG = REPOSITORY / "tests" / "data" / "config.test.yaml"
FAKE_SNPTEST = REPOSITORY / "tests" / "stubs" / "fake_snptest.py"

# Snakemake is looked for next to the Python that runs the tests (the same environment), then on the PATH.
SNAKEMAKE_DIRECTORY = Path(sys.executable).parent
PHENOTYPES = ("BMI", "T2D", "NULLQT")
HAVE_SNAKEMAKE = (SNAKEMAKE_DIRECTORY / "snakemake").exists() or shutil.which("snakemake") is not None


@unittest.skipUnless(HAVE_SNAKEMAKE, "Snakemake is not installed")
class TestWorkflow(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

        # The test configuration, with the stand-in for SNPTEST and a temporary output directory.
        with open(TEST_CONFIG, "r", encoding="utf-8") as handle:
            self.settings = yaml.safe_load(handle)
        self.settings["site"]["snptest"] = str(FAKE_SNPTEST)
        self.settings["project"]["dir"] = str(self.root)
        self.output = self.root / self.settings["project"]["name"]

    def run_gwastoolkit(self, *arguments):
        """Run `gwastoolkit run` from the repository root; return (exit code, output)."""
        config_path = self.root / "config.yaml"
        with open(config_path, "w", encoding="utf-8") as handle:
            yaml.safe_dump(self.settings, handle)
        environment = dict(os.environ)
        environment["PATH"] = f"{SNAKEMAKE_DIRECTORY}{os.pathsep}{environment['PATH']}"
        result = subprocess.run(
            [sys.executable, "-m", "gwastoolkit", "run", "--config", str(config_path), *arguments],
            cwd=REPOSITORY, env=environment, capture_output=True, text=True,
        )
        return result.returncode, result.stdout + result.stderr

    def summary_path(self, target, phenotype, extension="tsv.gz"):
        return self.output / "results" / target / f"{target}.{phenotype}.EXCL_DEFAULT.snptest.summary.{extension}"

    def read_summary(self, target, phenotype):
        with gzip.open(self.summary_path(target, phenotype), "rt", encoding="utf-8") as handle:
            header = handle.readline().rstrip("\n").split("\t")
            return [dict(zip(header, line.rstrip("\n").split("\t"))) for line in handle]

    def truth(self):
        """The planted effects: per phenotype (variant_id, position, effect allele, effect)."""
        planted = {}
        for line in (REPOSITORY / "tests" / "data" / "truth.txt").read_text().splitlines()[1:]:
            fields = line.split("\t")
            planted[fields[0]] = (fields[1], fields[3], fields[4], fields[5])
        return planted

    def assert_top_hit_is_planted(self, rows, phenotype):
        variant_id, position, effect_allele, _ = self.truth()[phenotype]
        top = min((row for row in rows if row["p"] != "NA"), key=lambda row: float(row["p"]))
        self.assertEqual((top["variant_id"], top["pos"], top["effect_allele"]), (variant_id, position, effect_allele))
        self.assertGreater(float(top["beta"]), 0)
        self.assertLess(float(top["p"]), 1e-8)
        return top

    # ---------------------------------------------------------------- GWAS
    def test_dry_run_lists_all_jobs(self):
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertEqual(code, 0, output)
        # 3 phenotypes x 2 chromosomes; no extraction in a GWAS.
        self.assertRegex(output, r"snptest\s+6")
        self.assertRegex(output, r"standardise\s+6")
        self.assertRegex(output, r"merge\s+3")
        self.assertRegex(output, r"parquet\s+3")
        self.assertNotRegex(output, r"extract\s+\d")
        self.assertIn("-method expected", output)
        self.assertIn("-exclude_samples_where SELECTION=not_selected", output)
        self.assertFalse(self.output.exists())  # a dry run makes nothing

    def test_gwas_finds_the_planted_effects(self):
        code, output = self.run_gwastoolkit("--cores", "2")
        self.assertEqual(code, 0, output)
        for phenotype in PHENOTYPES:
            rows = self.read_summary("gwas", phenotype)
            # Both chromosomes are in the merged table, chromosome 21 first.
            self.assertEqual(len(rows), 592)
            self.assertEqual(sorted({row["chr"] for row in rows}), ["21", "22"])
            self.assertEqual(rows[0]["chr"], "21")
            self.assertTrue(all(row["phenotype"] == phenotype and row["engine"] == "snptest" for row in rows))
            # 500 samples, minus the 12 excluded, minus the missing phenotype values.
            self.assertTrue(all(470 <= float(row["n"]) <= 488 for row in rows))
            # The Parquet file holds the same table.
            table = pl.read_parquet(self.summary_path("gwas", phenotype, "parquet"))
            self.assertEqual(table["variant_id"].to_list(), [row["variant_id"] for row in rows])

            if phenotype == "NULLQT":
                self.assertGreater(min(float(row["p"]) for row in rows if row["p"] != "NA"), 1e-5)
            else:
                top = self.assert_top_hit_is_planted(rows, phenotype)
                if phenotype == "BMI":
                    self.assertAlmostEqual(float(top["beta"]), float(self.truth()["BMI"][3]), delta=0.6)
        # No table with all phenotypes for a GWAS.
        self.assertFalse(self.summary_path("gwas", "ALL_PHENOTYPES").exists())

    def test_second_run_has_nothing_to_do(self):
        self.assertEqual(self.run_gwastoolkit("--cores", "2")[0], 0)
        code, output = self.run_gwastoolkit("--cores", "2")
        self.assertEqual(code, 0, output)
        self.assertIn("Nothing to be done", output)

    def test_mail_options_reach_the_jobs(self):
        self.settings["slurm"] = {"email": "me@example.org", "mail_type": "END,FAIL"}
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertEqual(code, 0, output)
        self.assertIn("slurm_extra=--mail-user=me@example.org --mail-type=END,FAIL", output)

    # ------------------------------------------------- VARIANT, REGION, GENES
    def test_variant_mode(self):
        self.settings["analysis"]["mode"] = "VARIANT"
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertEqual(code, 0, output)
        # The default in the targeted modes: newml for the binary phenotype, expected for the continuous ones.
        self.assertIn("-pheno T2D -frequentist 1 -method newml", output)
        self.assertIn("-pheno BMI -frequentist 1 -method expected", output)
        # SNPTEST reads the small extracted files, not the dataset.
        self.assertIn("-data " + str(self.output / "extract" / "variants" / "variants.chr21.vcf.gz"), output)
        self.assertRegex(output, r"extract\s+2")

        code, output = self.run_gwastoolkit("--cores", "2")
        self.assertEqual(code, 0, output)
        listed = [line.split()[0] for line in
                  (REPOSITORY / "tests" / "data" / "variantlist.txt").read_text().splitlines()]
        for phenotype in PHENOTYPES:
            rows = self.read_summary("variants", phenotype)
            # Exactly the six listed variants, from both chromosomes.
            self.assertEqual(sorted(row["variant_id"] for row in rows), sorted(listed))
        self.assert_top_hit_is_planted(self.read_summary("variants", "BMI"), "BMI")
        self.assert_top_hit_is_planted(self.read_summary("variants", "T2D"), "T2D")
        # One table with all phenotypes, as text and as Parquet.
        combined = self.read_summary("variants", "ALL_PHENOTYPES")
        self.assertEqual(len(combined), 18)
        self.assertEqual(sorted({row["phenotype"] for row in combined}), sorted(PHENOTYPES))
        self.assertEqual(pl.read_parquet(self.summary_path("variants", "ALL_PHENOTYPES", "parquet")).height, 18)
        self.assertTrue((self.output / "extract" / "variants" / "variants.chr21.vcf.gz").is_file())

    def test_region_mode(self):
        self.settings["analysis"]["mode"] = "REGION"
        code, output = self.run_gwastoolkit("--cores", "2")
        self.assertEqual(code, 0, output)
        target = "chr21_20185673_20285673"
        rows = self.read_summary(target, "BMI")
        self.assertGreater(len(rows), 20)
        self.assertTrue(all(row["chr"] == "21" and 20185673 <= int(row["pos"]) <= 20285673 for row in rows))
        self.assert_top_hit_is_planted(rows, "BMI")
        self.assertEqual(len(self.read_summary(target, "ALL_PHENOTYPES")), 3 * len(rows))

    def test_genes_mode(self):
        self.settings["analysis"]["mode"] = "GENES"
        code, output = self.run_gwastoolkit("--cores", "2")
        self.assertEqual(code, 0, output)
        # One target per gene: the gene plus 50 kb (targets.range) on either side.
        for gene, chromosome, phenotype in (("FAKEGENE1", "21", "BMI"), ("FAKEGENE2", "22", "T2D")):
            rows = self.read_summary(gene, phenotype)
            self.assertGreater(len(rows), 20)
            self.assertEqual({row["chr"] for row in rows}, {chromosome})
            planted_position = int(self.truth()[phenotype][1])
            self.assertTrue(all(abs(int(row["pos"]) - planted_position) <= 70000 for row in rows))
            self.assert_top_hit_is_planted(rows, phenotype)
            self.assertTrue(self.summary_path(gene, "ALL_PHENOTYPES", "parquet").is_file())

    def test_conditional_analysis_reads_the_whole_chromosome(self):
        # The variant to condition on may lie outside the targets, so nothing is extracted:
        # SNPTEST reads the dataset and is limited to the targets with -range.
        condition_file = self.root / "condition.txt"
        condition_file.write_text("chr21:20235673:G:T add\n")
        self.settings["analysis"].update(mode="GENES", condition=True, condition_file=str(condition_file))
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertEqual(code, 0, output)
        self.assertNotRegex(output, r"extract\s+\d")
        self.assertIn("-data tests/data/fake.chr21.vcf.gz", output)
        self.assertIn("-condition_on chr21:20235673:G:T add -range 20165673-20305673", output)

    # ------------------------------------------------------------- refusals
    def test_problems_are_reported_before_anything_runs(self):
        cases = []
        # A phenotype that is not in the sample file.
        phenotypes = self.root / "phenotypes.txt"
        phenotypes.write_text("BMI\nHEIGHT\n")
        cases.append(({"phenotype_file": str(phenotypes)}, "phenotype 'HEIGHT' is not a column"))
        # A baseline value that does not occur.
        cases.append(({"method": "newml", "baseline_phenotype": "control"}, "does not occur as a value"))
        # Method newml for continuous phenotypes.
        cases.append(({"method": "newml"}, "phenotype 'BMI' is continuous"))
        for changes, message in cases:
            settings = yaml.safe_load(yaml.safe_dump(self.settings))
            settings["analysis"].update(changes)
            self.settings, kept = settings, self.settings
            code, output = self.run_gwastoolkit("--dry-run")
            self.settings = kept
            self.assertNotEqual(code, 0)
            self.assertIn(message, output)

    def test_unknown_gene_is_refused(self):
        genes = self.root / "genes.txt"
        genes.write_text("FAKEGENE1\nNOSUCHGENE\n")
        self.settings["analysis"]["mode"] = "GENES"
        self.settings["targets"]["gene_file"] = str(genes)
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertNotEqual(code, 0)
        self.assertIn("gene NOSUCHGENE is not in the gene coordinates", output)

    def test_other_engines_are_refused(self):
        self.settings["analysis"]["engine"] = "plink2"
        code, output = self.run_gwastoolkit("--dry-run")
        self.assertNotEqual(code, 0)
        self.assertIn("not available yet", output)


if __name__ == "__main__":
    unittest.main()
