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
	echoerror ""
	echoerror "- Argument #1 is path_to the configuration file."
	echoerror "- Argument #2 is the phenotype analysed."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.wrapper.sh [arg1: path_to_configuration_file] [arg2: phenotype]"
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
echobold "                                          GWASTOOLKIT WRAPPER"
echobold "                                  WRAPPING UP SNPTEST ANALYSIS RESULTS"
echobold ""
echobold " Version    : v1.2.3"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold "              - Jacco Schaap (j.schaap-2@umcutrecht.nl)"
echobold "              - Tim Bezemer (t.bezemer-2@umcutrecht.nl)"
echobold ""
echobold " Description: Wrapping up all files from a SNPTEST analysis into one file for ease "
echobold "              of downstream (R) analyses."
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
PHENOTYPE="$2" # Depends on arg2

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 2 ]]; then 
	echoerror "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply at least [2] arguments when wrapping up *** GWASToolKit *** analyses results!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
	
	echo "The output directory is.....................................: ${OUTPUT_DIR}"
	echo "The following dataset will be used..........................: ${STUDY_TYPE}"
	echo "The following analysis type will be run.....................: ${ANALYSIS_TYPE}"
	echo "The reference used..........................................: ${REFERENCE}"
	echo "The following phenotype was analysed and is wrapped up......: ${PHENOTYPE}"
	
	### Starting of the script
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                WRAPPING UP SNPTEST ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""

	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		# create results file
		###   1     2    3   4  5            6            7              8    9      10     11     12     CALC 13 CALC 14 15  16 17 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt

		for CHR in $(seq 1 22) X; do
			# which chromosome are we processing?
			echo "Processing chromosome ${CHR}..."
			cat ${OUTPUT_DIR}/*.chr${CHR}.out | grep -v "#" | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col alternate_ids,rsid,chromosome,position,alleleA,alleleB,average_maximum_posterior_call,info,cohort_1_AA,cohort_1_AB,cohort_1_BB,all_total,all_maf,cohort_1_hwe,frequentist_add_pvalue,frequentist_add_beta_1,frequentist_add_se_1 | 
			tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, (2*$12*$13), $13, (((2*$11)+$10)/(2*$12)), $14, $15, $16, $17 } ' >> ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
		done
		
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" || ${ANALYSIS_TYPE} = "GENES" ]]; then
		# create results file
		###   1     2    3   4  5            6            7              8    9      10     11     12     CALC 13 CALC 14 15  16 17 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt

		for FILE in $(ls ${OUTPUT_DIR}/*.out); do
			# which file are we processing?
			echo "Processing file ${FILE}..."
			cat ${FILE} | grep -v "#" | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col alternate_ids,rsid,chromosome,position,alleleA,alleleB,average_maximum_posterior_call,info,cohort_1_AA,cohort_1_AB,cohort_1_BB,all_total,all_maf,cohort_1_hwe,frequentist_add_pvalue,frequentist_add_beta_1,frequentist_add_se_1 | 
			tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, (2*$12*$13), $13, (((2*$11)+$10)/(2*$12)), $14, $15, $16, $17 } ' >> ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
		done
		
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		echo "NOT AN OPTION YET!"
	
	else
		### If arguments are not met then this error message will be displayed 
		script_arguments_error_analysis_type
	fi
	
	echo ""
	gzip -vf ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt
	echo ""
	echo "Finished. "
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi
script_copyright_message

	### HEADER of SNPTEST output-file
	###	SEMI-QUANTITATIVE/BINARY			QUANTITATIVE
	### 1	alternate_ids 					1  alternate_ids
	### 2	rsid  							2  rsid
	### 3	chromosome  					3  chromosome
	### 4	position  						4  position
	### 5	alleleA  						5  alleleA
	### 6	alleleB  						6  alleleB
	### 7	index  							7  index
	### 8	average_maximum_posterior_call 	8  average_maximum_posterior_call
	### 9	info  							9  info
	### 10	cohort_1_AA  					10 cohort_1_AA
	### 11	cohort_1_AB  					11 cohort_1_AB
	### 12	cohort_1_BB  					12 cohort_1_BB
	### 13	cohort_1_NULL  					13 cohort_1_NULL
	### 14	all_AA  						14 all_AA
	### 15	all_AB  						15 all_AB
	### 16	all_BB  						16 all_BB
	### 17	all_NULL  						17 all_NULL
	### 18	all_total  						18 all_total
	### 19	cases_AA  						19 all_maf
	### 20	cases_AB  						20 missing_data_proportion
	### 21	cases_BB  						21 cohort_1_hwe
	### 22	cases_NULL  					22 frequentist_add_pvalue
	### 23	cases_total  					23 frequentist_add_info
	### 24	controls_AA  					24 frequentist_add_beta_1
	### 25	controls_AB  					25 frequentist_add_se_1
	### 26	controls_BB  					26 comment
	### 27	controls_NULL
	### 28	controls_total
	### 29	all_maf
	### 30	cases_maf
	### 31	controls_maf
	### 32	missing_data_proportion
	### 33	cohort_1_hwe
	### 34	cases_hwe
	### 35	controls_hwe
	### 36	het_OR
	### 37	het_OR_lower
	### 38	het_OR_upper
	### 39	hom_OR
	### 40	hom_OR_lower
	### 41	hom_OR_upper
	### 42	all_OR
	### 43	all_OR_lower
	### 44	all_OR_upper
	### 45	frequentist_add_pvalue
	### 46	frequentist_add_info
	### 47	frequentist_add_beta_1
	### 48	frequentist_add_se_1
	### 49	comment
	###

