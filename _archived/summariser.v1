#!/bin/bash

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                                 SUMMARISER.v1.1"
echo "                                          SUMMARISES ANALYSIS RESULTS"
echo ""
echo " You're here: "$(pwd)
echo " Today's: "$(date)
echo ""
echo " Version: SUMMARISER.v1.1"
echo ""
echo " Last update: July 28th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echo "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echo "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echo ""
echo " Description: Summarises analysis results and zips up into one directory."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 6 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [5] argument:"
	echo "- Argument #1 indicates the type of analysis [GWAS/REGION/GENES]."
	echo "- Argument #2 which study type [AEGS/AAAGS/CTMM]."
	echo "- Argument #3 which reference."
	echo "- Argument #4 is path_to the output directory."
	echo "- Argument #5 is project directory path"
	echo "- Argument #5 which phenotype was analysed."
	echo ""
	echo "An example command would be: summariser.v1.sh [arg1: [GWAS/REGION/GENES] ] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: path_to_output_dir]  [arg5: some_phenotype ]"
  	echo ""
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
else
	echo "All arguments are passed. These are the settings:"
	# set input-data
	ANALYSIS_TYPE=${1}
	STUDY_TYPE=${2}
	REFERENCE=${3}
	OUTPUT_DIR=${4} 
	cd ${OUTPUT_DIR}
	PROJECT_DIR=${5}	
	PHENOTYPE=${7}
	echo "The following analysis type will be run.....................: ${ANALYSIS_TYPE}"
	echo "The following dataset will be used..........................: ${STUDY_TYPE}"
	echo "The reference used..........................................: ${REFERENCE}"
	echo "The output directory is.....................................: ${OUTPUT_DIR}"
	echo "The project directory is....................................: ${PROJECT_DIR}"
	echo "The following gene was analysed and is summarised...........: ${GENE}"
	echo "The following phenotype was analysed and is summarised......: ${PHENOTYPE}"
	
	### Starting of the script
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                         SUMMARISING ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	
	if [[ -d ${PROJECT_DIR}/Summary ]]; then
		echo "Summary directory doesn't exist: making it."
		mkdir -v ${PROJECT_DIR}/Summary
		SUMMARY=${PROJECT_DIR}/Summary
	else
		echo "Summary directory does exist."
		SUMMARY=${PROJECT_DIR}/Summary
	if
	
	echo ""
	echo "Copying results files..."
	cp -v ${OUTPUT_DIR}/${STUDY_TYPE}*.${REFERENCE}.${PHENOTYPE}.summary_results.QC.txt.gz Summary/
 	
 	LOCUSZOOMFILE=$(ls ${OUTPUT_DIR}/locuszoom/*_${GENE}/*.pdf)
 	
 	cp -v ${i}/locuszoom/160221_MCL1/chr1_150047026-151052214.pdf Summary/${i}.chr1_150047026-151052214.pdf
 
	echo ""
	echo "All summarised."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi

#THISYEAR=$(date +'%Y')
#echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#echo ""
#echo ""
#echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#echo "+ The MIT License (MIT)                                                                                 +"
#echo "+ Copyright (c) ${THISYEAR} Sander W. van der Laan                                                             +"
#echo "+                                                                                                       +"
#echo "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +"
#echo "+ associated documentation files (the \"Software\"), to deal in the Software without restriction,         +"
#echo "+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +"
#echo "+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +"
#echo "+ subject to the following conditions:                                                                  +"
#echo "+                                                                                                       +"
#echo "+ The above copyright notice and this permission notice shall be included in all copies or substantial  +"
#echo "+ portions of the Software.                                                                             +"
#echo "+                                                                                                       +"
#echo "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +"
#echo "+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +"
#echo "+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +"
#echo "+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +"
#echo "+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +"
#echo "+                                                                                                       +"
#echo "+ Reference: http://opensource.org.                                                                     +"
#echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"