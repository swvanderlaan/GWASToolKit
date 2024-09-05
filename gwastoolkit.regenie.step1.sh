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
	echo "+ Copyright (c) 2015-${THISYEAR} Tim S. Peters                                                          +"
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
	echoerror ""
	echoerror "- Argument #1 is path_to the configuration file."
	echoerror "- Argument #2 is determining whether to run regenie for BINARY or QUANTATIVE traits."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.regenie.step1.sh [arg1: path_to_configuration_file] [args2: BINARY/QUANTATIVE]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                         GWASTOOLKIT REGENIE STEP 1"
echobold "                                         step 1 of REGENIE analysis"
echobold ""
echobold " Version    : v1.0.0"
echobold ""
echobold " Last update: 2024-08-29"
echobold " Written by :  Tim S. Peters (t.s.peters-4@umcutrecht.nl)."
echobold ""
echobold " Testers:     - "
echobold ""
echobold " Description: First step of GWAS using Regenie:"
echobold " Filter on:	- autosome snps"
echobold " 				- MAF"
echobold " 				- MAC"
echobold " 				- call rate"
echobold " 				- Hardy-Weinberg Equilibrium (HWE) p-value"
echobold " 				- LD r^2"
echobold " 				- exclude problamatic SNPs in long-range LD regions"
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
TRAIT_TYPE="$2" # Depends on arg1 -- but also on where it resides!!!

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 2 ]]; then
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments for cleaning of *** GENOME-WIDE ANALYSIS *** results!"
	script_copyright_message

else
	if [[ "${TRAIT_TYPE}" != 'BINARY' && "${TRAIT_TYPE}" != 'QUANTATIVE' ]]; then
		echo "Oh, computer says no! Second argument is not correct"
		script_arguments_error "Argument 2 should be either 'BINARY' or 'QUANTATIVE'!"
		script_copyright_message
		exit 1
	fi
	echo ""
	echo ""
	### Make and/or set the output directory
	if [ ! -d ${PROJECTDIR}/${PROJECTNAME}/regenie_results ]; then
		echo "The output directory does not exist. Making and setting it."
		mkdir -v ${PROJECTDIR}/${PROJECTNAME}/regenie_results
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/regenie_results
	else
		echo "The output directory already exists. Setting it."
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/regenie_results
	fi
	echo ""

	if [ ! -d ${OUTPUT_DIR}/pre_processing ]; then
		echo "The QC output directory does not exist. Making and setting it."
		echo "Something probably went wrong in the QC step."
		exit 1
	else
		echo "The QC output directory exists. Setting it."
		QC_OUTPUT_DIR=${OUTPUT_DIR}/pre_processing
	fi
	echo ""

	if [ "${TRAIT_TYPE}" == 'QUANTATIVE' ]; then
		echo "* Running REGENIE for QUANTATIVE traits"
		if [ ! -d ${OUTPUT_DIR}/regenie_QT_step1 ]; then
			echo "The Regenie Quantative traits step1 output directory does not exist. Making and setting it."
			mkdir -v ${OUTPUT_DIR}/regenie_QT_step1
			STEP1_QT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_QT_step1
		else
			echo "The Regenie Quantative traits step1 output directory already exists. Setting it."
			STEP1_QT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_QT_step1
		fi
		echo ""
	fi

	if [ "${TRAIT_TYPE}" == 'BINARY' ]; then
		echo "* Running REGENIE for BINARY traits"
		if [ ! -d ${OUTPUT_DIR}/regenie_BT_step1 ]; then
			echo "The Regenie Binary traits step1 output directory does not exist. Making and setting it."
			mkdir -v ${OUTPUT_DIR}/regenie_BT_step1
			STEP1_BT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_BT_step1
		else
			echo "The Regenie Binary traits step1 output directory already exists. Setting it."
			STEP1_BT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_BT_step1
		fi
		echo ""
	fi

	if [ ! -d ${OUTPUT_DIR}/tmp_dir ]; then
		echo "The temporary directory does not exist. Making and setting it."
		mkdir -v ${OUTPUT_DIR}/tmp_dir
		TMP_OUTPUT_DIR=${OUTPUT_DIR}/tmp_dir
	else
		echo "The temporary directory already exists. Setting it."
		TMP_OUTPUT_DIR=${OUTPUT_DIR}/tmp_dir
	fi
	echo ""
	echo ""

	if [ "${TRAIT_TYPE}" == 'QUANTATIVE' ]; then	
		echo "All arguments are passed. These are the settings:"
		echo "  * SAMPLE FILE: 				${SAMPLE_FILE}"
		echo "  * QUANTATIVE COVARIATES: 	${COVARIATE_QUANTATIVE}"
		echo "  * BINARY COVARIATES: 		${COVARIATE_BINARY}"
		echo "  * QUANTATIVE PHENOTYPE: 	${PHENOTYPE_QUANTATIVE}"
		echo "  * BINARY PHENOTYPE: 		-NOT USED-"
		echo ""
		echo "  * BLOCK SIZE: 				${REGENIE_STEP1_BZISE}"
		echo ""
		echo ""
		echo "Start processing REGENIE step 1 for QUANTATIVE traits"
		echo ""
		$REGENIE \
		--step 1 \
		--pgen ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC \
		--extract ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC.snplist \
		--keep ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC.id \
		--covarFile ${SAMPLE_FILE} \
		--covarColList ${COVARIATE_QUANTATIVE} \
		--catCovarList ${COVARIATE_BINARY} \
		--phenoFile ${SAMPLE_FILE} \
		--phenoColList ${PHENOTYPE_QUANTATIVE} \
		--bsize="${REGENIE_STEP1_BZISE}" \
		--lowmem \
		--lowmem-prefix ${TMP_OUTPUT_DIR}/regenie_tmp_qt_preds \
		--out ${STEP1_QT_OUTPUT_DIR}/aegscombo_topmed_step1
		
	elif [ "${TRAIT_TYPE}" == 'BINARY' ]; then
		echo "All arguments are passed. These are the settings:"
		echo "  * SAMPLE FILE: 				${SAMPLE_FILE}"
		echo "  * QUANTATIVE COVARIATES: 	${COVARIATE_QUANTATIVE}"
		echo "  * BINARY COVARIATES: 		${COVARIATE_BINARY}"
		echo "  * QUANTATIVE PHENOTYPE: 	-NOT USED-"
		echo "  * BINARY PHENOTYPE: 		${PHENOTYPE_BINARY}"
		echo ""
		echo "  * BLOCK SIZE: 				${REGENIE_STEP1_BZISE}"
		echo ""
		echo ""
		echo "Start processing REGENIE step 1 for BINARY traits"
		echo ""
		$REGENIE \
		--step 1 \
		--pgen ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC \
		--extract ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC.snplist \
		--keep ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC.id \
		--covarFile ${SAMPLE_FILE} \
		--covarColList ${COVARIATE_QUANTATIVE} \
		--catCovarList ${COVARIATE_BINARY} \
		--phenoFile ${SAMPLE_FILE} \
		--phenoColList ${PHENOTYPE_BINARY} \
		--bsize="${REGENIE_STEP1_BZISE}" \
		--lowmem --bt \
		--lowmem-prefix ${TMP_OUTPUT_DIR}/regenie_tmp_bt_preds \
		--out ${STEP1_BT_OUTPUT_DIR}/aegscombo_topmed_step1
	fi

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message
