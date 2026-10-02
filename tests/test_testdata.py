"""
Tests for the fake test dataset in tests/data and its configuration file.

Run from the repository root with either of:
    python -m unittest discover -s tests -v
    pytest

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import gzip
import hashlib
import importlib.util
import os
import tempfile
import unittest
from pathlib import Path

from gwastoolkit.config import load_config

REPOSITORY = Path(__file__).resolve().parent.parent
DATA = REPOSITORY / "tests" / "data"
TEST_CONFIG = DATA / "config.test.yaml"
CHROMOSOMES = ("21", "22")


def read_vcf(path):
    """Return (sample IDs, list of data lines split on tabs) of a VCF file."""
    samples, records = [], []
    with gzip.open(path, "rt", encoding="ascii") as handle:
        for line in handle:
            if line.startswith("##"):
                continue
            fields = line.rstrip("\n").split("\t")
            if line.startswith("#CHROM"):
                samples = fields[9:]
            else:
                records.append(fields)
    return samples, records


class TestFakeDataset(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # The paths in the test configuration are relative to the repository root.
        cls.previous_directory = os.getcwd()
        os.chdir(REPOSITORY)
        cls.config = load_config(TEST_CONFIG)

    @classmethod
    def tearDownClass(cls):
        os.chdir(cls.previous_directory)

    def test_config_is_valid_and_files_exist(self):
        config = self.config
        self.assertEqual(config.analysis.dataset, "fake_b38")
        self.assertTrue(Path(config.sample_file).is_file())
        self.assertTrue(Path(config.analysis.phenotype_file).is_file())
        self.assertTrue(Path(config.analysis.covariate_file).is_file())
        self.assertTrue(Path(config.targets.variant_file).is_file())
        self.assertTrue(Path(config.targets.gene_file).is_file())
        self.assertTrue(Path(config.active_references.genes).is_file())
        for chromosome in CHROMOSOMES:
            self.assertTrue(Path(config.active_dataset.path_for(chromosome)).is_file())

    def test_vcf_and_sample_file_agree(self):
        sample_lines = Path(self.config.sample_file).read_text(encoding="ascii").splitlines()
        header, types, rows = sample_lines[0].split(), sample_lines[1].split(), sample_lines[2:]
        self.assertEqual(len(header), len(types))
        sample_ids = [row.split()[0] for row in rows]
        self.assertEqual(len(sample_ids), self.config.active_dataset.n_samples)
        for chromosome in CHROMOSOMES:
            vcf_samples, records = read_vcf(self.config.active_dataset.path_for(chromosome))
            self.assertEqual(vcf_samples, sample_ids)
            self.assertGreater(len(records), 250)
            for fields in records:
                self.assertEqual(fields[0], f"chr{chromosome}")
                self.assertEqual(fields[2], f"{fields[0]}:{fields[1]}:{fields[3]}:{fields[4]}")
                self.assertEqual(fields[8], "GT:DS:GP")
                self.assertEqual(len(fields), 9 + len(sample_ids))

    def test_phenotypes_and_covariates_are_in_the_sample_file(self):
        header = Path(self.config.sample_file).read_text(encoding="ascii").splitlines()[0].split()
        phenotypes = Path(self.config.analysis.phenotype_file).read_text(encoding="ascii").split()
        covariates = Path(self.config.analysis.covariate_file).read_text(encoding="ascii").split()
        for name in phenotypes + covariates + [self.config.analysis.exclusion_column]:
            self.assertIn(name, header)

    def test_targets_are_in_the_data(self):
        variant_ids = set()
        for chromosome in CHROMOSOMES:
            variant_ids.update(fields[2] for fields in read_vcf(self.config.active_dataset.path_for(chromosome))[1])
        listed = [line.split()[0] for line in Path(self.config.targets.variant_file).read_text().splitlines()]
        self.assertEqual(len(listed), 6)
        self.assertTrue(set(listed) <= variant_ids)
        # The planted variants are in the variant list.
        truth = [line.split("\t") for line in (DATA / "truth.txt").read_text().splitlines()[1:]]
        for row in truth:
            if row[1] != "none":
                self.assertIn(row[1], listed)
        # The genes in the gene list have coordinates.
        with gzip.open(self.config.active_references.genes, "rt") as handle:
            known_genes = {line.split()[3] for line in handle}
        genes = Path(self.config.targets.gene_file).read_text().split()
        self.assertTrue(set(genes) <= known_genes)

    def test_generator_reproduces_the_files(self):
        """Running the generator again must give exactly the files in the repository."""
        spec = importlib.util.spec_from_file_location("make_test_data", DATA / "make_test_data.py")
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        with tempfile.TemporaryDirectory() as directory:
            generator.logger.disabled = True
            self.assertEqual(generator.main(["--output", directory]), 0)
            for name in ("fake.chr21.vcf.gz", "fake.chr22.vcf.gz", "fake.sample", "variantlist.txt",
                         "genelist.txt", "genes.fake_b38.txt.gz", "truth.txt", "phenotypes.txt", "covariates.txt"):
                new, old = (Path(directory) / name).read_bytes(), (DATA / name).read_bytes()
                if name.endswith(".gz"):
                    # Compare the contents: the compressed bytes may differ between zlib versions.
                    new, old = gzip.decompress(new), gzip.decompress(old)
                self.assertEqual(hashlib.sha256(new).hexdigest(), hashlib.sha256(old).hexdigest(), name)


if __name__ == "__main__":
    unittest.main()
