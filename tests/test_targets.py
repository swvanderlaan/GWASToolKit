"""
Tests for the targets (gwastoolkit/targets.py) and for the checks on the
contents of the input files (check_inputs in gwastoolkit/config.py).

Run from the repository root with either of:
    python -m unittest discover -s tests -v
    pytest

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import logging
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

from gwastoolkit import find_variants, make_gene_list
from gwastoolkit.config import check_inputs, load_config
from gwastoolkit.targets import Target, TargetError, load_targets, merge_regions, read_variant_list

REPOSITORY = Path(__file__).resolve().parent.parent
TEST_CONFIG = REPOSITORY / "tests" / "data" / "config.test.yaml"
# bcftools is looked for next to the Python that runs the tests (the same environment), then on the PATH.
BCFTOOLS = shutil.which("bcftools", path=str(Path(sys.executable).parent)) or shutil.which("bcftools")


class TargetsTestCase(unittest.TestCase):
    def setUp(self):
        # The paths in the test configuration are relative to the repository root.
        previous = os.getcwd()
        os.chdir(REPOSITORY)
        self.addCleanup(os.chdir, previous)
        self.config = load_config(TEST_CONFIG)
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def write(self, name, text) -> str:
        path = self.root / name
        path.write_text(text, encoding="utf-8")
        return str(path)


class TestTargets(TargetsTestCase):
    def test_merge_regions(self):
        self.assertEqual(merge_regions([(50, 60), (1, 10), (5, 20), (21, 30), (100, 100)]),
                         [(1, 30), (50, 60), (100, 100)])

    def test_target_formats(self):
        target = Target("x", "21", [(100, 200), (500, 900)])
        self.assertEqual(target.ranges, ["100-200", "500-900"])
        self.assertEqual(target.regions_text("chr"), "chr21\t100\t200\nchr21\t500\t900\n")
        self.assertEqual(target.regions_text(""), "21\t100\t200\n21\t500\t900\n")

    def test_gwas(self):
        targets = load_targets(self.config)
        self.assertEqual([(t.name, t.chromosome, t.regions) for t in targets], [("gwas", "21", []), ("gwas", "22", [])])

    def test_variant(self):
        self.config.analysis.mode = "VARIANT"
        targets = load_targets(self.config)
        self.assertEqual([(t.name, t.chromosome, len(t.regions)) for t in targets],
                         [("variants", "21", 3), ("variants", "22", 3)])
        # One base pair per variant.
        self.assertTrue(all(start == end for target in targets for start, end in target.regions))

    def test_variant_list_layouts(self):
        plain = self.write("plain.txt", "rs1 1 100\n# a comment\n\nrs2 chr2 200\n")
        self.assertEqual(read_variant_list(plain), [("1", 100), ("2", 200)])
        # With a header: columns are found by name (as in EXAMPLE/example.variantlist.txt).
        header = self.write("header.txt", "RSID\tVariantID\tChr\tBP\tREF\tALT\nrs1\tchr1:100:A:G\tchr1\t100\tA\tG\n")
        self.assertEqual(read_variant_list(header), [("1", 100)])
        for name in ("example.variantlist.txt", "example.variantlist.b37.txt"):
            self.assertGreaterEqual(len(read_variant_list(REPOSITORY / "EXAMPLE" / name)), 4)
        with self.assertRaises(TargetError):
            read_variant_list(self.write("bad.txt", "rs1 1 notanumber\n"))
        with self.assertRaises(TargetError):
            read_variant_list(self.write("empty.txt", "\n"))

    def test_region(self):
        self.config.analysis.mode = "REGION"
        (target,) = load_targets(self.config)
        self.assertEqual((target.name, target.chromosome, target.regions),
                         ("chr21_20185673_20285673", "21", [(20185673, 20285673)]))

    def test_genes(self):
        self.config.analysis.mode = "GENES"
        first, second = load_targets(self.config)
        # The gene (20215673-20255673) plus targets.range (50,000) on either side.
        self.assertEqual((first.name, first.chromosome, first.regions), ("FAKEGENE1", "21", [(20165673, 20305673)]))
        self.assertEqual((second.name, second.chromosome), ("FAKEGENE2", "22"))

    def test_unknown_gene(self):
        self.config.analysis.mode = "GENES"
        self.config.targets.gene_file = self.write("genes.txt", "FAKEGENE1\nNOSUCHGENE\n")
        with self.assertRaises(TargetError) as caught:
            load_targets(self.config)
        self.assertIn("gene NOSUCHGENE is not in the gene coordinates", str(caught.exception))

    def test_no_gene_coordinates(self):
        self.config.analysis.mode = "GENES"
        self.config.references["b38"].genes = ""
        with self.assertRaises(TargetError) as caught:
            load_targets(self.config)
        self.assertIn("references.b38.genes is empty", str(caught.exception))

    def test_gene_coordinates_file_missing(self):
        self.config.analysis.mode = "GENES"
        self.config.references["b38"].genes = "RESOURCES/no_such_file.txt.gz"
        with self.assertRaises(TargetError) as caught:
            load_targets(self.config)
        self.assertIn("gwastoolkit make-gene-list", str(caught.exception))

    def test_chromosome_without_data(self):
        self.config.analysis.mode = "VARIANT"
        self.config.targets.variant_file = self.write("variants.txt", "rs1 1 100\nrs2 X 500\n")
        with self.assertRaises(TargetError) as caught:
            load_targets(self.config)
        message = str(caught.exception)
        self.assertIn("chromosome 1 is not in dataset fake_b38", message)
        self.assertIn("chromosome X is not in dataset fake_b38", message)


class TestCheckInputs(TargetsTestCase):
    def test_test_configuration_is_fine(self):
        self.assertEqual(check_inputs(self.config), [])

    def test_names_must_be_in_the_sample_file(self):
        analysis = self.config.analysis
        analysis.phenotype_file = self.write("phenotypes.txt", "BMI\nHEIGHT\nAge\n")
        analysis.covariate_file = self.write("covariates.txt", "Age SEX PC9\n")
        analysis.exclusion_column = "CHOSEN"
        problems = "\n".join(check_inputs(self.config))
        self.assertIn("phenotype 'HEIGHT' is not a column", problems)
        self.assertIn("phenotype 'Age' has type C", problems)
        self.assertIn("covariate 'PC9' is not a column", problems)
        self.assertIn("'CHOSEN' is not a column", problems)

    def test_baseline_phenotype_must_occur(self):
        analysis = self.config.analysis
        analysis.phenotype_file = self.write("phenotypes.txt", "T2D\n")
        analysis.method, analysis.baseline_phenotype = "newml", "control"
        self.assertIn("'control' does not occur as a value of phenotype 'T2D'", "\n".join(check_inputs(self.config)))
        analysis.baseline_phenotype = "0"
        self.assertEqual(check_inputs(self.config), [])

    def test_newml_refuses_continuous_phenotypes(self):
        analysis = self.config.analysis
        analysis.method = "newml"
        problems = "\n".join(check_inputs(self.config))
        self.assertIn("phenotype 'BMI' is continuous (type P); method 'newml' only analyses", problems)
        self.assertIn("phenotype 'NULLQT' is continuous", problems)
        self.assertNotIn("T2D", problems)
        # With "auto" the method follows the phenotype, so there is nothing to report.
        analysis.method, analysis.mode = "auto", "VARIANT"
        self.assertEqual(check_inputs(self.config), [])

    def test_condition_file(self):
        analysis = self.config.analysis
        analysis.condition = True
        for text, valid in (("rs1 add rs2 dom\n", True), ("rs1 rs2\n", True), ("", False),
                            ("add rs1\n", False), ("rs1 add dom\n", False)):
            analysis.condition_file = self.write("condition.txt", text)
            self.assertEqual(check_inputs(self.config) == [], valid, repr(text))


# A few lines in the layout of a GENCODE annotation file (GTF).
GTF = """##description: a small example in GENCODE layout
chr2\tHAVANA\tgene\t500\t900\t.\t-\t.\tgene_id "ENSG02.1"; gene_type "lncRNA"; gene_name "LNC2"; level 2;
chr1\tHAVANA\tgene\t1000\t5000\t.\t+\t.\tgene_id "ENSG01.5"; gene_type "protein_coding"; gene_name "GENEA"; level 2;
chr1\tHAVANA\ttranscript\t1000\t4000\t.\t+\t.\tgene_id "ENSG01.5"; transcript_id "ENST01.1"; gene_name "GENEA";
chr1\tHAVANA\texon\t1000\t1200\t.\t+\t.\tgene_id "ENSG01.5"; gene_name "GENEA";
chrX\tHAVANA\tgene\t300\t700\t.\t+\t.\tgene_id "ENSG03.2"; gene_type "protein_coding"; gene_name "GENEX";
chrY\tHAVANA\tgene\t300\t700\t.\t+\t.\tgene_id "ENSG04.2"; gene_type "protein_coding"; gene_name "GENEY";
chrM\tENSEMBL\tgene\t10\t90\t.\t+\t.\tgene_id "ENSG05.1"; gene_type "Mt_tRNA"; gene_name "MT-TF";
chr1\tHAVANA\tgene\t200\t300\t.\t+\t.\tgene_id "ENSG06.1"; gene_type "pseudogene";
"""


class TestMakeGeneList(TargetsTestCase):
    def setUp(self):
        super().setUp()
        logging.disable(logging.CRITICAL)  # keep the test output clean
        self.addCleanup(logging.disable, logging.NOTSET)
        self.gtf = Path(self.write("example.v1.annotation.gtf", GTF))

    def test_read_genes(self):
        genes = make_gene_list.read_genes(self.gtf)
        # Only 'gene' lines; chromosomes 1-22 and X; sorted; a gene without a name gets its identifier.
        self.assertEqual(genes, [
            ("1", 200, 300, "ENSG06.1", "ENSG06.1", "pseudogene"),
            ("1", 1000, 5000, "GENEA", "ENSG01.5", "protein_coding"),
            ("2", 500, 900, "LNC2", "ENSG02.1", "lncRNA"),
            ("X", 300, 700, "GENEX", "ENSG03.2", "protein_coding"),
        ])
        coding = make_gene_list.read_genes(self.gtf, ["protein_coding"])
        self.assertEqual([gene[3] for gene in coding], ["GENEA", "GENEX"])
        with self.assertRaises(make_gene_list.GeneListError):
            make_gene_list.read_genes(Path(self.write("empty.gtf", "# nothing\n")))

    def test_command_line_with_a_local_file(self):
        output = self.root / "resources"
        arguments = ["--gtf", str(self.gtf), "--output", str(output)]
        # Which build is the file? That must be said.
        self.assertEqual(make_gene_list.main(arguments), 1)
        self.assertEqual(make_gene_list.main(arguments + ["--build", "b38"]), 0)
        gene_list = output / "genes.example.v1.annotation.b38.txt.gz"
        first = gene_list.read_bytes()
        info = (output / "genes.example.v1.annotation.b38.info.txt").read_text()
        self.assertIn("genes            : 4 (2 protein coding)", info)
        self.assertIn("given with --gtf", info)
        # Making it again gives a byte-for-byte identical file.
        self.assertEqual(make_gene_list.main(arguments + ["--build", "b38"]), 0)
        self.assertEqual(gene_list.read_bytes(), first)

        # A filtered list gets the filter in its name, and does not replace the full list.
        self.assertEqual(make_gene_list.main(arguments + ["--build", "b38", "--gene-types", "protein_coding"]), 0)
        filtered = output / "genes.example.v1.annotation.protein_coding.b38.txt.gz"
        self.assertEqual(gzip.decompress(filtered.read_bytes()).decode().count("\n"), 2)
        self.assertEqual(gene_list.read_bytes(), first)
        self.assertIn("gene types kept  : protein_coding",
                      (output / "genes.example.v1.annotation.protein_coding.b38.info.txt").read_text())

        # The list is what mode GENES reads.
        self.config.analysis.mode = "GENES"
        self.config.references["b38"].genes = str(gene_list)
        self.config.active_dataset.chromosomes = ["1", "2"]
        self.config.targets.gene_file = self.write("genes.txt", "GENEA\n")
        self.config.targets.range = 100
        (target,) = load_targets(self.config)
        self.assertEqual((target.name, target.chromosome, target.regions), ("GENEA", "1", [(900, 5100)]))

    def test_sources(self):
        self.assertEqual(make_gene_list.source("b38", "47"), (
            "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47",
            "gencode.v47.annotation.gtf.gz"))
        self.assertEqual(make_gene_list.source("b37", "47"), (
            "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh37_mapping",
            "gencode.v47lift37.annotation.gtf.gz"))
        self.assertEqual(make_gene_list.list_name("b38", "47", ["protein_coding", "lncRNA"]),
                         "genes.gencode_v47.lncRNA+protein_coding.b38.txt.gz")
        # The names the example configuration points to.
        with open(REPOSITORY / "config" / "config.yaml") as handle:
            example = handle.read()
        for build in ("b37", "b38"):
            self.assertIn("RESOURCES/" + make_gene_list.list_name(build, make_gene_list.DEFAULT_RELEASE), example)


@unittest.skipUnless(BCFTOOLS, "bcftools is not installed")
class TestFindVariants(TargetsTestCase):
    def setUp(self):
        super().setUp()
        self.config.site.bcftools = BCFTOOLS
        logging.disable(logging.CRITICAL)  # keep the test output clean
        self.addCleanup(logging.disable, logging.NOTSET)

    def test_found_and_not_found(self):
        found = find_variants.find_variants(
            self.config, ["chr21:20235673:G:T", "chr22:30222157:C:T", "chr21:20235673:A:C", "rs999", "chr5:100:A:G"]
        )
        # Present, under exactly this identifier.
        self.assertEqual(found["chr21:20235673:G:T"], [["chr21", "20235673", "chr21:20235673:G:T", "G", "T"]])
        self.assertEqual(len(found["chr22:30222157:C:T"]), 1)
        # Right position but other alleles, an unknown rsID, a chromosome without data: not found.
        self.assertEqual((found["chr21:20235673:A:C"], found["rs999"], found["chr5:100:A:G"]), ([], [], []))

    def test_command_line(self):
        condition = self.write("condition.txt", "chr21:20235673:G:T add chr22:30222157:C:T dom\n")
        output = self.root / "found.tsv"
        arguments = ["--config", str(TEST_CONFIG), "--file", condition, "--output", str(output)]
        self.assertEqual(find_variants.main(arguments), 0)
        lines = output.read_text().splitlines()
        self.assertEqual(lines[0], "variant\tstatus\tchr\tpos\tref\talt")
        self.assertEqual(len(lines), 3)  # the model words (add, dom) are not looked for
        # A variant that is not there gives exit code 1.
        self.assertEqual(find_variants.main(["--config", str(TEST_CONFIG), "--variants", "rs999"]), 1)
        self.assertEqual(find_variants.main(["--config", str(TEST_CONFIG)]), 1)  # nothing to look for
        self.assertEqual(find_variants.main(arguments + ["--dataset", "nonsense"]), 1)


if __name__ == "__main__":
    unittest.main()
