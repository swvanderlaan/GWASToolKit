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
	echoerror "- Argument #3 is the gene analysed -- gene-based analysis only."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.cleaner.sh [arg1: path_to_configuration_file] [arg2: phenotype] [arg3: gene]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                           GWASTOOLKIT CLEANER"
echobold "                                   cleaning of SNPTEST analysis results"
echobold ""
echobold " Version    : v1.2.3"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold "              - Jacco Schaap (j.schaap-2@umcutrecht.nl)"
echobold "              - Tim Bezemer (t.bezemer-2@umcutrecht.nl)"
echobold ""
echobold " Description: Cleaning up all files from a SNPTEST analysis into one file for ease "
echobold "              of downstream (R) analyses."
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
PHENOTYPE="$2" # Depends on arg2

### START of if-else statement for the number of command-line arguments passed ###
if [[ ${ANALYSIS_TYPE} = "GWAS" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments for cleaning of *** GENOME-WIDE ANALYSIS *** results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "VARIANT" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments for cleaning of *** VARIANT ANALYSIS *** results!"
	script_copyright_message

elif [[ ${ANALYSIS_TYPE} = "REGION" && $# -lt 3 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments for cleaning of *** REGIONAL ANALYSIS *** results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "GENES" && $# -lt 3 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [3] arguments for cleaning of *** GENE ANALYSIS *** results!"
	script_copyright_message

else
	
	echo "All arguments are passed. These are the settings:"
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then 
		### SET INPUT-DATA
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
	
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then 
		### SET INPUT-DATA
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
	
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then 
		### SET INPUT-DATA
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
		
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then 
		### SET INPUT-DATA
		GENE="$3"
		OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${GENE}/${PHENOTYPE} # depends on arg1
	else
		echo "Oh, computer says no! Number of arguments found "$#"."
		script_arguments_error "You must supply [2-3] arguments for cleaning of *** GWASToolKit *** results!"
		script_copyright_message
	fi
	
	echo "The following analysis type will be run.....................: ${ANALYSIS_TYPE}"
	echo "The following dataset will be used..........................: ${STUDY_TYPE}"
	echo "The reference used..........................................: ${REFERENCE}"
	echo "The exclusion criterium used................................: ${EXCLUSION}"
	echo "The output directory is.....................................: ${OUTPUT_DIR}"
	echo "The following phenotype was analysed and is wrapped up......: ${PHENOTYPE}"
	
	### Starting of the script
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                CLEANING UP SNPTEST ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	
	echo "Moving scripts and logs..."
	mkdir -v ${OUTPUT_DIR}/_scriptlogs
	mv -v ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.*.sh ${OUTPUT_DIR}/_scriptlogs/
	mv -v ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.*.log ${OUTPUT_DIR}/_scriptlogs/
	echo ""
	echo "Moving raw results..."
	mkdir -v ${OUTPUT_DIR}/_rawresults
	mv -v ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.*.out ${OUTPUT_DIR}/_rawresults/
	echo ""
	echo "Gzipping logs and raw results..."
	gzip -v ${OUTPUT_DIR}/_scriptlogs/*.log
	gzip -v ${OUTPUT_DIR}/_rawresults/*.out
	echo ""
	echo "Checking errors-files and zapping them if empty..."
	if [[ -s ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.*.errors ]]; then
		echo "* ERROR FILE NOT EMPTY: The error file has some data. We'll keep it there for review."
	else
		echo "The error file is empty."
	    rm -v ${OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.*.errors
	fi
	
	echo ""
	echo "All cleaned up."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message