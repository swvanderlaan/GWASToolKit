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
	echoerror ""
	echoerror "An example command would be: gwastoolkit.regenie.qc.sh [arg1: path_to_configuration_file]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                         GWASTOOLKIT QUALITY CONTROL for REGENIE"
echobold "                                 quality control of REGENIE analysis results"
echobold ""
echobold " Version    : v1.0.0"
echobold ""
echobold " Last update: 2024-08-29"
echobold " Written by :  Tim S. Peters (t.s.peters-4@umcutrecht.nl)."
echobold ""
echobold " Testers:     - "
echobold ""
echobold " Description: Quality control of a REGENIE analysis:"
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

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 1 ]]; then
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [1] argument for cleaning of *** GENOME-WIDE ANALYSIS *** results!"
	script_copyright_message

else
	### Make and/or set the output directory
	if [ ! -d ${PROJECTDIR}/${PROJECTNAME}/regenie_results ]; then
		echo "The output directory does not exist. Making and setting it."
		mkdir -v ${PROJECTDIR}/${PROJECTNAME}/regenie_results
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/regenie_results
	else
		echo "The output directory already exists. Setting it."
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/regenie_results
	fi

	if [ ! -d ${OUTPUT_DIR}/pre_processing ]; then
		echo "The QC output directory does not exist. Making and setting it."
		mkdir -v ${OUTPUT_DIR}/pre_processing
		QC_OUTPUT_DIR=${OUTPUT_DIR}/pre_processing
	else
		echo "The QC output directory already exists. Setting it."
		QC_OUTPUT_DIR=${OUTPUT_DIR}/pre_processing
	fi

	echo "All arguments are passed. These are the settings:"
	echo "The output directory is...................: ${OUTPUT_DIR}"
	echo "The call rate filter is...................: ${REGENIE_CALL_RATE}"
	echo "The minimum minor allele frequency is.....: ${REGENIE_MAF}"
	echo "The minimum HWE p-value is................: ${REGENIE_HWE}"
	echo "The filter for independent SNPs is........: ${REGENIE_PRUNE}"
	echo ""
	# PLOT GWAS RESULTS
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                            STARTING QUALITY CONTROL"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	echo ""
	echo "First, get a list of A/T and C/G SNPs, to exclude later:"
	cat ${IMPUTEDDATA_ALLCHR}.pvar | \
	awk '($4 == "A" && $5 == "T") || ($4 == "T" && $5 == "A") || ($4 == "C" && $5 == "G") || ($4 == "G" && $5 == "C")' | \
	awk '{ print $3, $1, $2, 0, $4, $5 }' > ${QC_OUTPUT_DIR}/all.atcg.variants.txt
	echo ""
	echo ""
	echo "Second, filtering data, using the following criteria: "
	echo "  * CALL RATE < ${REGENIE_CALL_RATE}"
	echo "  * MAF >= ${REGENIE_MAF}"
	echo "  * HWE <= ${REGENIE_HWE}"
	echo "  * indep_pairwise ${REGENIE_PRUNE}"
	$PLINK2 --pfile ${IMPUTEDDATA_ALLCHR} \
	--autosome \
	--maf ${REGENIE_MAF} --geno ${REGENIE_CALL_RATE} --hwe ${REGENIE_HWE} \
	--exclude-if-info "R2>0.99" \
	--indep-pairwise ${REGENIE_PRUNE}\
	--exclude range ${EXCLUDE_RANGE_FILE} \
	--make-pgen --out ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.temp
	echo ""
	echo ""
	echo "Third, prune out unwanted SNPs in high LD."
	$PLINK2 --pfile ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.temp \
	--extract ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.temp.prune.in \
	--make-pgen --out ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.ultraclean.temp
	echo ""
	echo ""
	echo "Fourth, remove the A/T and C/G SNPs."
	$PLINK2 --pfile ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.ultraclean.temp \
	--exclude ${QC_OUTPUT_DIR}/all.atcg.variants.txt \
	--write-snplist --write-samples --no-id-header \
	--make-pgen --out ${QC_OUTPUT_DIR}/aegscombo_topmed_r3_f10_b38.allChrs.QC
	echo ""
	echo ""
	echo "Finishing up..."
	rm -fv ${QC_OUTPUT_DIR}/*.temp*
	echo ""
	echo ""
### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message
