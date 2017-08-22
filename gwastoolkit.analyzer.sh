#!/bin/bash

### Creating display functions
### Setting colouring
NONE='\033[00m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
STRIKETHROUGH='\033[9m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoitalic { 
    echo -e "${ITALIC}${1}${NONE}" 
}
function echonooption { 
    echo -e "${OPAQUE}${RED}${1}${NONE}"
}
function echoerrorflash { 
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}" 
}
function echoerror { 
    echo -e "${RED}${1}${NONE}"
}
# errors no option
function echoerrornooption { 
    echo -e "${YELLOW}${1}${NONE}"
}
function echoerrorflashnooption { 
    echo -e "${YELLOW}${BOLD}${FLASHING}${1}${NONE}"
}

### MESSAGE FUNCTIONS
script_copyright_message() {
	echo ""
	THISYEAR=$(date +'%Y')
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "+ The MIT License (MIT)                                                                                 +"
	echo "+ Copyright (c) 2015-${THISYEAR} Sander W. van der Laan                                                        +"
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
}
script_arguments_error() {
	echoerror "$1" # ERROR MESSAGE
	echoerror "- Argument #1  indicates whether you want to analyse a list of variants, a region, or do a GWAS [VARIANT/REGION/GWAS]."
	echoerror "               Depending on the choice you additional arguments are expected:"
	echoerror "               - for GWAS: the standard 11 arguments in total."
	echoerror "               - for VARIANT: additional argument, namely a [FILE] containing the list of variants and the chromosome."
	echoerror "               - for REGION: additional arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion."
	echoerror "               - for GENES: additional arguments, namely the [GENES] list and [RANGE] in numerical fashion."
	echoerror "- Argument #2  the study to use, AEGS, AAAGS, or CTMM."
	echoerror "- Argument #3  is input data to use, i.e. where the [imputed] genotypes reside: [1kGp3v5GoNL5/1kGp1v3/GoNL4]."
	echoerror "- Argument #4  is the name of the SNPTEST method used [score/expected]."
	echoerror "- Argument #5  is exclusion-list to be used, can be either:"
	echoerror "               [EXCL_DEFAULT]   * exclusion_nonCEA.list            - excludes all non-STUDY samples, THIS IS THE DEFAULT"
	echoerror "               [EXCL_FEMALES]   * exclusion_nonCEA_Females.list    - excludes all non-STUDY samples and all females"
	echoerror "               [EXCL_MALES]     * exclusion_nonCEA_Males.list      - excludes all non-STUDY samples and all males"
	echoerror "               [EXCL_CKD]       * exclusion_nonCEA_CKD.list        - excludes all non-STUDY samples and with CKD"
	echoerror "               [EXCL_NONCKD]    * exclusion_nonCEA_nonCKD.list     - excludes all non-STUDY samples and without CKD"
	echoerror "               [EXCL_T2D]       * exclusion_nonCEA_T2D.list        - excludes all non-STUDY samples and who have type 2 diabetes"
	echoerror "               [EXCL_NONT2D]    * exclusion_nonCEA_nonT2D.list     - excludes all non-STUDY samples and who *do not* have type 2 diabetes"
	echoerror "               [EXCL_SMOKER]    * exclusion_nonCEA_SMOKER.list     - excludes all non-STUDY samples and who are smokers "
	echoerror "               [EXCL_NONSMOKER] * exclusion_nonCEA_nonSMOKER.list  - excludes all non-STUDY samples and who are non-smokers"
	echoerror "               [EXCL_PRE2007]   * exclusion_nonCEA_pre2007.list    - excludes all non-STUDY samples and who were included before 2007; AE exclusive"
	echoerror "               [EXCL_POST2007]  * exclusion_nonCEA_post2007.list   - excludes all non-STUDY samples and who were included after 2007; AE exclusive"
	echoerror "- Argument #6  is path_to to the phenotype-file [refer to readme for list of available phenotypes]."
	echoerror "- Argument #7  is path_to to the covariates-file [refer to readme for list of available covariates]."
	echoerror "- Argument #8  is path_to the project [name] directory, where the output should be stored."
	echoerror "- Argument #9  is the amount of Gigabytes of memory you want to use on the HPC (GWAS require more than 8 hours per chromosome)."
	echoerror "- Argument #10 is the amount of time you want to use the HPC for"
	echoerror "- Argument #11 is your e-mail address; you'll get an email when the jobs have ended or are aborted/killed."
	echoerror "- Argument #12 are you mail setting; you can get an email if jobs begin (b), end (e), actually start (s), abort (a), or do not want an email (n)."
	echoerror ""
	echoerror "For GWAS:"
	echoerror "- Argument #13 determines the way phenotypes are normalized, i.e. raw or standardized phenotypes are used [RAW/STANDARDIZE]."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.analyzer.sh [arg1: VARIANT/REGION/GWAS] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: SCORE/EXPECTED] [arg5: which_exclusion_list] [arg6: path_to_phenotype_file ] [arg7: path_to_covariates_file ] [arg8: path_to_project] [arg9: job_memory] [arg10: job_time] [arg11: your_email@domain.com] [arg12: mailsettings] [arg13: standardize [STANDARDIZE/RAW]]"
  	echoerror ""
  	echoerror "For per-VARIANT ANALYSES:"
	echoerror "- Argument #13 you are running an individual variant list analysis, thus we expect a path_to to the variant-list-file which includes three columns: SNP CHR BP (e.g. rs12345 5 1234)."
	echoerror "- Argument #14 determines the way phenotypes are normalized, i.e. raw or standardized phenotypes are used [RAW/STANDARDIZE]."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.analyzer.sh [arg1: VARIANT/REGION/GWAS] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: SCORE/EXPECTED] [arg5: which_exclusion_list] [arg6: path_to_phenotype_file ] [arg7: path_to_covariates_file ] [arg8: path_to_project] [arg9: job_memory] [arg10: job_time] [arg11: your_email@domain.com] [arg12: mailsettings] [arg13: path_to_variant_list] [arg14: standardize [STANDARDIZE/RAW]]"
	echoerror ""
  	echoerror "For REGIONAL ANALYSES:"
	echoerror "- Argument #13 you are running a regional analysis, thus we expect here [CHR] (e.g. 1-22 or X; NOTE: GoNL4 doesn't include information for chromosome X)."
	echoerror "- Argument #14 you are running a regional analysis, thus we expect here [REGION_START] (e.g. 12345)"
	echoerror "- Argument #15 you are running a regional analysis, thus we expect here [REGION_END] (e.g. 678910)"
	echoerror "- Argument #16 determines the way phenotypes are normalized, i.e. raw or standardized phenotypes are used [RAW/STANDARDIZE]."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.analyzer.sh [arg1: VARIANT/REGION/GWAS] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: SCORE/EXPECTED] [arg5: which_exclusion_list] [arg6: path_to_phenotype_file ] [arg7: path_to_covariates_file ] [arg8: path_to_project] [arg9: job_memory] [arg10: job_time] [arg11: your_email@domain.com] [arg12: mailsettings] [arg13: chromosome] [arg14: region_start] [arg15: region_end] [arg16: standardize [STANDARDIZE/RAW]]"
	echoerror ""
  	echoerror "For per-GENE ANALYSES:"
  	echoerror "- Argument #13 you are running a per-gene analysis using a list of genes, thus we expect here path_to_a_list_of [GENES]."
	echoerror "- Argument #14 you are running a per-gene analysis, thus we expect here [RANGE]."
	echoerror "- Argument #15 determines the way phenotypes are normalized, i.e. raw or standardized phenotypes are used [RAW/STANDARDIZE]."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.analyzer.sh [arg1: VARIANT/REGION/GWAS] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: SCORE/EXPECTED] [arg5: which_exclusion_list] [arg6: path_to_phenotype_file ] [arg7: path_to_covariates_file ] [arg8: path_to_project] [arg9: job_memory] [arg10: job_time] [arg11: your_email@domain.com] [arg12: mailsettings] [arg13: chromosome] [arg14: range] [arg15: standardize [STANDARDIZE/RAW]]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}
script_arguments_error_normalization() {
	echoerror "$1" 
	echoerror ""
	echoerror "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
	echoerror ""
	echoerror " You must supply the correct argument:"
	echoerror " * [STANDARDIZE/RAW] -- SNPTEST can either use the raw trait data or standardize it on the fly."
	echoerror ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}
script_arguments_error_analysis_type() {
	echoerror "$1" 
	echoerror ""
	echoerror "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
	echoerror ""
	echoerror " You must supply the correct argument:"
	echoerror " * [GWAS]         -- genome-wide association study of traits in ${PHENOTYPE_FILE}."
	echoerror " * [VARIANT]      -- genetic analysis of variants in ${VARIANTLIST} for traits in ${PHENOTYPE_FILE}."
	echoerror " * [REGION]       -- genetic analysis of a specific region [chr${CHR}:${REGION_START}-${REGION_END}] for traits in ${PHENOTYPE_FILE}."
	echoerror " * [GENE]         -- genetic analysis of specific genes in ${GENES_FILE} for traits in ${PHENOTYPE_FILE}."
	echoerror ""
	echoerror " Please refer to instruction above."
	echoerror ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                            GWASTOOLKIT ANALYZER"
echobold "           individual variant, per-gene, regional, or genome-wide association study of a trait"
echobold ""
echobold " Version    : v1.2.13"
echobold ""
echobold " Last update: 2017-08-22"
echobold " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold "              - Jacco Schaap (j.schaap-2@umcutrecht.nl)"
echobold "              - Tim Bezemer (t.bezemer-2@umcutrecht.nl)"
echobold ""
echobold " Description: Perform individual variant, regional or genome-wide association "
echobold "              analysis on some phenotype(s). It will do the following:"
echobold "              - Run GWAS using SNPTESTv2.5.2 and 1000G (phase 1), GoNL4, or "
echobold "                1000G (phase 3) + GoNL5 data per chromosome."
echobold "              - Collect results in one file upon completion of jobs."
echobold ""
echobold " REQUIRED: "
echobold " * A high-performance computer cluster with a qsub system."
echobold " * Imputed genotype data with 1000G[p1/p3]/GoNL[4/5] as reference."
echobold " * SNPTEST v2.5+"
echobold " * R v3.2+"
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!

### START of if-else statement for the number of command-line arguments passed ###
if [[ ${ANALYSIS_TYPE} = "GWAS" && $# -lt 1 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply correct arguments when running a *** GENOME-WIDE ANALYSIS ***!"
	
elif [[ ${ANALYSIS_TYPE} = "VARIANT" && $# -lt 1 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply correct arguments when running a *** VARIANT ANALYSIS ***!"
	
elif [[ ${ANALYSIS_TYPE} = "REGION" && $# -lt 1 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply correct arguments when running a *** REGIONAL ANALYSIS ***!"
	
elif [[ ${ANALYSIS_TYPE} = "GENES" && $# -lt 1 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply correct arguments when running a *** GENE ANALYSIS ***!"
	
else
	
echo "All arguments are passed and correct. These are the settings:"
	
### Set input-data
PHENOTYPES=$(cat "$PHENOTYPE_FILE") # which phenotypes to investigate anyway
COVARIATES=$(cat "$COVARIATE_FILE") # covariate list

### Set location of the individual, regional and GWAS scripts
	
	### Report back these variables
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		QMEM=${QMEMGWAS}
		QTIME=${QTIMEGWAS}
		echo "SNPTEST is located here.................................................: ${SNPTEST}"
		echo "The analysis scripts are located here...................................: ${GWASTOOLKITDIR}"
		echo "The following dataset will be used......................................: ${STUDY_TYPE}"
		echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
		echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
		echo "The analysis will be run using the following method.....................: ${METHOD}"
		echo "The analysis will be run using the following exclusion .................: ${EXCLUSION}"
		echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION_LIST}"
		echo "The way phenotypes are handle (normalization on/off)....................: ${STANDARDIZE}"
		echo "The analysis will be run using the following phenotypes.................: "
		for PHENOTYPE in ${PHENOTYPES}; do
			echo "     * ${PHENOTYPE}"
		done
		echo ""
		echo "The analysis will be run using the following covariates.................: ${COVARIATES}"
		echo "The project directory is................................................: ${PROJECTDIR}/${PROJECTNAME}"
		echo "The following list of variants will be used.............................: ${VARIANTLIST}"
		echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
		echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
		### Starting of the script
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                                     SUBMIT ACTUAL GENOME-WIDE ANALYSIS"
		echo ""
		echo "Please be patient as we are creating jobs to submit genome-wide analysis of each phenotype..."
		echo "We started at: "$(date)
		echo ""
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
		QMEM=${QMEMVAR}
		QTIME=${QTIMEVAR}
		echo "SNPTEST is located here.................................................: ${SNPTEST}"
		echo "The analysis scripts are located here...................................: ${GWASTOOLKITDIR}"
		echo "The following dataset will be used......................................: ${STUDY_TYPE}"
		echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
		echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
		echo "The analysis will be run using the following method.....................: ${METHOD}"
		echo "The analysis will be run using the following exclusion .................: ${EXCLUSION}"
		echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION_LIST}"
		echo "The way phenotypes are handle (normalization on/off)....................: ${STANDARDIZE}"
		echo "The analysis will be run using the following phenotypes.................: "
		for PHENOTYPE in ${PHENOTYPES}; do
			echo "     * ${PHENOTYPE}"
		done
		echo ""
		echo "The analysis will be run using the following covariates.................: ${COVARIATES}"
		echo "The project directory is................................................: ${PROJECTDIR}/${PROJECTNAME}"
		echo "The following list of variants will be used.............................: ${VARIANTLIST}"
		echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
		echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
		### Starting of the script
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                                    SUBMIT ACTUAL INDIVIDUAL VARIANT ANALYSIS"
		echo ""
		echo "Please be patient as we are creating jobs to submit individual variant analysis of each phenotype..."
		echo "We started at: "$(date)
		echo ""
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		QMEM=${QMEMREG}
		QTIME=${QTIMEREG}
		echo "SNPTEST is located here.................................................: ${SNPTEST}"
		echo "The analysis scripts are located here...................................: ${GWASTOOLKITDIR}"
		echo "The following dataset will be used......................................: ${STUDY_TYPE}"
		echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
		echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
		echo "The analysis will be run using the following method.....................: ${METHOD}"
		echo "The analysis will be run using the following exclusion .................: ${EXCLUSION}"
		echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION_LIST}"
		echo "The way phenotypes are handle (normalization on/off)....................: ${STANDARDIZE}"
		echo "The analysis will be run using the following phenotypes.................: "
		for PHENOTYPE in ${PHENOTYPES}; do
			echo "     * ${PHENOTYPE}"
		done
		echo ""
		echo "The analysis will be run using the following covariates.................: ${COVARIATES}"
		echo "The project directory is................................................: ${PROJECTDIR}/${PROJECTNAME}"
		echo "The chromosomal region will be analysed.................................: chromosome ${CHR}:${REGION_START}-${REGION_END}"
		echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
		echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
		### Starting of the script
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                                      SUBMIT ACTUAL REGIONAL ANALYSIS"
		echo ""
		echo "Please be patient as we are creating jobs to submit regional analysis of each phenotype..."
		echo "We started at: "$(date)
		echo ""
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		### Setting variant list
		GENES=$(cat ${GENES_FILE})
		QMEM=${QMEMGENE}
		QTIME=${QTIMEGENE}
		echo "SNPTEST is located here.................................................: ${SNPTEST}"
		echo "The analysis scripts are located here...................................: ${GWASTOOLKITDIR}"
		echo "The following dataset will be used......................................: ${STUDY_TYPE}"
		echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
		echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
		echo "The analysis will be run using the following method.....................: ${METHOD}"
		echo "The analysis will be run using the following exclusion .................: ${EXCLUSION}"
		echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION_LIST}"
		echo "The way phenotypes are handle (normalization on/off)....................: ${STANDARDIZE}"
		echo "The analysis will be run using the following phenotypes.................: "
		for PHENOTYPE in ${PHENOTYPES}; do
			echo "     * ${PHENOTYPE}"
		done
		echo ""
		echo "The analysis will be run using the following covariates.................: ${COVARIATES}"
		echo "The project directory is................................................: ${PROJECTDIR}/${PROJECTNAME}"
		echo "The following genes will be analysed....................................: "
		for GENE in ${GENES}; do
			echo "     * ${GENE}"
		done
		echo ""
		echo "The following range around genes will be taken..........................: ${RANGE}"
		echo "The following gene list will be used....................................: ${HG19_GENES}"
		echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
		echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
		### Starting of the script
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                                      SUBMIT ACTUAL PER-GENE ANALYSIS"
		echo ""
		echo "Please be patient as we are creating jobs to submit regional analysis of each phenotype..."
		echo "We started at: "$(date)
		echo ""
	else
		### If arguments are not met then this error message will be displayed 
		script_arguments_error_analysis_type
	fi
	
	### Make and/or set the output directory
	if [ ! -d ${PROJECTDIR}/${PROJECTNAME}/snptest_results ]; then
  		echo "The output directory does not exist. Making and setting it."
  		mkdir -v ${PROJECTDIR}/${PROJECTNAME}/snptest_results
  		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results
	else
  		echo "The output directory already exists. Setting it."
  		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results
	fi

	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		echo "Submit jobs to perform GWAS on your phenotype(s)..."
		### Run SNPTEST for each phenotype
		for PHENOTYPE in ${PHENOTYPES}; do
		### Make and/or set the output directory
			if [ ! -d ${OUTPUT_DIR}/${PHENOTYPE} ]; then
  				echo "The output directory does not exist. Making and setting it."
  				mkdir -v ${OUTPUT_DIR}/${PHENOTYPE}
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			else
  				echo "The output directory already exists. Setting it."
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			fi
		echo "Analysing the phenotype ${PHENOTYPE}."
			for CHR in $(seq 1 22) X; do
				echo "Processing the following chromosome ${CHR}."
				if [[ ${STANDARDIZE} = "STANDARDIZE" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.sh
				elif [[ ${STANDARDIZE} = "RAW" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -use_raw_phenotypes -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}.sh
				else
					### If arguments are not met then this error message will be displayed
					script_arguments_error_normalization
				fi

				echo ""
				echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
				echo ""
			done
			### Create wrap-up bash-script to send to qsub
			echo "${GWASTOOLKITDIR}/gwastoolkit.wrapper.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			### Submit wrap-up script
			### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N AEGS_GWAS' are finished
			qsub -S /bin/bash -N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEM} -l ${QTIME} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			echo ""

		done
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
		echo "Submit jobs to perform individual variant analysis on your phenotype(s)..."
		### Run SNPTEST for each phenotype
		for PHENOTYPE in ${PHENOTYPES}; do
		### Make and/or set the output directory
			if [ ! -d ${OUTPUT_DIR}/${PHENOTYPE} ]; then
  				echo "The output directory does not exist. Making and setting it."
  				mkdir -v ${OUTPUT_DIR}/${PHENOTYPE}
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			else
  				echo "The output directory already exists. Setting it."
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			fi
			while IFS='' read -r VARIANTOFINTEREST || [[ -n "$VARIANTOFINTEREST" ]]; do
				### EXAMPLE VARIANT LIST
				### rs12344 12 9029381
				### rs35467 4 171011538
				
				LINE=${VARIANTOFINTEREST}
				VARIANT=$(echo "${LINE}" | awk '{ print $1 }')
				VARIANTFORFILE=$(echo "${LINE}" | awk '{ print $1 }' | sed 's/\:/_/g')
				CHR=$(echo "${LINE}" | awk '{ print $2 }')
				BP=$(echo "${LINE}" | awk '{ print $3 }')
			
				echo "Analysing the phenotype [ ${PHENOTYPE} ] for [ ${VARIANT}: on chromosome ${CHR} ]."
				if [[ ${STANDARDIZE} = "STANDARDIZE" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -snpid ${VARIANT} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.sh
				elif [[ ${STANDARDIZE} = "RAW" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -use_raw_phenotypes -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -snpid ${VARIANT} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${VARIANTFORFILE}.chr${CHR}.sh
				else
					### If arguments are not met then this error message will be displayed
					script_arguments_error_normalization
				fi

			done < ${VARIANTLIST}
			
			echo ""
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
			### Create wrap-up bash-script to send to qsub
			echo "${GWASTOOLKITDIR}/gwastoolkit.wrapper.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			### Submit wrap-up script
			### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N AEGS_GWAS' are finished
			qsub -S /bin/bash -N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEM} -l ${QTIME} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			echo ""

		done
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		echo "Submit jobs to perform a regional analysis on your phenotype(s)..."
		### Run SNPTEST for each phenotype
		for PHENOTYPE in ${PHENOTYPES}; do
		### Make and/or set the output directory
			if [ ! -d ${OUTPUT_DIR}/${PHENOTYPE} ]; then
  				echo "The output directory does not exist. Making and setting it."
  				mkdir -v ${OUTPUT_DIR}/${PHENOTYPE}
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			else
  				echo "The output directory already exists. Setting it."
  				PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			fi
			echo "Analysing the phenotype [ ${PHENOTYPE} ] and all variants in the region [ chr${CHR}:${REGION_START}-${REGION_END} ]."
			if [[ ${STANDARDIZE} = "STANDARDIZE" ]]; then
				echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -range ${REGION_START}-${REGION_END} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.out " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.sh
				qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.sh
			elif [[ ${STANDARDIZE} = "RAW" ]]; then
				echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -use_raw_phenotypes -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -range ${REGION_START}-${REGION_END} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.out " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.sh
				qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.chr${CHR}_${REGION_START}_${REGION_END}.sh
			else
				### If arguments are not met then this error message will be displayed
				script_arguments_error_normalization
			fi
			
			echo ""
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
			### Create wrap-up bash-script to send to qsub
			echo "${GWASTOOLKITDIR}/gwastoolkit.wrapper.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			### Submit wrap-up script
			### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N AEGS_GWAS' are finished
 			qsub -S /bin/bash -N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE} -o ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEM} -l ${QTIME} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			echo ""

		done
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		echo "Submit jobs to perform a per gene analysis on your phenotype(s)..."
			
			echo ""
			if [ ! -f ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt ]; then
  				echo "${STUDY_TYPE}.regions_of_interest.txt does not exist. Making and setting it."
  				touch ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt
			else
  				echo "${STUDY_TYPE}.regions_of_interest.txt already exists; archiving it."
		  		mv -v ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt.bak
		  		touch ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt
			fi
			REGIONS=${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt
			while IFS= read -r GENEOFINTEREST || [[ -n "$GENEOFINTEREST" ]]; do
				for GENE in ${GENEOFINTEREST}; do 
					echo "* ${GENE} ± ${RANGE}"
					zcat ${HG19_GENES} | awk '$4=="'${GENE}'"' | awk '{ print $4, $1, ($2-'${RANGE}'), ($3+'${RANGE}') }' >> ${REGIONS}
				done
			done < ${GENES_FILE}

			echo ""
			echo "Analyzing this list of regions ± ${RANGE} basepairs: "
			cat ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt
			echo "Number of regions: "$(cat ${PROJECTDIR}/${PROJECTNAME}/${STUDY_TYPE}.regions_of_interest.txt | wc -l)
		
		echo ""
		### Run SNPTEST for each gene and phenotype
		while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
			LINE=${REGIONOFINTEREST}
			GENELOCUS=$(echo "${LINE}" | awk '{print $1}')
			CHR=$(echo "${LINE}" | awk '{print $2}')
			START=$(echo "${LINE}" | awk '{print $3}')
			END=$(echo "${LINE}" | awk '{print $4}')
			
			### Creating directory per gene
			if [ ! -d ${OUTPUT_DIR}/${GENELOCUS} ]; then
  				echo "The output directory does not exist. Making and setting it."
  				mkdir -v ${OUTPUT_DIR}/${GENELOCUS}
  				GENE_OUTPUT_DIR=${OUTPUT_DIR}/${GENELOCUS}
			else
  				echo "The output directory already exists. Setting it."
  				GENE_OUTPUT_DIR=${OUTPUT_DIR}/${GENELOCUS}
			fi
			for PHENOTYPE in ${PHENOTYPES}; do
				
				#### Creating directories per phenotype
				if [ ! -d ${GENE_OUTPUT_DIR}/${PHENOTYPE} ]; then
  					echo "The output directory does not exist. Making and setting it."
  					mkdir -v ${GENE_OUTPUT_DIR}/${PHENOTYPE}
  					PHENO_OUTPUT_DIR=${GENE_OUTPUT_DIR}/${PHENOTYPE}
				else
  					echo "The output directory already exists. Setting it."
  					PHENO_OUTPUT_DIR=${GENE_OUTPUT_DIR}/${PHENOTYPE}
				fi
				
				echo "Analysing the phenotype [ ${PHENOTYPE} ] and all variants on the [ ${GENELOCUS} locus on ${CHR}:${START}-${END} ]."
				
				if [[ ${STANDARDIZE} = "STANDARDIZE" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -range '${START}'-'${END}' -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
				elif [[ ${STANDARDIZE} = "RAW" ]]; then
					echo "${SNPTEST} -data ${IMPUTEDDATA}${CHR}.bgen ${SAMPLE_FILE} -pheno ${PHENOTYPE} -frequentist 1 -method ${METHOD} -use_raw_phenotypes -hwe -lower_sample_limit 10 -cov_names ${COVARIATES} -exclude_samples ${EXCLUSION_LIST} -range '${START}'-'${END}' -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.out -log ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.log " > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
					qsub -S /bin/bash -N ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE} -o ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.errors -l ${QMEM} -l ${QTIME} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
				else
					### If arguments are not met then this error message will be displayed
					script_arguments_error_normalization
				fi
				
				echo ""
				echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
				echo ""
				### Create wrap-up bash-script to send to qsub
				echo "${GWASTOOLKITDIR}/gwastoolkit.wrapper.sh ${CONFIGURATIONFILE} ${PHENOTYPE} ${GENELOCUS} " > ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
				### Submit wrap-up script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N ${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
				qsub -S /bin/bash -N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE} -hold_jid ${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE} -o ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.errors -l ${QMEM} -l ${QTIME} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/wrap_up.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENELOCUS}_${RANGE}.sh
				echo ""
				
			done
		done < ${REGIONS}
			
	else
		### If arguments are not met then this error message will be displayed 
		script_arguments_error_analysis_type
	fi
	echo "Man, oh man, I'm done with submitting! That was a lot..."
	echo ""
	echo ""
	echo "All finished. All qsubs submitted, results will be summarised in summary_results.txt.gz."
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message
