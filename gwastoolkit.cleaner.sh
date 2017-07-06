#!/bin/bash

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
	echo "$1" # ERROR MESSAGE
	echo ""
	echo "- Argument #1 indicates the type of analysis [GWAS/REGION/GENES]."
	echo "- Argument #2 which study type [AEGS/AAAGS/CTMM]."
	echo "- Argument #3 which reference."
	echo "- Argument #4 which exclusion criterium was used."
	echo "- Argument #5 is path_to the output directory."
	echo "- Argument #6 which phenotype was analysed."
	echo ""
	echo "An example command would be: snptest_cleaner.v1.sh [arg1: [GWAS/REGION/GENES] ] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: exclusion list] [arg5: path_to_output_dir]  [arg6: some_phenotype ]"
  	echo ""
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}



echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                             SNPTEST_CLEANER"
echo "                                    CLEANS UP SNPTEST ANALYSIS RESULTS"
echo ""
echo " Version    : v1.2.2"
echo ""
echo " Last update: 2017-03-10"
echo " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echo "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echo "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echo "              - Jacco Schaap (j.schaap-2@umcutrecht.nl)"
echo "              - Tim Bezemer (t.bezemer-2@umcutrecht.nl)"
echo ""
echo " Description: Cleaning up all files from a SNPTEST analysis into one file for ease "
echo "              of downstream (R) analyses."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 6 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply at least [6] arguments when cleaning a *** GENOME-WIDE ANALYSIS ***!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	# set input-data
	ANALYSIS_TYPE=${1}
	STUDY_TYPE=${2}
	REFERENCE=${3}
	EXCLUSION=${4}
	OUTPUT_DIR=${5} 
	cd ${OUTPUT_DIR}	
	PHENOTYPE=${6}
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

script_copyright_message