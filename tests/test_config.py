"""
Tests for the configuration schema (gwastoolkit/config.py) and the command-line interface.

Run from the repository root with either of:
    python -m unittest discover -s tests -v
    pytest

The MIT License (MIT)
Copyright (c) 2010-2026 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com
See the LICENSE file in the repository for the full license text.
"""

import contextlib
import copy
import io
import tempfile
import unittest
from pathlib import Path

import yaml

from gwastoolkit.cli import main
from gwastoolkit.config import ConfigError, check_files, collect_warnings, load_config

REPOSITORY = Path(__file__).resolve().parent.parent
EXAMPLE_CONFIG = REPOSITORY / "config" / "config.yaml"


class ConfigTestCase(unittest.TestCase):
    """Base class: gives each test the example configuration to change and reload."""

    def setUp(self):
        with open(EXAMPLE_CONFIG, "r", encoding="utf-8") as handle:
            self.settings = yaml.safe_load(handle)
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)

    def write(self, settings) -> Path:
        """Write settings to a temporary configuration file and return its path."""
        path = Path(self.directory.name) / "config.yaml"
        with open(path, "w", encoding="utf-8") as handle:
            yaml.safe_dump(settings, handle)
        return path

    def load(self, settings):
        return load_config(self.write(settings))

    def errors(self, settings) -> str:
        """Load settings that should be invalid; return the error messages as one text."""
        with self.assertRaises(ConfigError) as caught:
            self.load(settings)
        return "\n".join(caught.exception.messages)


class TestExampleConfig(ConfigTestCase):
    def test_example_config_is_valid(self):
        config = load_config(EXAMPLE_CONFIG)
        self.assertEqual(config.analysis.dataset, "aegs_topmed_r3_b38_eur_nl")
        self.assertEqual(config.active_dataset.build, "b38")
        self.assertEqual(config.active_dataset.n_samples, 1989)
        self.assertEqual(len(config.datasets), 12)

    def test_every_dataset_can_be_chosen(self):
        for name in self.settings["datasets"]:
            settings = copy.deepcopy(self.settings)
            settings["analysis"]["dataset"] = name
            # AAAGS and CTMMGS have a default sample file; AEGS uses the one given.
            config = self.load(settings)
            self.assertTrue(config.sample_file, name)
            self.assertIn(config.active_dataset.build, config.references, name)

    def test_study_default_sample_file_is_used(self):
        self.settings["analysis"]["dataset"] = "aaags_1kgp3_b37"
        self.settings["analysis"]["sample_file"] = ""
        config = self.load(self.settings)
        self.assertTrue(config.sample_file.endswith("aaags_phenocov.sample"))

    def test_path_for_chromosome(self):
        config = load_config(EXAMPLE_CONFIG)
        self.assertTrue(config.active_dataset.path_for(7).endswith(".eur_nl.chr7.vcf.gz"))
        with self.assertRaises(ValueError):
            config.active_dataset.path_for("X")  # the default dataset has no chromosome X
        b37 = config.datasets["aegs_1kgp3_hrc_r11_b37"]
        self.assertTrue(b37.path_for("X").endswith("chrX.vcf.gz"))

    def test_references_follow_the_build(self):
        self.settings["analysis"]["dataset"] = "aegs_1kgp3_hrc_r11_b37"
        config = self.load(self.settings)
        self.assertEqual(config.active_references.genes, "RESOURCES/genes.gencode_v47lift37.b37.txt.gz")
        self.assertTrue(config.reference_path(config.active_references.genes).startswith("/"))

    def test_method_auto_follows_mode_and_phenotype_type(self):
        self.assertEqual(self.settings["analysis"]["method"], "auto")
        # The fake sample file: BMI and NULLQT are continuous (P), T2D is binary (B).
        self.settings["analysis"]["sample_file"] = str(REPOSITORY / "tests" / "data" / "fake.sample")
        self.settings["analysis"]["mode"] = "GWAS"
        config = self.load(self.settings)
        self.assertEqual([config.method_for(name) for name in ("BMI", "T2D")], ["expected", "expected"])
        for mode in ("VARIANT", "REGION", "GENES"):
            self.settings["analysis"]["mode"] = mode
            config = self.load(self.settings)
            # newml cannot analyse a continuous phenotype.
            self.assertEqual([config.method_for(name) for name in ("BMI", "T2D", "NULLQT")],
                             ["expected", "newml", "expected"], mode)
        # A method that is given is used whatever the mode and phenotype.
        self.settings["analysis"]["method"] = "score"
        self.assertEqual(self.load(self.settings).method_for("T2D"), "score")
        # Without a readable sample file the type is unknown: expected.
        self.settings["analysis"].update(method="auto", sample_file="/no/such/file.sample")
        self.assertEqual(self.load(self.settings).method_for("T2D"), "expected")

    def test_slurm_mail_options(self):
        self.settings["slurm"] = {"email": "me@example.org", "mail_type": "end, fail"}
        config = self.load(self.settings)
        self.assertEqual(config.slurm.sbatch_options, "--mail-user=me@example.org --mail-type=END,FAIL")
        self.settings["slurm"] = {"email": "", "mail_type": "NONE"}
        self.assertEqual(self.load(self.settings).slurm.sbatch_options, "")

    def test_warnings_for_missing_b38_references(self):
        warnings = "\n".join(collect_warnings(load_config(EXAMPLE_CONFIG)))
        self.assertIn("references.b38.ld_reference", warnings)
        self.assertIn("placeholder", warnings)


class TestInvalidConfigs(ConfigTestCase):
    def test_unknown_dataset_gives_a_suggestion(self):
        self.settings["analysis"]["dataset"] = "aegs_topmed_r3_b38_eurnl"
        message = self.errors(self.settings)
        self.assertIn("is not listed under `datasets`", message)
        self.assertIn("aegs_topmed_r3_b38_eur_nl", message)

    def test_misspelled_setting_is_rejected(self):
        self.settings["qc"]["min_infoo"] = 0.5
        self.assertIn("qc.min_infoo: unknown setting", self.errors(self.settings))

    def test_wrong_mode_is_rejected(self):
        self.settings["analysis"]["mode"] = "GENE"
        self.assertIn("analysis.mode", self.errors(self.settings))

    def test_regenie_is_gwas_only(self):
        self.settings["analysis"]["engine"] = "regenie"
        self.settings["analysis"]["mode"] = "VARIANT"
        self.assertIn("only available for mode GWAS", self.errors(self.settings))

    def test_condition_needs_a_file(self):
        self.settings["analysis"]["condition"] = True
        self.assertIn("analysis.condition_file", self.errors(self.settings))

    def test_baseline_phenotype_is_for_newml_only(self):
        self.settings["analysis"]["baseline_phenotype"] = "control"  # mode GWAS: method expected
        self.assertIn("analysis.baseline_phenotype", self.errors(self.settings))
        self.settings["analysis"]["method"] = "newml"
        self.assertEqual(self.load(self.settings).method_for("T2D"), "newml")
        # With "auto", newml is used in the targeted modes, so a baseline is accepted there.
        self.settings["analysis"].update(method="auto", mode="VARIANT")
        self.load(self.settings)

    def test_mail_settings(self):
        self.settings["slurm"] = {"email": "not-an-address", "mail_type": "FAIL"}
        self.assertIn("slurm.email", self.errors(self.settings))
        self.settings["slurm"] = {"email": "me@example.org", "mail_type": "SOMETIMES"}
        self.assertIn("slurm.mail_type", self.errors(self.settings))
        self.settings["slurm"] = {"email": "me@example.org", "mail_type": "NONE,FAIL"}
        self.assertIn("NONE cannot be combined", self.errors(self.settings))

    def test_mode_needs_its_targets(self):
        self.settings["analysis"]["mode"] = "GENES"
        self.settings["targets"]["gene_file"] = ""
        self.assertIn("targets.gene_file", self.errors(self.settings))

    def test_region_start_before_end(self):
        self.settings["targets"]["region"] = {"chr": "chr1", "start": 200, "end": 100}
        self.assertIn("start must be smaller than end", self.errors(self.settings))

    def test_dataset_path_needs_chr_placeholder(self):
        dataset = self.settings["datasets"]["aegs_topmed_r3_b38_eur_nl"]
        dataset["path"] = "/data/aegs.chr1.vcf.gz"
        message = self.errors(self.settings)
        self.assertIn("datasets.aegs_topmed_r3_b38_eur_nl", message)
        self.assertIn("{chr}", message)

    def test_dataset_path_must_match_format(self):
        self.settings["datasets"]["aegs_topmed_r3_b38_eur_nl"]["format"] = "bgen"
        self.assertIn("does not end in '.bgen'", self.errors(self.settings))

    def test_dataset_with_unknown_study(self):
        self.settings["datasets"]["aegs_topmed_r3_b38_eur_nl"]["study"] = "AEGSS"
        self.assertIn("is not listed under `studies`", self.errors(self.settings))

    def test_missing_sample_file(self):
        self.settings["analysis"]["sample_file"] = ""  # AEGS has no default sample file
        self.assertIn("analysis.sample_file", self.errors(self.settings))

    def test_all_problems_are_reported_at_once(self):
        self.settings["analysis"]["condition"] = True
        self.settings["analysis"]["mode"] = "GENES"
        self.settings["targets"]["gene_file"] = ""
        message = self.errors(self.settings)
        self.assertIn("analysis.condition_file", message)
        self.assertIn("targets.gene_file", message)

    def test_missing_or_broken_file(self):
        with self.assertRaises(ConfigError):
            load_config(Path(self.directory.name) / "does_not_exist.yaml")
        broken = Path(self.directory.name) / "broken.yaml"
        broken.write_text("site: [unclosed\n", encoding="utf-8")
        with self.assertRaises(ConfigError):
            load_config(broken)


class TestFileChecks(ConfigTestCase):
    def test_missing_files_are_reported(self):
        # Point to paths that exist nowhere, so the test gives the same result on any machine
        # (on the cluster the paths of the example configuration do exist).
        self.settings["project"]["dir"] = "/no/such/directory"
        self.settings["analysis"]["sample_file"] = "/no/such/directory/samples.sample"
        self.settings["datasets"]["aegs_topmed_r3_b38_eur_nl"]["path"] = "/no/such/directory/data.chr{chr}.vcf.gz"
        problems = "\n".join(check_files(self.load(self.settings)))
        self.assertIn("project.dir: directory not found", problems)
        self.assertIn("sample file: file not found", problems)
        self.assertIn("chromosome 22", problems)

    def test_existing_files_pass(self):
        # Build a small set of (empty) files so that every check passes.
        root = Path(self.directory.name)
        for name in ("software", "toolkit", "harmonia", "project", "data"):
            (root / name).mkdir()
        for name in ("snptest", "samples.sample", "phenotypes.txt", "covariates.txt"):
            (root / name).touch()
        for chromosome in range(1, 23):
            (root / "data" / f"test.chr{chromosome}.vcf.gz").touch()

        settings = self.settings
        settings["site"].update(gwastoolkit=str(root / "toolkit"), harmonia=str(root / "harmonia"),
                                snptest=str(root / "snptest"))
        settings["project"]["dir"] = str(root / "project")
        settings["analysis"].update(sample_file=str(root / "samples.sample"),
                                    phenotype_file=str(root / "phenotypes.txt"),
                                    covariate_file=str(root / "covariates.txt"))
        settings["datasets"]["aegs_topmed_r3_b38_eur_nl"]["path"] = str(root / "data" / "test.chr{chr}.vcf.gz")
        self.assertEqual(check_files(self.load(settings)), [])


class TestCommandLine(ConfigTestCase):
    def run_cli(self, *arguments):
        """Run the command-line interface; return (exit code, what it printed)."""
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            try:
                code = main(list(arguments))
            except SystemExit as stop:  # argparse exits after --help and --version
                code = stop.code
        return code, output.getvalue()

    def test_help(self):
        for arguments in (["--help"], ["validate", "--help"], ["datasets", "--help"], ["show", "--help"]):
            code, output = self.run_cli(*arguments)
            self.assertEqual(code, 0, arguments)
            self.assertIn("usage: gwastoolkit", output)

    def test_no_command_prints_help(self):
        code, output = self.run_cli()
        self.assertEqual(code, 1)
        self.assertIn("usage: gwastoolkit", output)

    def test_datasets(self):
        code, output = self.run_cli("datasets")
        self.assertEqual(code, 0)
        self.assertEqual(sum(line.startswith(("*", " ")) and "b3" in line for line in output.splitlines()), 12)
        self.assertRegex(output, r"\*\s+aegs_topmed_r3_b38_eur_nl")

    def test_datasets_filter(self):
        code, output = self.run_cli("datasets", "--study", "ctmmgs", "--build", "b37")
        self.assertEqual(code, 0)
        self.assertIn("ctmmgs_hrc_r11_b37", output)
        self.assertNotIn("aegs_", output)

    def test_validate_writes_a_log(self):
        path = self.write(self.settings)
        code, output = self.run_cli("validate", "--config", str(path))
        self.assertEqual(code, 0)
        self.assertIn("The configuration file is valid", output)
        logs = list(path.parent.glob("*_config.gwastoolkit.log"))
        self.assertEqual(len(logs), 1)
        self.assertIn("The configuration file is valid", logs[0].read_text(encoding="utf-8"))

    def test_validate_no_log(self):
        path = self.write(self.settings)
        code, _ = self.run_cli("validate", "--config", str(path), "--no-log")
        self.assertEqual(code, 0)
        self.assertEqual(list(path.parent.glob("*.log")), [])

    def test_validate_invalid_config(self):
        self.settings["analysis"]["dataset"] = "nonsense"
        code, output = self.run_cli("validate", "--config", str(self.write(self.settings)), "--no-log")
        self.assertEqual(code, 1)
        self.assertIn("NOT valid", output)

    def test_validate_check_files_fails_off_cluster(self):
        self.settings["project"]["dir"] = "/no/such/directory"
        path = self.write(self.settings)
        code, output = self.run_cli("validate", "--config", str(path), "--check-files", "--no-log")
        self.assertEqual(code, 1)
        self.assertIn("were not found", output)

    def test_show(self):
        code, output = self.run_cli("show")
        self.assertEqual(code, 0)
        self.assertIn("aegs_topmed_r3_b38_eur_nl", output)
        self.assertIn("chr1.vcf.gz", output)


if __name__ == "__main__":
    unittest.main()
