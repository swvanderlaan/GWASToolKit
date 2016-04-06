# GWASToolKit
This repository contains various scripts in Perl, BASH, and Python to use in genome-wide association studies, single variant analyses, regional analyses, and gene-centered analyses. 
Scripts will work within the context of a certain Linux environment (in this case that of the UMC Utrecht, Utrecht, the Netherlands). LocusZoom style figures, Manhattan plots, QQ-plots and other informative plots will be made depending on the type of analysis.

NOTE: THIS IS STILL WORK IN PROGRESS


# IMPUTE2DOSAGE
This Perl and BASH-script convert IMPUTE2 derived .gen-files to PLINK-style .dosage-files.

IMPUTE2 derived imputed genotype data (.gen-files) are genotype probabilities per genotype for each variant (AA, AB, BB). These scripts will convert these genotype probabilities to PLINK-style dosage data. The three genotype probabilities (AA, AB, BB) are converted to 1 dosage relative to the B-allele. The resulting files can than readily be used used for polygenic scores analyses or regular PLINK-style association analyses with the --dosage flag. Output will automatically be gzipped.

Files made are:

*.dose.gz -- the new DOSAGE file in PLINK style
*.map -- the new MAP file in PLINK style
*.fam -- the new FAM file in PLINK style
FURTHER NOTES: - A [.gen.gz] extension, i.e. a gzipped [.gen] file is expected. - The FAM file only contains the sample IDs and has PID, MID, Sex and Phenotype set to -9.
