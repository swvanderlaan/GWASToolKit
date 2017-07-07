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
	echoerror "An example command would be: gwastoolkit.clumper.sh [arg1: path_to_configuration_file] [arg2: phenotype]"
	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                          GWASTOOLKIT CLUMPER"
echobold "                                  clumping of SNPTEST analysis results"
echobold ""
echobold " Version    : v1.2.5"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold ""
echobold " Description: Clumping of a genome-wide SNPTEST analysis."
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
	script_arguments_error "You must supply at least [2] arguments when clumping a *** GENOME-WIDE ANALYSIS ***!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1

	echo ""
	echo "The output directory is.................................................: ${OUTPUT_DIR}"
	echo "The phenotype to clump for is...........................................: ${PHENOTYPE}"
	echo "We will use the following reference.....................................: ${REFERENCE}"
	echo "The following dataset will be used......................................: ${STUDY_TYPE}"
	echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
	echo "Maximum (largest) p-value to clump......................................: ${CLUMP_P2}"
	echo "Minimum (smallest) p-value to clump.....................................: ${CLUMP_P1}"
	echo "R^2 to use for clumping.................................................: ${CLUMP_R2}"
	echo "The KB range used for clumping..........................................: ${CLUMP_KB}"
	echo "Indicate the name of the clumping field to use (default: p-value, P)....: ${CLUMP_FIELD}"
	echo ""
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Preparing clumping of genome-wide analysis results using the P-values."	
	# what is the basename of the file?
	RESULTS=${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.txt.gz
	FILENAME=$(basename ${RESULTS} .txt.gz)
	echo "The basename is: [ ${FILENAME} ]."
	echo ""
	echo "Un-Gzipping the results for clumping..."
	gzip -dv ${OUTPUT_DIR}/${FILENAME}.txt.gz
	echo "Clumping..."
	echo "The reference is ${REFERENCE}."

	$PLINK2 --bfile ${REFERENCEDATA} --memory 168960 --clump ${OUTPUT_DIR}/${FILENAME}.txt --clump-snp-field "RSID" --clump-p1 ${CLUMP_P1} --clump-p2 ${CLUMP_P2} --clump-r2 ${CLUMP_R2} --clump-kb ${CLUMP_KB} --clump-field ${CLUMP_FIELD} --out ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.clumped --clump-verbose --clump-annotate CodedAlleleB,OtherAlleleA,CAF,MAF,MAC,HWE,AvgMaxPostCall,Info,BETA,SE 
		
	echo "Done clumping; gzipping the results for [ ${FILENAME} ]..."
	gzip -v ${OUTPUT_DIR}/${FILENAME}.txt
	echo ""
	
	echo "After clumping, pull out the index variants..."
	grep "INDEX" ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.clumped.clumped | awk ' { print $2 } ' > ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.indexvariants.txt
	echo "Number of index variants..." 
	cat ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.indexvariants.txt | wc -l
	
	echo ""
	echo "Copying to a working file..."
	cp -v ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.indexvariants.txt ${OUTPUT_DIR}/${FILENAME}.clumped_hits.txt.foo
	echo ""
	
	echo "Counting the total of number of index variants to look at."
	cat ${OUTPUT_DIR}/${FILENAME}.clumped_hits.txt.foo | wc -l
	cat ${OUTPUT_DIR}/${FILENAME}.clumped_hits.txt.foo | sort -u > ${OUTPUT_DIR}/${FILENAME}.clumped_hits.txt
	#rm -v ${OUTPUT_DIR}/${FILENAME}.clumped_hits.txt.foo
	echo ""
	
	echo "Making a list of TOP-variants based on p < ${CLUMP_P1}."
	zcat ${OUTPUT_DIR}/${FILENAME}.txt.gz | awk '$1=="ALTID" || $17<='${CLUMP_P1}'' > ${OUTPUT_DIR}/${FILENAME}.TOP_based_on_p${CLUMP_P1}.txt
	echo ""
	
### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message