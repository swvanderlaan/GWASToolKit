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
	echoerror "An example command would be: gwastoolkit.qc.sh [arg1: path_to_configuration_file] [arg2: phenotype]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                         GWASTOOLKIT QUALITY CONTROL"
echobold "                                 quality control of SNPTEST analysis results"
echobold ""
echobold " Version    : v1.1.3"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by :  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold ""
echobold " Description: Quality control of a SNPTEST analysis: filter on INFO, MAC, CAF and BETA/SE."
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
PHENOTYPE="$2" # Depends on arg2

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply at least [2] arguments when performing quality control on *** GWASToolKit *** results!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1

	echo "The output directory is...................: ${OUTPUT_DIR}"
	echo "The phenotypes is.........................: ${PHENOTYPE}"
	echo "The minimum info-score filter is..........: ${INFO}"
	echo "The minimum minor allele count is.........: ${MAC}"
	echo "The minimum coded allele frequency is.....: ${CAF}"
	echo "The lower/upper limit of the BETA/SE is...: ${BETA_SE}"
	echo ""	
	# PLOT GWAS RESULTS
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                            STARTING QUALITY CONTROL"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	echo ""
	echo "Plotting reformatted FILTERED data."
	# what is the basename of the file?
	RESULTS=${OUTPUT_DIR}/*.summary_results.txt.gz
	echo ${RESULTS}
	FILENAME=$(basename ${RESULTS} .txt.gz)
	echo "The basename is: "${FILENAME}
	echo ""
	### COLUMN NAMES & NUMBERS
	###     1    2   3  4            5            6              7    8      9     10     11     12  13  14  15  16 17  18 19
	### ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE

	echo ""
	echo "Filtering data, using the following criteria: "
	echo "  * ${INFO} <= INFO < 1 "
	echo "  * CAF > ${CAF} "
	echo "  * MAC >= ${MAC} "
	echo "  * BETA/SE/P != NA "
	echo "  * -${BETA_SE} <= BETA/SE < ${BETA_SE}. "
	zcat ${RESULTS} | head -1 > ${OUTPUT_DIR}/${FILENAME}.QC.txt
	### COLUMN NAMES & NUMBERS
	###     1    2   3  4            5            6              7    8      9     10     11     12  13  14  15  16 17  18 19
	### ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE
	zcat ${OUTPUT_DIR}/${FILENAME}.txt.gz | awk '( $8 >= '${INFO}' && $8 < 1 && $13 >= '${MAC}' &&  $15 >= '${CAF}' && $17 != "NA" && $17 <= 1 && $17 >= 0 && $18 != "NA" && $18 < '${BETA_SE}' && $18 > -'${BETA_SE}' && $19 != "NA" && $19 < '${BETA_SE}' && $19 > -'${BETA_SE}' )' >> ${OUTPUT_DIR}/${FILENAME}.QC.txt
	echo "Number of QC'd variants:"
	cat ${OUTPUT_DIR}/${FILENAME}.QC.txt | wc -l
	echo "Head of QC'd file:"
	head ${OUTPUT_DIR}/${FILENAME}.QC.txt
	echo ""
	echo "Tail of QC'd file:"
	tail ${OUTPUT_DIR}/${FILENAME}.QC.txt
	echo ""
	echo ""
	echo "Zipping up..."
	gzip -v ${OUTPUT_DIR}/${FILENAME}.QC.txt
	echo ""
	echo ""

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message