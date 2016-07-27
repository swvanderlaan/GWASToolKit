#! /bin/bash -x

# Clear the scene!
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                      SNPTEST_PHENO_WRAPPER.v1: WRAPPING UP SNPTEST ANALYSIS RESULTS"
echo ""
echo " You're here: "`pwd`
echo " Today's: " `date`
echo ""
echo " Version: SNPTEST_PHENO_WRAPPER.v1.20160208"
echo ""
echo " Last update: February 8th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl);"
echo ""
echo " Description: Wrapping up all files from a SNPTEST analysis into one file for ease "
echo "              of downstream (R) analyses."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
### Set the analysis type.
ANALYSIS_TYPE=${1} # depends on arg1

### START of if-else statement for the number of command-line arguments passed ###
if [[ (${ANALYSIS_TYPE} = "GWAS" || ${ANALYSIS_TYPE} = "VARIANT") && $# -lt 3 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [3] arguments:"
	echo "- Argument #1 indicates whether you want to analyse a list of variants, a region, or do a GWAS [VARIANT/REGION/GWAS]."
	echo "               Depending on the choice you additional arguments are expected:"
	echo "               - for GWAS: no additional arguments, except the standard 14 arguments in total."
	echo "               - for VARIANT: 2 alternative argument, namely a [FILE] containing the list of variants and the chromosome."
	echo "               - for REGION: 3 alternative arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion."
	echo "               - for GENES: 2 alternative arguments, namely a list of [GENES] and a ±[RANGE]."
	echo "- Argument #2 is path_to the output directory."
	echo "- Argument #3 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT."
	echo ""
	echo "An example command would be: snptest_pheno_wrapper.v1.sh [arg1: path_to_output_dir] [arg2: [QUANT/BINARY] ]"
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	date
  	exit 1
elif [[ (${ANALYSIS_TYPE} = "GENES" || ${ANALYSIS_TYPE} = "REGION") && $# -lt 4 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [3] arguments:"
	echo "- Argument #1 indicates whether you want to analyse a list of variants, a region, or do a GWAS [VARIANT/REGION/GWAS]."
	echo "               Depending on the choice you additional arguments are expected:"
	echo "               - for GWAS: no additional arguments, except the standard 14 arguments in total."
	echo "               - for VARIANT: 2 alternative argument, namely a [FILE] containing the list of variants and the chromosome."
	echo "               - for REGION: 3 alternative arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion."
	echo "               - for GENES: 2 alternative arguments, namely a list of [GENES] and a ±[RANGE]."
	echo "- Argument #2 is path_to the output directory."
	echo "- Argument #3 indicates the type of trait, quantitative or binary [QUANT/BINARY] | QUANT IS THE DEFAULT."
	echo "- Argument #4 indicates the exact file name for per-gene/regional analyses."
	echo ""
	echo "An example command would be: snptest_pheno_wrapper.v1.sh [arg1: path_to_output_dir] [arg2: [QUANT/BINARY] ] [arg3: [EXACT_FILE_NAME]]"
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	date
  	exit 1
else
	echo "All arguments are passed. These are the settings:"
	# set input-data
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		OUTPUT_DIR=${2} # depends on arg2
		TRAIT_TYPE=${3} # depends on arg3
		echo "The output directory is.................: ${OUTPUT_DIR}"
		echo "The type of phenotypes..................: ${TRAIT_TYPE}"
		
	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then
		echo "The output directory is.................: ${OUTPUT_DIR}"
		echo "The type of phenotypes..................: ${TRAIT_TYPE}"
		
	elif [[ ${ANALYSIS_TYPE} = "REGION" || ${ANALYSIS_TYPE} = "GENES" ]]; then
		EXACTNAME=${4} # depends on arg4
		echo "The output directory is.................: ${OUTPUT_DIR}"
		echo "The type of phenotypes..................: ${TRAIT_TYPE}"
		echo "The exact file name is..................: ${EXACTNAME}"
		
	#elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
	#	EXACTNAME=${4} # depends on arg4
	#	echo "The output directory is.................: ${OUTPUT_DIR}"
	#	echo "The type of phenotypes..................: ${TRAIT_TYPE}"
	#	echo "The exact file name is..................: ${EXACTNAME}"
	
	else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [GWAS]        -- for a genome-wide analysis."
			echo " * [VARIANT]     -- for a per-variant analysis."
			echo " * [REGION]      -- for a regional analysis."
			echo " * [GENES]      -- for a per-gene analysis."
			echo ""
			echo " Please refer to instruction above."
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
	fi
	
		### Starting of the script
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                                WRAPPING UP SNPTEST ANALYSIS RESULTS"
		echo ""
		echo "Please be patient...this can take a long time depending on the number of files."
		echo "We started at: `date`"
		echo ""
	
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
	if [[ ${TRAIT_TYPE} = "QUANT" && ${ANALYSIS_TYPE} = "GWAS" ]]; then
		# create results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 19 CALC 21 22  24 25 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/summary_results.txt
		
		for CHR in $(seq 1 22) X; do
			# which file are we processing?
			echo "Processing chromosome "${CHR}
			cat ${OUTPUT_DIR}/*.chr${CHR}.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$19*$18), $19, (((2*$16)+$15)/(2*$18)), $21, $22, $24, $25 } ' >> ${OUTPUT_DIR}/summary_results.txt
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
		done
	
	elif [[ ${TRAIT_TYPE} = "BINARY" && ${ANALYSIS_TYPE} = "GWAS" ]]; then	
		# create BINARY results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 29 CALC 33 45  47 48 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/summary_results.txt
		
		for CHR in $(seq 1 22) X; do
			# which file are we processing?
			echo "Processing chromosome "${CHR}
			cat ${OUTPUT_DIR}/*.chr${CHR}.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$29*$18), $29, (((2*$16)+$15)/(2*$18)), $33, $45, $47, $48 } ' >> ${OUTPUT_DIR}/summary_results.txt
			echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
			echo ""
		done
	elif [[ ${TRAIT_TYPE} = "QUANT" && (${ANALYSIS_TYPE} = "REGION" || ${ANALYSIS_TYPE} = "GENES") ]]; then
		# create results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 19 CALC 21 22  24 25 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/${EXACTNAME}.summary_results.txt
		
		# which file are we processing?
		echo "Processing ${EXACTNAME}."
		cat ${OUTPUT_DIR}/${EXACTNAME}.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$19*$18), $19, (((2*$16)+$15)/(2*$18)), $21, $22, $24, $25 } ' >> ${OUTPUT_DIR}/${EXACTNAME}.summary_results.txt
		echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
		echo ""
	
	elif [[ ${TRAIT_TYPE} = "BINARY" && (${ANALYSIS_TYPE} = "REGION" || ${ANALYSIS_TYPE} = "GENES") ]]; then	
		# create BINARY results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 29 CALC 33 45  47 48 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/${EXACTNAME}.summary_results.txt
		
		# which file are we processing?
		echo "Processing ${EXACTNAME}."
		cat ${OUTPUT_DIR}/${EXACTNAME}.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$29*$18), $29, (((2*$16)+$15)/(2*$18)), $33, $45, $47, $48 } ' >> ${OUTPUT_DIR}/${EXACTNAME}.summary_results.txt
		echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
		echo ""
	elif [[ ${TRAIT_TYPE} = "QUANT" && ${ANALYSIS_TYPE} = "VARIANT" ]]; then
		# create results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 19 CALC 21 22  24 25 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/variant.summary_results.txt
		
		# which file are we processing?
		echo "Processing the file for individual ${ANALYSIS_TYPE} results."
		cat ${OUTPUT_DIR}/*.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$19*$18), $19, (((2*$16)+$15)/(2*$18)), $21, $22, $24, $25 } ' >> ${OUTPUT_DIR}/variant.summary_results.txt
		echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
		echo ""
	
	elif [[ ${TRAIT_TYPE} = "BINARY" && ${ANALYSIS_TYPE} = "VARIANT" ]]; then	
		# create BINARY results file
		###   1     2    3   4  5            6            8              9    14     15     16     18     CALC 29 CALC 33 45  47 48 # AUTOSOMAL & X CHROMOSOMES
		echo "ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > ${OUTPUT_DIR}/variant.summary_results.txt
		
		# which file are we processing?
		echo "Processing the file for individual ${ANALYSIS_TYPE} results."
		cat ${OUTPUT_DIR}/*.out | grep -v "#" | tail -n +2 | awk ' { print $1, $2, $3, $4, $5, $6, $8, $9, $14, $15, $16, $18, (2*$29*$18), $29, (((2*$16)+$15)/(2*$18)), $33, $45, $47, $48 } ' >> ${OUTPUT_DIR}/variant.summary_results.txt
		echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
		echo ""
	else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [QUANT]                        -- indicates the trait is quantitative (e.g. total cholesterol levels) | THIS IS THE DEFAULT."
			echo " * [BINARY]                       -- indicates the trait is binary (e.g. case-control, etc)."
			echo " * [GWAS/VARIANT/REGION/GENES]    -- to indicate the type of analysis."
			echo ""
			echo " Please refer to instruction above."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
	fi
	
	echo ""
	echo "Let's clean up our work..."
	mkdir -v ${OUTPUT_DIR}/_scriptlogs
	mv -v ${OUTPUT_DIR}/aegs_*.sh ${OUTPUT_DIR}/_scriptlogs/
	mv -v ${OUTPUT_DIR}/aegs_*.output ${OUTPUT_DIR}/_scriptlogs/
	gzip -v ${OUTPUT_DIR}/_scriptlogs/aegs_*.output
	mkdir -v ${OUTPUT_DIR}/_rawresults
	mv -v ${OUTPUT_DIR}/*.log ${OUTPUT_DIR}/_rawresults/
	gzip -v ${OUTPUT_DIR}/_rawresults/*.log
	mv -v ${OUTPUT_DIR}/*.out ${OUTPUT_DIR}/_rawresults/
	gzip -v ${OUTPUT_DIR}/_rawresults/*.out
		if [[ -s ${OUTPUT_DIR}/aegs_*.errors ]]
		then
			echo "* ERROR FILE NOT EMPTY: The error file has some data. We'll keep it there for review."
		else
			echo "The error file is empty."
	        rm -v ${OUTPUT_DIR}/aegs_*.errors
		fi
	gzip -v ${OUTPUT_DIR}/*ummary_results.txt
	echo ""
	echo "All finished. You're analysis has finished successfully and was summarised in ${OUTPUT_DIR}. A ReadMe text-file is also"
	echo "available with some explanation on the data, plots (not made for individual variant analyses), "
	echo "(raw zipped) results."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### END of if-else statement for the number of command-line arguments passed ###
fi

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ The MIT License (MIT)                                                                                 +"
echo "+ Copyright (c) 2016 Sander W. van der Laan                                                             +"
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


