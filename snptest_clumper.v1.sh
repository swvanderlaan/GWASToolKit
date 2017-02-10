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
	echo "- Argument #1 is path_to the output directory."
	echo "- Argument #2 is name of the phenotype."
	echo "- Argument #3 is the maximum (largest) p-value to clump [CLUMP_P2]."
	echo "- Argument #4 is the minimum (smallest) p-value to clump [CLUMP_P1]."
	echo "- Argument #5 is the R^2 to use for clumping [CLUMP_R2]."
	echo "- Argument #6 is the KB range used for clumping [CLUMP_KB]."
	echo "- Argument #7 indicates the name of the clumping field to use (default: P) [CLUMP_FIELD]."
	echo "- Argument #8 indicates the reference to be used [1kGp3v5GoNL5/1kGp1v3/GoNL4]."
	echo "- Argument #9 indicates the study type to be used [AEGS/AAAGS/CTMM]."
	echo ""
	echo "An example command would be: snptest_clumper.v1.sh [arg1: path_to_output_dir] [arg2: phenotype] [arg3: CLUMP_P2] [arg4: CLUMP_P1] [arg5: CLUMP_R2] [arg6: CLUMP_KB] [arg7: CLUMP_FIELD] [arg8: REFERENCE]"
	echo ""
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
	date
  	exit 1

}

script_arguments_error_reference() {
	echo "$1" # ERROR MESSAGE
	echo ""
	echo " You must supply the correct argument:"
	echo " * [1kGp3v5GoNL5] -- for use of 1000G (phase 3, version 5, \"Final release\") plus GoNL5 as reference | DEFAULT."
	echo " * [1kGp1v3]      -- for use of 1000G (phase 1, version 3) as reference."
	echo " * [GoNL4]        -- for use of GoNL4 as reference | CURRENTLY UNAVAILABLE"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	# The wrong arguments are passed, so we'll exit the script now!
  	date
  	exit 1
}

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                             SNPTEST_CLUMPER"
echo "                                  CLUMPING OF SNPTEST ANALYSIS RESULTS"
echo ""
echo " Version    : v1.2.3"
echo ""
echo " Last update: 2017-02-10"
echo " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Testers    : - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echo "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echo "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echo ""
echo " Description: Clumping of a genome-wide SNPTEST analysis."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 10 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply at least [10] arguments when clumping a *** GENOME-WIDE ANALYSIS ***!"
	echo ""
	script_copyright_message
else
	echo "All arguments are passed. These are the settings:"
	### SET INPUT-DATA
	OUTPUT_DIR=${1} # depends on arg1
	PHENOTYPE=${2} 
	CLUMP_P1=${3} # e.g.5.0e-06 Significance threshold for index SNPs
	CLUMP_P2=${4} # e.g. 0.05 Secondary significance threshold for clumped SNPs
	CLUMP_R2=${5} # LD threshold for clumping
	CLUMP_KB=${6} # Physical distance threshold for clumping
	CLUMP_FIELD=${7}
	
	### ANALYSIS SETTINGS
	### Set location of [imputed] genotype data
	REFERENCE=${8} # depends on arg1  [1kGp3v5GoNL5/1kGp1v3/GoNL4] 
	
	### Study type used
	STUDY_TYPE=${9}

	### Study type used
	ANALYSIS_TYPE=${10}
	
	### THIS SHOULD BE PART OF THE GWASToolKit
	RESOURCES=/hpc/local/CentOS7/dhl_ec/software/MetaGWASToolKit/RESOURCES
	
	### THERE SHOULD BE A CHECK ON THIS AS A PREREQUISITE
	PLINK2=/hpc/local/CentOS7/dhl_ec/software/plink_v1.9
	
	### Determine which reference and thereby input data to use, arg1 [1kGp3v5GoNL5/1kGp1v3/GoNL4] 
		if [[ ${REFERENCE} = "1kGp1v3" ]]; then
			REFERENCE_1kGp1v3=${RESOURCES}/1000Gp1v3_EUR # 1000Gp1v3.20101123.EUR
		elif [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
			REFERENCE_1kGp3v5GoNL5=${RESOURCES}/1000Gp3v5_EUR # 1000Gp3v5.20130502.EURs
		elif [[ ${REFERENCE} = "GoNL4" ]]; then
			echo "Apologies: currently it is not possible to clump based on GoNL4"
		else
		### If arguments are not met than the 
			echo "Oh, computer says no! Number of arguments found "$#"."
			script_arguments_error_reference echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			script_copyright_message
		fi
		
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
	if [[ ${REFERENCE} = "1kGp1v3" ]]; then
		echo "The reference is ${REFERENCE}."
		### REFERENCE_1kGp1v3 # 1000Gp1v3.20101123.EUR
		$PLINK2 --bfile $REFERENCE_1kGp1v3/1000Gp1v3.20101123.EUR --memory 168960 --clump ${OUTPUT_DIR}/${FILENAME}.txt --clump-snp-field "RSID" --clump-p1 ${CLUMP_P1} --clump-p2 ${CLUMP_P2} --clump-r2 ${CLUMP_R2} --clump-kb ${CLUMP_KB} --clump-field ${CLUMP_FIELD} --out ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.clumped --clump-verbose --clump-annotate CodedAlleleB,OtherAlleleA,CAF,MAF,MAC,HWE,AvgMaxPostCall,Info,BETA,SE 
		echo "The reference is ${REFERENCE}."
	elif [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
		echo "The reference is ${REFERENCE}."
		### REFERENCE_1kGp3v5GoNL5 # 1000Gp3v5.20130502.EUR
		$PLINK2 --bfile $REFERENCE_1kGp3v5GoNL5/1000Gp3v5.20130502.EUR --memory 168960 --clump ${OUTPUT_DIR}/${FILENAME}.txt --clump-snp-field "RSID" --clump-p1 ${CLUMP_P1} --clump-p2 ${CLUMP_P2} --clump-r2 ${CLUMP_R2} --clump-kb ${CLUMP_KB} --clump-field ${CLUMP_FIELD} --out ${OUTPUT_DIR}/${FILENAME}.${CLUMP_R2}.clumped --clump-verbose --clump-annotate CodedAlleleB,OtherAlleleA,CAF,MAF,MAC,HWE,AvgMaxPostCall,Info,BETA,SE 
	elif [[ ${REFERENCE} = "GoNL4" ]]; then
		echo "Apologies: currently it is not possible to clump based on GoNL4"
	else
	### If arguments are not met than the 
		echo "Oh, computer says no! Number of arguments found "$#"."
		script_arguments_error_reference echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
		echo ""
		script_copyright_message
	fi
		
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

script_copyright_message