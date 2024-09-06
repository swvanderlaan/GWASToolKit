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
	echoerror "An example command would be: gwastoolkit.regenie.step2.sh [arg1: path_to_configuration_file] [args2: BINARY/QUANTATIVE]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                         GWASTOOLKIT REGENIE WRAPPER"
echobold "                                         Wrapup of REGENIE analysis"
echobold ""
echobold " Version    : v1.0.0"
echobold ""
echobold " Last update: 2024-08-29"
echobold " Written by :  Tim S. Peters (t.s.peters-4@umcutrecht.nl)."
echobold ""
echobold " Testers:     - "
echobold ""
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

	if [ "${TRAIT_TYPE}" == 'QUANTATIVE' ]; then
		echo "* Running REGENIE for QUANTATIVE traits"
		if [ ! -d ${OUTPUT_DIR}/regenie_QT_step2 ]; then
			script_arguments_error "Regenie step 2 does not seem to be executed or the directory could not be found!"
			script_copyright_message
			exit 1
		else
			echo "The Regenie Quantative traits step2 output directory already exists. Setting it."
			STEP2_QT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_QT_step2
		fi
		echo ""
	fi

	if [ "${TRAIT_TYPE}" == 'BINARY' ]; then
		echo "* Running REGENIE for BINARY traits"
		if [ ! -d ${OUTPUT_DIR}/regenie_BT_step2 ]; then
			script_arguments_error "Regenie step 2 does not seem to be executed or the directory could not be found!"
			script_copyright_message
			exit 1
		else
			echo "The Regenie Binary traits step2 output directory already exists. Setting it."
			STEP2_BT_OUTPUT_DIR=${OUTPUT_DIR}/regenie_BT_step2
		fi
		echo ""
	fi

	if [ ! -d ${OUTPUT_DIR}/regenie_OUT ]; then
		echo "The Regenie output directory does not exist. Making and setting it."
		mkdir -v ${OUTPUT_DIR}/regenie_OUT
		REGENIE_FINAL_DIR=${OUTPUT_DIR}/regenie_OUT
	else
		echo "The Regenie output directory already exists. Setting it."
		REGENIE_FINAL_DIR=${OUTPUT_DIR}/regenie_OUT
	fi
	echo ""
	echo ""

	# Save the current IFS
	OLD_IFS=$IFS

	if [ "${TRAIT_TYPE}" == 'QUANTATIVE' ]; then	
		echo "All arguments are passed. These are the settings:"
		echo "  * SAMPLE FILE: 				${SAMPLE_FILE}"
		echo "  * QUANTATIVE COVARIATES: 	${COVARIATE_QUANTATIVE}"
		echo "  * BINARY COVARIATES: 		${COVARIATE_BINARY}"
		echo "  * QUANTATIVE PHENOTYPE: 	${PHENOTYPE_QUANTATIVE}"
		echo "  * BINARY PHENOTYPE: 		-NOT USED-"
		echo ""
		echo "  * BLOCK SIZE: 				${REGENIE_STEP2_BZISE}"
		echo ""
		echo ""
		echo "Start processing REGENIE step 2 for QUANTATIVE traits"
		echo ""
		
		IFS=','  # Set comma as the delimiter
		for PHENOTYPE_ITEM in $PHENOTYPE_QUANTATIVE; do
			echo "Wrapping up for QUANTATIVE PHENOTYPE: ${PHENOTYPE_ITEM}"
			# create results file
			###      1     2    3   4  5            6            7              8    9      10     11     12     CALC 13 CALC 14 15  16 17 # AUTOSOMAL & X CHROMOSOMES
			# echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.txt
			echo "CHROM GENPOS ID ALLELE0 ALLELE1 A1FREQ N TEST BETA SE CHISQ LOG10P EXTRA" > ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt

			# Reset IFS to its original value
    		IFS=$OLD_IFS
			for CHR in $(seq 1 22); do
				# which chromosome are we processing?
				echo "Processing chromosome ${CHR}..."
				cat ${STEP2_QT_OUTPUT_DIR}/*.chr${CHR}_${PHENOTYPE_ITEM}.regenie | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13 } ' >> ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt
				echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
				echo ""
			done
			echo ""
			gzip -vf ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt
		done
		
	elif [ "${TRAIT_TYPE}" == 'BINARY' ]; then
		echo "All arguments are passed. These are the settings:"
		echo "  * SAMPLE FILE: 				${SAMPLE_FILE}"
		echo "  * QUANTATIVE COVARIATES: 	${COVARIATE_QUANTATIVE}"
		echo "  * BINARY COVARIATES: 		${COVARIATE_BINARY}"
		echo "  * QUANTATIVE PHENOTYPE: 	-NOT USED-"
		echo "  * BINARY PHENOTYPE: 		${PHENOTYPE_BINARY}"
		echo ""
		echo "  * BLOCK SIZE: 				${REGENIE_STEP2_BZISE}"
		echo ""
		echo ""
		echo "Start processing REGENIE step 2 for BINARY traits"
		echo ""
		
		IFS=','  # Set comma as the delimiter
		for PHENOTYPE_ITEM in $PHENOTYPE_BINARY; do
			echo "Wrapping up for BINARY PHENOTYPE: ${PHENOTYPE_ITEM}"
			# create results file
			###      1     2    3   4  5            6            7              8    9      10     11     12     CALC 13 CALC 14 15  16 17 # AUTOSOMAL & X CHROMOSOMES
			# echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.txt
			echo "CHROM GENPOS ID ALLELE0 ALLELE1 A1FREQ N TEST BETA SE CHISQ LOG10P EXTRA" > ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt

			# Reset IFS to its original value
    		IFS=$OLD_IFS
			for CHR in $(seq 1 22); do
				# which chromosome are we processing?
				echo "Processing chromosome ${CHR}..."
				cat ${STEP2_BT_OUTPUT_DIR}/*.chr${CHR}_${PHENOTYPE_ITEM}.regenie | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13 } ' >> ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt
				echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
				echo ""
			done
			echo ""
			gzip -vf ${REGENIE_FINAL_DIR}/regenie.${PHENOTYPE_ITEM}.summary_results.txt
		done
	fi

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message
