#! /bin/bash -x

# Clear the scene!
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "     RUN_ANALYSES.v1: INDIVIDUAL VARIANT, REGIONAL OR GENOME-WIDE ASSOCIATION STUDY ON A PHENOTYPE"
echo ""
echo " You're here: "`pwd`
echo " Today's: "`date`
echo ""
echo " Version: RUN_ANALYSES.v1.20160208"
echo ""
echo " Last update: February 8th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl);"
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
###                - for GWAS: no additional arguments, except the standard 10 arguments in total.
###                - for VARIANT: 2 additional argument, namely a [FILE] containing the list of variants and the chromosome.
###                - for REGION: 3 additional arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion.
###                - for GENES: 2 additional argument, namely a list of [GENES] and a ±[RANGE].
### - Argument #2  is input data to use, i.e. where the [imputed] genotypes reside: [1kGp3v5GoNL5/1kGp1v3/GoNL4].
### - Argument #3  is the name of the SNPTEST method used [score/expected].
### - Argument #4  is exclusion-list to be used, can be either:
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
### - Argument #5  is path_to to the phenotype-file [refer to readme for list of available phenotypes].
### - Argument #6  is path_to to the covariates-file [refer to readme for list of available covariates].
### - Argument #7  is path_to the project [name] directory, where the output should be stored.
### - Argument #8  is the name of the queue to use [veryshort/short/medium/long/verylong] (GWAS require more than 8 hours per chromosome).
### - Argument #9  is your e-mail address; you'll get an email when the jobs have ended or are aborted/killed.

### THIS PART IS SPECIFIC FOR GWAS
### - Argument #10 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT.
### - Argument #11 is minimum info-score [INFO]."
### - Argument #12 is minimum minor allele count [MAC]."
### - Argument #13 is minimum coded allele frequency [CAF]."
### - Argument #14 is lower/upper limit of the BETA/SE [BETA_SE]."

### THIS PART IS SPECIFIC FOR INDIVIDUAL VARIANT ANALYSES
### - Argument #10 you are running an individual variant list analysis, thus we expect a path_to to the variant-list-file."
### - Argument #11 you are running a regional analysis, thus we expect here [CHR] (e.g. 1-22 or X; NOTE: GoNL4 doesn't include information for chromosome X)."
### - Argument #12 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT."

### THIS PART IS SPECIFIC FOR REGIONAL ANALYSES
### - Argument #10 you are running a regional analysis, thus we expect here [CHR] (e.g. 1-22 or X; NOTE: GoNL4 doesn't include information for chromosome X).
### - Argument #11 you are running a regional analysis, thus we expect here [REGION_START] (e.g. 12345)
### - Argument #12 you are running a regional analysis, thus we expect here [REGION_END] (e.g. 678910)
### - Argument #13 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT.

### REQUIRED
SOFTWARE=/hpc/local/CentOS6/dhl_ec/software
GWAS_SCRIPTS=${SOFTWARE}/GWAS
PROJECTROOT=/hpc/dhl_ec/svanderlaan/projects/testing_gwas
ANALYSIS_TYPE="GENES"
REFERENCE="1kGp3v5GoNL5"
METHOD="EXPECTED"
EXCLUSION="EXCL_DEFAULT"
PHENOTYPE_FILE="${PROJECTROOT}/phenotypes_pp_bin.txt"
COVARIATE_FILE="${PROJECTROOT}/covariates.txt"
PROJECT="${PROJECTROOT}"
QSUBQUEUE="veryshort" # 'medium' (24 hours) for GWAS; 'veryshort' (2 hours) for anything else
YOUREMAIL="s.w.vanderlaan-2@umcutrecht.nl" # you're e-mail address; you'll get an email when the job has ended or when it was aborted
TRAIT_TYPE="BINARY"
INFO="0.3"
MAC="6"
CAF="0.005"
BETA_SE="100"
CLUMP_P2="1"
CLUMP_P1="0.000005" # should be of the form 0.005 rather than 5e-3
CLUMP_R2="0.2"
CLUMP_KB="500"
CLUMP_FIELD="P"
VARIANTLIST="none"
CHR="none"
REGION_START="none"
REGION_END="none"
GENES="${PROJECTROOT}/genes.txt"
RANGE="500000" # 500000=500kb


### RETURNING SETTINGS
echo "These things were set:"
echo "The analysis scripts are located here...................................: ${GWAS_SCRIPTS}"
echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
echo "The analysis will be run using the following method.....................: ${METHOD}"
echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION}"
echo "The analysis will be run using the following phenotypes.................: ${PHENOTYPE_FILE}"
echo "The analysis will be run using the following covariates.................: ${COVARIATE_FILE}"
echo "The project directory is................................................: ${PROJECT}"
echo "The analysis will be run on the following queue.........................: ${QSUBQUEUE}"
echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
echo "The type of phenotypes..................................................: ${TRAIT_TYPE}"
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
echo "The following genes will be analysed....................................: ${GENES}"
echo "The following range around genes will be taken..........................: ${RANGE}"
	
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### SUBMIT SNPTEST_PHENO

if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
	echo "Creating jobs to perform GWAS on your phenotype(s)..."
	sh ${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QSUBQUEUE} ${YOUREMAIL} ${TRAIT_TYPE} ${INFO} ${MAC} ${CAF} ${BETA_SE}

	PHENOTYPES=`cat ${PHENOTYPE_FILE}` # which phenotypes to investigate anyway
	COVARIATES=`cat ${COVARIATE_FILE}` # covariate list
	
	for PHENOTYPE in ${PHENOTYPES}; do
		#### Create clumper bash-script to send to qsub
		echo "sh ${GWAS_SCRIPTS}/snptest_clumper.v1.sh ${PROJECT}/snptest_results ${PHENOTYPE} ${CLUMP_P1} ${CLUMP_P2} ${CLUMP_R2} ${CLUMP_KB} ${CLUMP_FIELD} ${REFERENCE}" > ${PROJECT}/clumper.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.sh
		#### Submit clumper script
		#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N PLOTTER.AEGSGWAS' are finished
		qsub -S /bin/bash -N CLUMPER.AEGSGWAS.${PHENOTYPE}.${EXCLUSION} -hold_jid PLOTTER.AEGSGWAS.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/clumper.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.output -e ${PROJECT}/clumper.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.errors -q $QSUBQUEUE -M ${YOUREMAIL} -m ea -wd ${PROJECT} ${PROJECT}/clumper.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.sh
		sleep 0.25s
	done

	for PHENOTYPE in ${PHENOTYPES}; do
		#### Create locuszoom bash-script to send to qsub
		echo "sh ${GWAS_SCRIPTS}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${PROJECT}/snptest_results ${PROJECT}/snptest_results/${PHENOTYPE}.summary_results.QC.${CLUMP_R2}.indexvariants.txt ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION}" > ${PROJECT}/locuszoom.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.sh
		#### Submit locuszoom script
		#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N CLUMPER.AEGSGWAS' are finished
		qsub -S /bin/bash -N LZ.AEGSGWAS.${PHENOTYPE}.${EXCLUSION} -hold_jid CLUMPER.AEGSGWAS.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/locuszoom.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/locuszoom.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.errors -q $QSUBQUEUE -M ${YOUREMAIL} -m ea -wd ${PROJECT} ${PROJECT}/locuszoom.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.sh
		sleep 0.25s
	done

elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
	echo "Creating jobs to perform an individual variant analysis on your phenotype(s)..."
	sh ${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QSUBQUEUE} ${YOUREMAIL} ${VARIANTLIST} ${TRAIT_TYPE}

elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
	echo "Creating jobs to perform a regional analysis on your phenotype(s)..."
	sh ${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QSUBQUEUE} ${YOUREMAIL} ${CHR} ${REGION_START} ${REGION_END} ${TRAIT_TYPE}

elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
	echo "Creating jobs to perform a regional analysis on your phenotype(s) for each gene..."
	sh ${GWAS_SCRIPTS}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QSUBQUEUE} ${YOUREMAIL} ${GENES} ${RANGE} ${TRAIT_TYPE}
	
	#for PHENOTYPE in ${PHENOTYPES}; do
	#	GENES_LIST=`cat ${GENES}` # genes list
	#	for GENE in ${GENES_LIST}; do
	#		echo "Processing ${GENE} locus with ${RANGE}..."
	#		### Create locuszoom bash-script to send to qsub
	#		echo "sh ${GWAS_SCRIPTS}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${PROJECT}/snptest_results ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION} ${RANGE}" > ${PROJECT}/locuszoom.AEGSGENE.${PHENOTYPE}.${EXCLUSION}.sh
	#		#### Submit clumper script
	#		#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N CLUMPER.AEGSGWAS' are finished
	#		qsub -S /bin/bash -N LZ.AEGSGENE.${PHENOTYPE}.${EXCLUSION} -hold_jid CLUMPER.AEGSGENE.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/locuszoom.AEGSGWAS.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/locuszoom.AEGSGENE.${PHENOTYPE}.${EXCLUSION}.errors -q $QSUBQUEUE -M ${YOUREMAIL} -m ea -wd ${PROJECT} ${PROJECT}/locuszoom.AEGSGENE.${PHENOTYPE}.${EXCLUSION}.sh
	#		sleep 0.25s
	#	done 

	
else
	### If arguments are not met than the 
	echo ""
	echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
	echo ""
	echo " You must supply the correct argument:"
	echo " * [GWAS]         -- uses a total of 10 arguments | THIS IS THE DEFAULT."
	echo " * [VARIANT]      -- uses 12 arguments, and the last should be a variant-list and the chromosome."
	echo " * [REGION]       -- uses 13 arguments, and the last three should indicate the chromosomal range."
	echo ""
	echo " Please refer to instruction above."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	# The wrong arguments are passed, so we'll exit the script now!
	date
	exit 1
fi
#
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
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ The MIT License (MIT)                                                                                 +"
echo "+ Copyright (c) 2016 Sander W. van der Laan                                                             +"
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


