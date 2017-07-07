#!/bin/bash

# to do: add in readme functionality, text file with summary results and explanation of things
# to do: make argument parsing depending on ${ANALYSIS_TYPE}
# to do: add in gzipping functionality of 'summary' directory and its readme

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
	echoerror "An example command would be: summariser.sh [arg1: path_to_configuration_file] [arg2: phenotype]"
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
echobold "                                             GWASTOOLKIT SUMMARISER"
echobold "                                          SUMMARISES ANALYSIS RESULTS"
echobold ""
echobold " Version    : v1.3.2"
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
echobold " Description: Summarises analysis results and zips up into one directory."
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
PHENOTYPES=$(cat ${PHENOTYPE_FILE}) # which phenotypes to investigate anyway

### START of if-else statement for the number of command-line arguments passed ###
if [[ ${ANALYSIS_TYPE} = "GWAS" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments when summarising *** GWASToolKit *** [ ${ANALYSIS_TYPE} ] analyses results!"
	script_copyright_message

elif [[ ${ANALYSIS_TYPE} = "VARIANT" && $# -lt 1 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [1] arguments when summarising *** GWASToolKit *** [ ${ANALYSIS_TYPE} ] analyses results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "REGION" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments when summarising *** GWASToolKit *** [ ${ANALYSIS_TYPE} ] analyses results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "GENES" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments when summarising *** GWASToolKit *** [ ${ANALYSIS_TYPE} ] analyses results!"
	script_copyright_message

else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results # depends on arg1
	
	echo "The following analysis type will be run.....................: ${ANALYSIS_TYPE}"
	echo "The following dataset will be used..........................: ${STUDY_TYPE}"
	echo "The reference used..........................................: ${REFERENCE}"
	echo "The output directory is.....................................: ${OUTPUT_DIR}"
	echo "The project directory is....................................: ${PROJECTDIR}"
	echo "The analysis will be run using the following phenotypes.....: "
		for PHENOTYPE in ${PHENOTYPES}; do
			echo "     * ${PHENOTYPE}"
		done
	### Starting of the script
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                          STARTING SUMMARISATION"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		echo "*** NOT IMPLEMENTED YET ***"
		
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
	
		if [[ ! -d ${PROJECTDIR}/${PROJECTNAME}/summary.${ANALYSIS_TYPE} ]]; then
			echo "Summary directory doesn't exist: making it."
			mkdir -v ${PROJECTDIR}/${PROJECTNAME}/summary.${ANALYSIS_TYPE}
			SUMMARY=${PROJECTDIR}/${PROJECTNAME}/summary.${ANALYSIS_TYPE}
		else
			echo "Summary directory does exist."
			SUMMARY=${PROJECTDIR}/${PROJECTNAME}/summary.${ANALYSIS_TYPE}
		fi
		echo ""
	
		echo "Summarising data..."
		echo "Phenotype ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.summary.txt

		for PHENOTYPE in ${PHENOTYPES}; do
		PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			echo "* Copying results for [ ${PHENOTYPE} ]..."
			cp -fv ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz ${SUMMARY}/
		
			echo ""
			echo "* Concatenating results for [ ${PHENOTYPE} ]..."
			zcat ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz | tail -n +2 | awk -v PHENOTYPE_RESULT=${PHENOTYPE} '{ print PHENOTYPE_RESULT, $0 }' OFS=" "  >> ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.summary.txt
				
		done
		echo " * Gzipping the summarised data..."
		gzip -fv ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.summary.txt

 	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		echo "*** NOT IMPLEMENTED YET ***"
	
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
 		GENE="$2"
 		
 		if [[ ! -d ${PROJECTDIR}/${PROJECTNAME}/summary.${GENE} ]]; then
			echo "Summary directory doesn't exist: making it."
			mkdir -v ${PROJECTDIR}/${PROJECTNAME}/summary.${GENE}
			SUMMARY=${PROJECTDIR}/${PROJECTNAME}/summary.${GENE}
		else
			echo "Summary directory does exist."
			SUMMARY=${PROJECTDIR}/${PROJECTNAME}/summary.${GENE}
		fi
		echo ""
		
		echo "Summarising data..."
		echo "Phenotype ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${GENE}.summary.txt

		for PHENOTYPE in ${PHENOTYPES}; do
		PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			echo "* Copying results for [ ${PHENOTYPE} ]..."
			cp -fv ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz ${SUMMARY}/
		
			echo ""
			echo "* Concatenating results for [ ${PHENOTYPE} ]..."
			zcat ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz | tail -n +2 | awk -v PHENOTYPE_RESULT=${PHENOTYPE} '{ print PHENOTYPE_RESULT, $0 }' OFS=" "  >> ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${GENE}.summary.txt
		
			echo "* Copying LocusZoom plots for [ ${PHENOTYPE} ]..."
			cp -fv ${PHENO_OUTPUT_DIR}/locuszoom/*_${GENE}/*.pdf ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${GENE}.LocusZoom.pdf
		
		done
		echo " * Gzipping the summarised data..."
		gzip -fv ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${GENE}.summary.txt
		
 	else
		### If arguments are not met then this error message will be displayed 
		script_arguments_error_analysis_type
	fi
 	
	echo ""
	echo "All summarised."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message