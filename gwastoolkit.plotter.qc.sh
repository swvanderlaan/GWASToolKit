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
	echoerror "An example command would be: gwastoolkit.plotter.qc.sh [arg1: path_to_configuration_file] [arg2: phenotype]"
  	echoerror ""
  	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                          GWASTOOLKIT PLOTTER -- AFTER QC"
echobold "                              plotting of SNPTEST analysis results after quality control"
echobold ""
echobold " Version    : v1.1.4"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold ""
echobold " Description: Plotting of a SNPTEST analysis: making Manhattan, and QQ plots of"
echobold "              the filtered data."
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
	script_arguments_error "You must supply at least [2] arguments when plotting *** GWASToolKit *** results!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
	
	echo "The output directory is...................: ${OUTPUT_DIR}"
	echo "The phenotypes is.........................: ${PHENOTYPE}"
	echo ""	
	# PLOT GWAS RESULTS
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                    PLOTTING SNPTEST ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	SCRIPTS=${GWASTOOLKITDIR}/SCRIPTS
	echo ""
	echo "Plotting reformatted FILTERED data."
	# what is the basename of the file?
	RESULTS=${OUTPUT_DIR}/*.summary_results.QC.txt.gz
	FILENAME=$(basename ${RESULTS} .txt.gz)
	echo "The basename is: "${FILENAME}
	echo ""
	### COLUMN NAMES & NUMBERS
	###     1    2   3  4            5            6              7    8      9     10     11     12  13  14  15  16 17  18 19
	### ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE
	
	#### QQ-plot including 95%CI and compute lambda [P]
	echo "Making QQ-plot including 95%CI and compute lambda..."
	zcat ${OUTPUT_DIR}/${FILENAME}.txt.gz | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col P | tail -n +2 | grep -v NA > ${OUTPUT_DIR}/${FILENAME}.QQplot.txt
		Rscript ${SCRIPTS}/plotter.qq.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.QQplot.txt -o ${OUTPUT_DIR} -s PVAL -f PDF
		Rscript ${SCRIPTS}/plotter.qq.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.QQplot.txt -o ${OUTPUT_DIR} -s PVAL -f PNG
	echo ""
	### Manhattan plot for publications [CHR, BP, P]
	echo "Manhattan plot for publications ..."
	zcat ${OUTPUT_DIR}/${FILENAME}.txt.gz | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col CHR,BP,P | tail -n +2 | grep -v NA > ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt
		Rscript ${SCRIPTS}/plotter.manhattan.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt -o ${OUTPUT_DIR} -c FULL -f PDF -t ${FILENAME}
		Rscript ${SCRIPTS}/plotter.manhattan.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt -o ${OUTPUT_DIR} -c FULL -f PNG -t ${FILENAME}
		Rscript ${SCRIPTS}/plotter.manhattan.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt -o ${OUTPUT_DIR} -c TWOCOLOR -f PDF -t ${FILENAME}
		Rscript ${SCRIPTS}/plotter.manhattan.R -p ${OUTPUT_DIR} -r ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt -o ${OUTPUT_DIR} -c TWOCOLOR -f PNG -t ${FILENAME}
	echo "Finished plotting, zipping up and re-organising intermediate files!"
	rm -v ${OUTPUT_DIR}/${FILENAME}.QQplot.txt
	rm -v ${OUTPUT_DIR}/${FILENAME}.Manhattan.txt
	echo ""
	echo ""

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message