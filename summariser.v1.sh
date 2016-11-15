#!/bin/bash

# to do: add in readme functionality, text file with summary results and explanation of things
# to do: make argument parsing depending on ${ANALYSIS_TYPE}
# to do: add in gzipping functionality of 'summary' directory and its readme

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                                   SUMMARISER"
echo "                                          SUMMARISES ANALYSIS RESULTS"
echo ""
echo " You're here: "$(pwd)
echo " Today's: "$(date)
echo ""
echo " Version: SUMMARISER.v1.3"
echo ""
echo " Last update: November 15th, 2016"
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
if [[ $# -lt 7 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [5] argument:"
	echo "- Argument #1 indicates the type of analysis [GWAS/REGION/GENES]."
	echo "- Argument #2 which study type [AEGS/AAAGS/CTMM]."
	echo "- Argument #3 which reference."
	echo "- Argument #4 is path_to the output directory."
	echo "- Argument #5 is project directory path."
	echo "- Argument #5 which phenotype was analysed."
	echo ""
	echo "An example command would be: summariser.v1.sh [arg1: [GWAS/REGION/GENES] ] [arg2: AEGS/AAAGS/CTMM] [arg3: reference_to_use [1kGp3v5GoNL5/1kGp1v3/GoNL4] ] [arg4: path_to_output_dir] [arg6: path_to_project_dir ] [arg7: some_phenotype ] [arg8: trait_type ]"
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
	OUTPUT_DIR=${4} # this is the directory of the results 'snptest_results' relative to '/hpc/dhl_ec/YOURLOGINNAME/SOMEDIRECTORY/PROJECTNAME/'
	PROJECT_DIR=${5} # the name of the project directory: /hpc/dhl_ec/YOURLOGINNAME/SOMEDIRECTORY/PROJECTNAME	
	PHENOTYPE_FILE=${6} 
	PHENOTYPES=$(cat ${PHENOTYPE_FILE})
	TRAIT_TYPE=${7}
	
	echo "The following analysis type will be run.....................: ${ANALYSIS_TYPE}"
	echo "The following dataset will be used..........................: ${STUDY_TYPE}"
	echo "The reference used..........................................: ${REFERENCE}"
	echo "The output directory is.....................................: ${OUTPUT_DIR}"
	echo "The project directory is....................................: ${PROJECT_DIR}"
	### Starting of the script
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                         SUMMARISING ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "$(date)
	echo ""
	
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		echo "*** NOT IMPLEMENTED YET ***"
	
	
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
	
		if [[ ! -d ${PROJECT_DIR}/summary.${ANALYSIS_TYPE} ]]; then
			echo "Summary directory doesn't exist: making it."
			mkdir -v ${PROJECT_DIR}/summary.${ANALYSIS_TYPE}
			SUMMARY=${PROJECT_DIR}/summary.${ANALYSIS_TYPE}
		else
			echo "Summary directory does exist."
			SUMMARY=${PROJECT_DIR}/summary.${ANALYSIS_TYPE}
		fi
		echo ""
	
		echo "Summarising data..."
		echo "Phenotype TraitType ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt

		for PHENOTYPE in ${PHENOTYPES}; do
		PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			echo "* Copying results for [ ${PHENOTYPE} ]..."
			cp -v ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz ${SUMMARY}/
		
			echo ""
			echo "* Concatenating results for [ ${PHENOTYPE} ]..."
			zcat ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz | tail -n +2 | awk -v PHENOTYPE_RESULT=${PHENOTYPE} -v TRAIT_RESULT=${TRAIT_TYPE} '{ print PHENOTYPE_RESULT, TRAIT_RESULT, $0 }' OFS=" "  >> ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt
				
		done
		echo " * Gzipping the summarised data..."
		gzip -v ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt

 	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
 		GENE=${8}
 		
 		if [[ ! -d ${PROJECT_DIR}/summary.${GENE} ]]; then
			echo "Summary directory doesn't exist: making it."
			mkdir -v ${PROJECT_DIR}/summary.${GENE}
			SUMMARY=${PROJECT_DIR}/summary.${GENE}
		else
			echo "Summary directory does exist."
			SUMMARY=${PROJECT_DIR}/summary.${GENE}
		fi
		echo ""
		
		echo "Summarising data..."
		echo "Phenotype TraitType ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt

		for PHENOTYPE in ${PHENOTYPES}; do
		PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
			echo "* Copying results for [ ${PHENOTYPE} ]..."
			cp -v ${PHENO_OUTPUT_DIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz ${SUMMARY}/
		
			echo ""
			echo "* Concatenating results for [ ${PHENOTYPE} ]..."
			zcat ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.txt.gz | tail -n +2 | awk -v PHENOTYPE_RESULT=${PHENOTYPE} -v TRAIT_RESULT=${TRAIT_TYPE} '{ print PHENOTYPE_RESULT, TRAIT_RESULT, $0 }' OFS=" "  >> ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt
		
			echo "* Copying LocusZoom plots for [ ${PHENOTYPE} ]..."
			cp -v ${PHENO_OUTPUT_DIR}/locuszoom/*_${GENE}/*.pdf ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${GENE}.LocusZoom.pdf
		
		done
		echo " * Gzipping the summarised data..."
		gzip -v ${SUMMARY}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${TRAIT_TYPE}.${GENE}.summary.txt
		
 	else
		### If arguments are not met then this error message will be displayed 
		echo ""
		echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
		echo ""
		echo " You must supply the correct argument:"
		echo " * [GWAS]         -- uses a total of 13 arguments | THIS IS THE DEFAULT."
		echo " * [VARIANT]      -- uses 14 arguments, and the last should be a variant-list and the chromosome."
		echo " * [REGION]       -- uses 16 arguments, and the last three should indicate the chromosomal range."
		echo " * [GENES]        -- uses 14 arguments, and the last three should indicate the gene list and the range."
		echo ""
		echo " Please refer to instruction above."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		# The wrong arguments are passed, so we'll exit the script now!
  		date
  		exit 1
	fi
 	
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