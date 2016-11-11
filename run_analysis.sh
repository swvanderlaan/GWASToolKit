#!/bin/bash

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                              RUN_ANALYSES.v1.2.2"
echo "          INDIVIDUAL VARIANT, PER-GENE, REGIONAL OR GENOME-WIDE ASSOCIATION STUDY ON A PHENOTYPE"
echo ""
echo " You're here: "$(pwd)
echo " Today's: "$(date)
echo ""
echo " Version: RUN_ANALYSES.v1.2.5"
echo ""
echo " Last update: 2016-11-11"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echo "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echo "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echo ""
echo " Description: Perform individual variant, regional or genome-wide association "
echo "              analysis on some phenotype(s). It will do the following:"
echo "              - Run GWAS using SNPTESTv2.5.2 and 1000G (phase 1), GoNL4, or "
echo "                1000G (phase 3) + GoNL5 data per chromosome."
echo "              - Collect results in one file upon completion of jobs."
echo "              - Produce plots (PDF and PNG) for quick inspection and publication."
echo "              - Lookup individual variant results in AEGS plaque phenotype GWAS."
echo "              - Lookup gene results in AEGS plaque phenotype VEGAS results."
echo "              - Lookup gene results in public GWAS VEGAS results."
echo "              - Produce a ReadMe file."
echo ""
echo " REQUIRED: "
echo " * A high-performance computer cluster with a qsub system."
echo " * Imputed genotype data with 1000G[p1/p3]/GoNL[4/5] as reference."
echo " * SNPTEST v2.5+"
echo " * R v3.2+"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### SET SOME VARIABLES
### This part will determine what lines below will be run.

### FOR ANY TYPE OF ANALYSIS
### - Argument #1  indicates whether you want to analyse a list of variants, a region, or do a GWAS [VARIANT/REGION/GWAS].
###                Depending on the choice you additional arguments are expected:
###                - for GWAS: no additional arguments, except the standard 12 arguments in total.
###                - for VARIANT: 2 additional argument, namely a [FILE] containing the list of variants and the chromosome.
###                - for REGION: 3 additional arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion.
###                - for GENES: 2 additional argument, namely a list of [GENES] and a ±[RANGE].
### - Argument #2  the study to use, AEGS, AAAGS, or CTMM.
### - Argument #3  is input data to use, i.e. where the [imputed] genotypes reside: [1kGp3v5GoNL5/1kGp1v3/GoNL4].
### - Argument #4  is the name of the SNPTEST method used [score/expected].
### - Argument #5  is exclusion-list to be used, can be either:
###                [EXCL_DEFAULT]   * exclusion_nonCEA.list            - excludes all non-CEA samples, THIS IS THE DEFAULT
###                [EXCL_FEMALES]   * exclusion_nonCEA_Females.list    - excludes all non-CEA samples and all females
###                [EXCL_MALES]     * exclusion_nonCEA_Males.list      - excludes all non-CEA samples and all males
###                [EXCL_CKD]       * exclusion_nonCEA_CKD.list        - excludes all non-CEA samples and with CKD
###                [EXCL_NONCKD]    * exclusion_nonCEA_nonCKD.list     - excludes all non-CEA samples and without CKD
###                [EXCL_T2D]       * exclusion_nonCEA_T2D.list        - excludes all non-CEA samples and who have type 2 diabetes
###                [EXCL_NONT2D]    * exclusion_nonCEA_nonT2D.list     - excludes all non-CEA samples and who *do not* have type 2 diabetes
###                [EXCL_SMOKER]    * exclusion_nonCEA_SMOKER.list     - excludes all non-CEA samples and who are smokers 
###                [EXCL_NONSMOKER] * exclusion_nonCEA_nonSMOKER.list  - excludes all non-CEA samples and who are non-smokers
###                [EXCL_PRE2007]   * exclusion_nonCEA_pre2007.list    - excludes all non-CEA samples and who were included before 2007
###                [EXCL_POST2007]  * exclusion_nonCEA_post2007.list   - excludes all non-CEA samples and who were included after 2007
### - Argument #6  is path_to to the phenotype-file [refer to readme for list of available phenotypes].
### - Argument #7  is path_to to the covariates-file [refer to readme for list of available covariates].
### - Argument #8  is path_to the project [name] directory, where the output should be stored.
### - Argument #9  is the amount of memory you want to use on the HPC (GWAS require more than 8 hours per chromosome).
### - Argument #10 is the amount of time you want to use the HPC for the analyses.
### - Argument #11 is your e-mail address; you'll get an email when the jobs have ended or are aborted/killed.
### - Argument #12 are you mail setting; you can get an email if jobs begin (b), end (e), actually start (s), abort (a), or do not want an email (n).

### THIS PART IS SPECIFIC FOR GWAS
### - Argument #13 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT.

### THIS PART IS SPECIFIC FOR INDIVIDUAL VARIANT ANALYSES
### - Argument #13 you are running an individual variant list analysis, thus we expect a path_to to the variant-list-file which includes three columns: SNP CHR BP (e.g. rs12345 5 1234).
### - Argument #14 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT.

### THIS PART IS SPECIFIC FOR REGIONAL ANALYSES
### - Argument #13 you are running a regional analysis, thus we expect here [CHR] (e.g. 1-22 or X; NOTE: GoNL4 doesn't include information for chromosome X).
### - Argument #14 you are running a regional analysis, thus we expect here [REGION_START] (e.g. 12345)
### - Argument #15 you are running a regional analysis, thus we expect here [REGION_END] (e.g. 678910)
### - Argument #16 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT.

### THIS PART IS SPECIFIC FOR PER-GENE ANALYSES
### - Argument #13 you are running a per-gene analysis, thus we expect a path_to to the gene-list-file."
### - Argument #14 you are running a per-gene analysis, thus we expect here [RANGE] (e.g. 500000 for ±500kb)."
### - Argument #15 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT."

### REQUIRED | GENERALS

### SYSTEM REQUIRED | NEVER CHANGE
SOFTWARE=/hpc/local/CentOS7/dhl_ec/software
GWAS_SCRIPTS=${SOFTWARE}/GWASToolKit


### PROJECT SETTINGS
PROJECTNAME=SOMEPROJECTNAME ### Change to some project name, for example 'pcsk6'
PROJECTROOT=/hpc/dhl_ec/YOURLOGINNAME/SOMEDIRECTORY ### you should probably make some directory to have the script put your project in
# Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
if [ ! -d ${PROJECTROOT}/${PROJECTNAME}/ ]; then
	mkdir -v ${PROJECTROOT}/${PROJECTNAME}/
	echo "The project-subdirectory is non-existent. Mr. Bourne will create it for you..."
else
	echo "Your project-subdirectory already exists..."
fi
PROJECT=${PROJECTROOT}/${PROJECTNAME}

### ANALYSIS SETTINGS
ANALYSIS_TYPE="GWAS" # GWAS/VARIANT/REGION/GENES
STUDY_TYPE="AEGS" # AEGS/AAAGS/CTMM | NOTE: currently only AEGS and CTMM works
REFERENCE="1kGp3v5GoNL5" # 1kGp3v5GoNL5/1kGp1v3/GoNL4
METHOD="EXPECTED" #EXPECTED/SCORE -- EXPECTED is likely best
EXCLUSION="EXCL_DEFAULT" # EXCL_DEFAULT/EXCL_FEMALES/EXCL_MALES/EXCL_CKD/EXCL_NONCKD/EXCL_T2D/EXCL_NONT2D/EXCL_SMOKER/EXCL_NONSMOKER/EXCL_PRE2007/EXCL_POST2007

### PHENOTYPES AND COVARIATES
# Example phenotype-list format: -- should be 'binary' OR 'continuous'
# BMI
# CRP
# TRAIT3
PHENOTYPE_FILE="${PROJECTROOT}/${PROJECTNAME}.phenotypes.txt"

# Example covariate-list format:
# COHORT Age sex PC1_2013 PC2_2013 PC3_2013 PC4_2013 PC5_2013 PC6_2013 PC7_2013 PC8_2013 PC9_2013 PC10_2013
COVARIATE_FILE="${PROJECTROOT}/${PROJECTNAME}.covariates.txt"

PHENOTYPES=$(cat ${PHENOTYPE_FILE}) # which phenotypes to investigate anyway
COVARIATES=$(cat ${COVARIATE_FILE}) # covariate list
TRAIT_TYPE="BINARY" # QUANT/BINARY

### DEFINING QSUB SETTINGS
# FOR GWAS
QMEMGWAS="h_vmem=8G" # '8Gb' for GWAS; 
QTIMEGWAS="h_rt=48:00:00" # 12 hours for GWAS; 
QMEMGWASCLUMP="h_vmem=180G" # 180Gb needed for clumping;
QTIMEGWASCLUMP="h_rt=48:00:00" # 12 hours for clumping;
QMEMGWASPLOT="h_vmem=4G" # 4gb for snptest plotter;
QTIMEGWASPLOT="h_rt=12:00:00" # 4 hours for plotter;
QMEMGWASPLOTQC="h_vmem=4G" # 4gb for plotter qc;
QTIMEGWASPLOTQC="h_rt=12:00:00" # 4 hours for plotter qc;
QMEMGWASLZOOM="h_vmem=4G" # 4Gb needed for locuszoom;
QTIMEGWASLZOOM="h_rt=01:00:00" # 15mins for locuszoom;

# FOR VARIANT
QMEMVAR="h_vmem=8G" # 8Gb for variants;
QTIMEVAR="h_rt=00:15:00" # 15mins for variants;

# FOR REGION
QMEMREG="h_vmem=8G" # 8Gb for regions;
QTIMEREG="h_rt=00:30:00" # 30mins for regions;

# FOR GENE
QMEMGENE="h_vmem=8G" # 8Gb for genes;
QTIMEGENE="h_rt=00:30:00" # 30 minutes for genes;
QMEMGENEQC="h_vmem=4G" # 4 Gb for snptest qc;
QTIMEGENEQC="h_rt=00:30:00" # 30 minutes for snptest qc;
QMEMGENELZOOM="h_vmem=4G" # 4Gb for locuszoom;
QTIMEGENELZOOM="h_rt=00:15:00" #15mins for locuszoom;

# MAILSETTINGS
YOUREMAIL="your-mail@address.com" # you're e-mail address; you'll get an email when the job has ended or when it was aborted
MAILSETTINGS="beas" 
# 'b' Mail is sent at the beginning of the job; 
# 'e' Mail is sent at the end of the job; 
# 'a' Mail is sent when the job is aborted or rescheduled.
# 's' Mail is sent when the job is suspended;
# 'n' No mail is sent.

 
### ANALYSIS SPECIFIC ARGUMENTS
# For per-variant analysis
# EXAMPLE FORMAT
# rs1234 1 12345567
# rs5678 2 12345567
# rs4321 14 12345567
# rs9876 20 12345567
VARIANTLIST="${PROJECTROOT}/${PROJECTNAME}.variantlist.txt"

# For GWAS/REGION/GENE analysis
LZVERSION="LZ13"
RANGE="500000" # 500000=500kb, needed for GWAS (LocusZoom plots); and GENE analyses (analysis and LocusZoom plots)

# For GWAS
CLUMP_P2="1"
CLUMP_P1="0.000005" # should be of the form 0.005 rather than 5e-3
CLUMP_R2="0.2"
CLUMP_KB="500"
CLUMP_FIELD="P"

# For regional analysis
CHR="none" # e.g. 1
REGION_START="none" # e.g. 12345678
REGION_END="none" # e.g. 87654321

# For per-gene analysis
GENES_FILE="${PROJECTROOT}/${PROJECTNAME}.genelist.txt"

# Filter settings -- specifically, GWAS, GENE and REGIONAL analyses
INFO="0.3"
MAC="6"
CAF="0.005"
BETA_SE="100"

### SYSTEM REQUIRED | NEVER CHANGE
OUTPUT_DIR=${PROJECT}/snptest_results 
VARIANTID="2"
PVALUE="17"
RANGELZ=$(expr "$RANGE" / 1000)

### RETURNING SETTINGS
echo "-----------------------------------------"
echo "            General settings"
echo "-----------------------------------------"
echo "The analysis scripts are located here...................................: ${GWAS_SCRIPTS}"
echo "The following dataset will be used......................................: ${STUDY_TYPE}"
echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
echo "The analysis will be run using the following method.....................: ${METHOD}"
echo ""
echo "-----------------------------------------"
echo "        Project specific settings"
echo "-----------------------------------------"
echo "The project name is.....................................................: ${PROJECTNAME}"
echo "The project directory is................................................: ${PROJECT}"
echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION}"
echo "The analysis will be run using the following phenotypes.................: ${PHENOTYPE_FILE}"
echo "The type of phenotypes..................................................: ${TRAIT_TYPE}"
echo "The analysis will be run using the following covariates.................: ${COVARIATE_FILE}"
echo "The minimum info-score filter is........................................: ${INFO}"
echo "The minimum minor allele count is.......................................: ${MAC}"
echo "The minimum coded allele frequency is...................................: ${CAF}"
echo "The lower/upper limit of the BETA/SE is.................................: ${BETA_SE}"
echo "Maximum (largest) p-value to clump......................................: ${CLUMP_P2}"
echo "Minimum (smallest) p-value to clump.....................................: ${CLUMP_P1}"
echo "R^2 to use for clumping.................................................: ${CLUMP_R2}"
echo "The KB range used for clumping..........................................: ${CLUMP_KB}"
echo "Indicate the name of the clumping field to use (default: p-value, P)....: ${CLUMP_FIELD}"
echo "The following list of variants will be analysed.........................: ${VARIANTLIST}"
echo "The chromosomal region will be analysed.................................: chromosome ${CHR}:${REGION_START}-${REGION_END}"
echo "The following genes will be analysed....................................: ${GENES_FILE}"
echo "The following range around genes will be taken..........................: ${RANGE}"
	
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### SUBMIT SNPTEST_PHENO

if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
	echo "Creating jobs to perform GWAS on your phenotype(s)..."
	${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMGWAS} ${QTIMEGWAS} ${YOUREMAIL} ${MAILSETTINGS} ${TRAIT_TYPE} 

	### Create QC bash-script to send to qsub
	for PHENOTYPE in ${PHENOTYPES}; do
	
		PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
	
		echo "${GWAS_SCRIPTS}/snptest_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${INFO} ${MAC} ${CAF} ${BETA_SE}" > ${PROJECT}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		### Submit QC script
		### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
		qsub -S /bin/bash -N QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWAS} -l ${QTIMEGWAS} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		echo ""

		### Create plotter bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/snptest_plotter.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PROJECT}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		### Submit plotter script
		qsub -S /bin/bash -N PLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASPLOT} -l ${QTIMEGWASPLOT} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		echo ""

		### Create QC plotter bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/snptest_plotter_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PROJECT}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		### Submit QC plotter script
		qsub -S /bin/bash -N QCPLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASPLOTQC} -l ${QTIMEGWASPLOTQC} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		echo ""

		#### Create clumper bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/snptest_clumper.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${CLUMP_P1} ${CLUMP_P2} ${CLUMP_R2} ${CLUMP_KB} ${CLUMP_FIELD} ${REFERENCE}" > ${PROJECT}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		#### Submit clumper script
		qsub -S /bin/bash -N CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASCLUMP} -l ${QTIMEGWASCLUMP} -M ${YOUREMAIL} -m ${MAILSETTINGS} -pe threaded 12 -wd ${PROJECT} ${PROJECT}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		echo ""
	
		##### Create locuszoom bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION} ${PHENO_OUTPUT_DIR}/${PHENOTYPE}.summary_results.QC.${CLUMP_R2}.indexvariants.txt ${RANGE}" > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		##### Submit locuszoom script
		qsub -S /bin/bash -N LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh

		##### Create cleaner bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/snptest_cleaner.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${EXCLUSION} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		##### Submit cleaner script
		qsub -S /bin/bash -N CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh

	done

elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
	echo "Creating jobs to perform an individual variant analysis on your phenotype(s)..."
	${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMVAR} ${QTIMEVAR} ${YOUREMAIL} ${MAILSETTINGS} ${VARIANTLIST} ${TRAIT_TYPE}

	for PHENOTYPE in ${PHENOTYPES}; do
		##### Create cleaner bash-script to send to qsub
		echo "${GWAS_SCRIPTS}/snptest_cleaner.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${EXCLUSION} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		qsub -S /bin/bash -N CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
	done

elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
	echo "Creating jobs to perform a regional analysis on your phenotype(s)..."
	${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMREG} ${QTIMEREG} ${YOUREMAIL} ${MAILSETTINGS} ${CHR} ${REGION_START} ${REGION_END} ${TRAIT_TYPE}

elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
	echo "Creating jobs to perform a per-analysis on your phenotype(s)..."
	${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMGENE} ${QTIMEGENE} ${YOUREMAIL} ${MAILSETTINGS} ${GENES_FILE} ${RANGE} ${TRAIT_TYPE}

	### Create QC bash-script to send to qsub
	while read GENES; do
		for GENE in ${GENES}; do
			echo "* ${GENE} ± ${RANGE}"
			for PHENOTYPE in ${PHENOTYPES}; do

				GENE_OUTPUT_DIR=${OUTPUT_DIR}/${GENE}
				PHENO_OUTPUT_DIR=${GENE_OUTPUT_DIR}/${PHENOTYPE}

				echo "${GWAS_SCRIPTS}/snptest_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${INFO} ${MAC} ${CAF} ${BETA_SE}" > ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				### Submit plotter script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
				qsub -S /bin/bash -N QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE} -o ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGENEQC} -l ${QTIMEGENEQC} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
	
				##### Create locuszoom bash-script to send to qsub
				echo "${GWAS_SCRIPTS}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION} ${GENE} ${RANGELZ}" > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				##### Submit clumper script
				#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
				qsub -S /bin/bash -N LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGENELZOOM} -l ${QTIMEGENELZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				echo ""
			done
		done
	done < ${GENES_FILE}
	
else
	### If arguments are not met than the 
	echo ""
	echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
	echo ""
	echo " You must supply the correct argument:"
	echo " * [GWAS]         -- uses a total of 13 arguments | THIS IS THE DEFAULT."
	echo " * [VARIANT]      -- uses 14 arguments, and the last should be a variant-list and the chromosome."
	echo " * [REGION]       -- uses 16 arguments, and the last three should indicate the chromosomal range."
	echo " * [GENES]        -- uses 14 arguments, and the last three should indicate the gene list and the range."
	echo ""
	echo " Please refer to instruction above."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	# The wrong arguments are passed, so we'll exit the script now!
	date
	exit 1
fi

#IN ALL CASES
#	UPON COMPLETION RUN fastQTL FOR mQTL
#	
#	AFTER fastQTL PRODUCE QC PLOTS
#	
#IN CASE OF GWAS
#	
#	LOOKUP SNP IN AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA (LOOKUP SCRIPT)
#
#IN CASE OF REGION
#	UPON COMPLETION (WRAPPER SCRIPT!) RUN LOCUSZOOM PLOTTER OF REGION
#	
#	LOOKUP SNP IN AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA
#	
#IN CASE OF VARIANT
#	UPON COMPLETION (WRAPPER SCRIPT!) LOOKUP SNP IN AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA (LOOKUP SCRIPT)
#	
#
#PRODUCE RELEVANT README
#
#GZIP
# Put all graphs in one document including readme.

THISYEAR=$(date +'%Y')
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ The MIT License (MIT)                                                                                 +"
echo "+ Copyright (c) 2015-${THISYEAR} Sander W. van der Laan                                                             +"
echo "+                                                                                                       +"
echo "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +"
echo "+ associated documentation files (the \"Software\"), to deal in the Software without restriction,         +"
echo "+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +"
echo "+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +"
echo "+ subject to the following conditions:                                                                  +"
echo "+                                                                                                       +"
echo "+ The above copyright notice and this permission notice shall be included in all copies or substantial  +"
echo "+ portions of the Software.                                                                             +"
echo "+                                                                                                       +"
echo "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +"
echo "+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +"
echo "+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +"
echo "+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +"
echo "+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +"
echo "+                                                                                                       +"
echo "+ Reference: http://opensource.org.                                                                     +"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"