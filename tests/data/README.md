# Fake test dataset

Everything in this directory is **simulated**. No sample, genotype, position, gene or phenotype
comes from real people or real studies. The dataset exists so that GWASToolKit can be tested
anywhere, and it is small enough (about 0.2 Mb) to keep in the repository.

It was made with [make_test_data.py](make_test_data.py), which needs only Python (no extra
packages). The same seed always gives exactly the same files:

```
python tests/data/make_test_data.py
```

## Contents

| File | What it is |
|---|---|
| `fake.chr21.vcf.gz`, `fake.chr22.vcf.gz` | "Imputed" genotypes for 500 samples and 296 variants per chromosome, in the layout of the TOPMed/Michigan imputation servers: `GT:DS:GP` per sample; `AF`, `MAF`, `R2`, `TYPED`/`IMPUTED` per variant. Chromosomes are named `chr21` and `chr22`; variant IDs are `chr:pos:ref:alt`. BGZF-compressed, so they can be indexed with `tabix`. |
| `fake.sample` | SNPTEST sample file: covariates `Age`, `SEX`, `PC1`–`PC4`; the `SELECTION` column (12 samples are `not_selected`); phenotypes `BMI`, `T2D` and `NULLQT`, each with a few missing values. |
| `phenotypes.txt`, `covariates.txt` | The phenotype and covariate lists. |
| `variantlist.txt` | Six variants for the `VARIANT` mode, including the two with a planted effect. |
| `genelist.txt`, `genes.fake_b38.txt.gz` | Two fake genes (`FAKEGENE1`, `FAKEGENE2`) for the `GENES` mode, and their coordinates. |
| `truth.txt` | The planted effects. |
| `config.test.yaml` | A GWASToolKit configuration that points to these files. |

## What an analysis should find

| Phenotype | Type | Planted effect |
|---|---|---|
| `BMI` | quantitative | `chr21:20235673:G:T`, +2.0 units per `T` allele (in `FAKEGENE1`) |
| `T2D` | binary | `chr22:30222157:C:T`, log odds +1.0 per `T` allele (in `FAKEGENE2`) |
| `NULLQT` | quantitative | none |

Both planted variants are common and well imputed, and are the strongest signal for their
phenotype. Because neighbouring common variants are correlated (LD), nearby variants show a weaker
signal too, which is what clumping and regional plots need. About half of the variants are rare
(MAF < 5%) and some have a low imputation quality (R2 < 0.3), so the QC filters have something to remove.

## Limitations

- Two short stretches of two chromosomes: enough to test every step, not to judge performance.
- No chromosome X.
- The files are named `chr21` and `chr22`; a workflow run on this dataset must be limited to those
  two chromosomes.
