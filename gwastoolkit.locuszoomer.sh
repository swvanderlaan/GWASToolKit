#!/bin/bash

### DISPLAY FUNCTIONS
### Setting colouring
NONE='\033[00m'
BOLD='\033[1m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
UNDERLINE='\033[4m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
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
	echo "$1" # ANALYSIS TYPE
	echo "- Argument #1  indicates whether you want to analyse a list of variants, a region, or do a GWAS [VARIANT/REGION/GWAS]."
	echo "               Depending on the choice you additional arguments are expected:"
	echo "               - for GWAS: the standard 9 arguments in total."
	echo "               - for REGION: additional arguments, namely the [CHR], [REGION_START] and [REGION_END] in numerical fashion."
	echo "               - for GENES: additional arguments, namely the [GENES] list and [RANGE] in numerical fashion."
	echo "- Argument #2  the study to use, AEGS, AAAGS, or CTMM."
	echo "- Argument #3  is input data to use, i.e. where the [imputed] genotypes reside: [1kGp3v5GoNL5/1kGp1v3/GoNL4]."
	echo "- Argument #4  is path_to the RESULTS directory of your analysis. [INPUTDIR]"
	echo "- Argument #5  is the results file PHENOTYPE (e.g. EP_composite_LA.summary_results.QC) -- this"
	echo "               is used to 1) load the data and 2) write output with a similar name."
	echo "- Argument #6  is the column number that holds the variantID (e.g. 2)."
	echo "- Argument #7  is the column number that holds the P-values (e.g. 19)."
	echo "- Argument #8  to indicate which version of LocusZoom to use [LZ12/LZ13] | DEFAULT IS LZ13."
	echo "" 
	echo "For GWAS:" 
	echo "- Argument #9  we expect a list with variantIDs [VARIANTLIST]."
	echo "- Argument #10 indicates the [RANGE] in basepairs (e.g. 500000) to plot around the variant."
	echo ""
	echo "An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9"
	echo ""
  	echo "For REGIONAL ANALYSES:"
  	echo "- Argument #9 is the lookup_list_file [REGIONS_FILE]: this is a file with on each line a [VARIANT], [CHR] (e.g. 1-22 or X; "
  	echo "               NOTE: GoNL4 doesn't include information for chromosome X), [REGION_START] (e.g. 12345) and "
  	echo "               [REGION_END] (e.g. 678910)."
	echo ""
	echo "An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 arg11"
	echo ""
  	echo "For per-GENE ANALYSES:"
  	echo "- Argument #9 we expect here a [GENE]."
	echo "- Argument #10 we expect here [RANGE] in basepairs (e.g. 500000) to plot around the gene."
	echo ""
	echo "An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
}

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                           LOCUSZOOM PLOTTER"
echo ""
echo " Version    : v1.4.3"
echo ""
echo " Last update: 2016-12-20"
echo " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Description: Plot a LocusZoom for (imputed) (meta-)ExomeChip or (meta-)GWAS hits "
echo "              (determined after clumping!). "
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### START of if-else statement for the number of command-line arguments passed ###
### Set the analysis type.
ANALYSIS_TYPE=${1}

### Set the analysis type.
STUDY_TYPE=${2}

### START of if-else statement for the number of command-line arguments passed ###
if [[ ${ANALYSIS_TYPE} = "GWAS" && $# -lt 9 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply at least [9] arguments when running a *** GENOME-WIDE ANALYSIS ***!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "REGION" && $# -lt 11 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [11] arguments when running a *** REGIONAL ANALYSIS ***!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "GENES" && $# -lt 10 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [10] arguments when running a *** GENE ANALYSIS ***!"
	script_copyright_message

else
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                             MAKE LOCUSZOOM PLOTS"
	### SETTING LOCUSZOOM
	# Works for version 1.2 and version 1.3 is forthcoming.
	LOCUSZOOM12=/hpc/local/CentOS7/dhl_ec/software/locuszoom_1.2/bin/locuszoom
	LOCUSZOOM13=/hpc/local/CentOS7/dhl_ec/software/locuszoom_1.3/bin/locuszoom
	echo ""	
	### CHECKING ARGUMENTS ###
	### Set location of [imputed] genotype data
	REFERENCE=${3} # depends on arg3  [1kGp3v5GoNL5/1kGp1v3/GoNL4] 
	
	### Determine which reference and thereby input data to use, arg1 [1kGp3v5GoNL5/1kGp1v3/GoNL4] 
	if [[ ${STUDY_TYPE} = "AEGS" ]]; then
		if [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
			echo "Unfortunately it is not possible yet to make LZ with this reference."
			HG19_GENES=/hpc/local/CentOS7/dhl_ec/software/GWASToolKit/glist-hg19
		elif [[ ${REFERENCE} = "1kGp1v3" ]]; then
			LDMAP="--pop EUR --build hg19 --source 1000G_March2012"
			HG19_GENES=/hpc/local/CentOS7/dhl_ec/software/GWASToolKit/glist-hg19
		elif [[ ${REFERENCE} = "GoNL4" ]]; then
			echo "Unfortunately it is not possible yet to make LZ with this reference."
			HG19_GENES=/hpc/local/CentOS7/dhl_ec/software/GWASToolKit/glist-hg19
		else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [1kGp3v5GoNL5] -- for use of data imputed using 1000G (phase 3, version 5, \"Final release\") plus GoNL5."
			echo " * [1kGp1v3]      -- for use of data imputed using 1000G (phase 1, version 3)."
			echo " * [GoNL4]        -- for use of data imputed using GoNL4, note that this data *does not* include chromosome X."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
		fi
	elif [[ ${STUDY_TYPE} = "AAGS" ]]; then
		if [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
			echo "Unfortunately it is not possible yet to make LZ with this reference."
			HG19_GENES=/hpc/local/CentOS7/dhl_ec/software/GWASToolKit/glist-hg19
		else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [1kGp3v5GoNL5] -- for use of data imputed using 1000G (phase 3, version 5, \"Final release\") plus GoNL5."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
		fi
	elif [[ ${STUDY_TYPE} = "CTMM" ]]; then
		if [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
			echo "Unfortunately it is not possible yet to make LZ with this reference."
			HG19_GENES=/hpc/local/CentOS7/dhl_ec/software/GWASToolKit/glist-hg19
		else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [1kGp3v5GoNL5] -- for use of data imputed using 1000G (phase 3, version 5, \"Final release\") plus GoNL5."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
  			script_copyright_message
		fi
	else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [AEGS/AAAGS/CTMM] -- for use of imputed data of Athero-Express Genomics Study 1 & 2 (AEGS, n = 1,526), "
			echo "                        Abdominal Aortic Aneurysm Express Genomics Study (AAAGS, n = 479), or CTMM (n = )."
			echo "                        Please note that for AAAGS and CTMM only 1000G (phase 3, version 5, "
			echo "                        \"Final release\") plus GoNL5 imputed data is available."
			echo "                        For AEGS also 1000G (phase 1, version 3) and GoNL4 imputed data is available."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
  			script_copyright_message
	fi

	### SETTING VARIABLES BASED ON ARGUMENTS PASSED
	# Setting the remaining variables
	INPUTDIR=${4} # depends on arg4
	# Plus make a new directory which will serve as the output directory!
	if [ ! -d ${INPUTDIR}/locuszoom ]; then
	  	echo ""
	  	mkdir -v ${INPUTDIR}/locuszoom
	  	OUTPUTDIR=${INPUTDIR}/locuszoom
	  	echo "The output directory is set...: ${OUTPUTDIR}"
	else
		OUTPUTDIR=${INPUTDIR}/locuszoom
	  	echo "Output directory already exists...: ${OUTPUTDIR}"
	fi
	echo ""

	PHENOTYPE=${5} # depends on arg5
	VARIANTID=${6} # depends on arg6
	PVALUE=${7} # depends on arg7
	LZVERSION=${8} # depends on arg8
	
	LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE dCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 showRug=TRUE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=FALSE bigDiamond=TRUE ymax=8 rfrows=10 refsnpLineWidth=2"

	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		### Which variant to look at.
		echo "We will lookup the following variants:"
		VARIANTLIST=${9} # depends on arg9
		while read VARIANTS; do 
			for VARIANT in ${VARIANTS}; do
			echo "* ${VARIANT}"
			done
		done < ${VARIANTLIST}

		### Determine the range
		RANGE=${10}
		echo ""
		N_VARIANTS=$(cat ${VARIANTLIST} | wc -l)
		echo "Number of variants to plot...: ${N_VARIANTS} variants"
		echo "Investigating range..........: ${RANGE}kb around each of these variants."
		
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Initiating lookup..."
		echo ""	
		### Making the input file for LocusZoom for the phenotype.
		### Example header of input file
		### MarkerName P-value
		### rs7098888 0.000686966
		### rs9733444 0.00149974
		echo "Making the LocusZoom input-file for the phenotype..."
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
		zcat ${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.txt.gz | tail -n +2 | awk '{ print $'${VARIANTID}', $'${PVALUE}' }' >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
		while read VARIANTS; do
			for VARIANT in ${VARIANTS}; do
				echo "Plotting variant: ${VARIANT} ± ${RANGE}kb..."
				
				if [[ ${LZVERSION} = "LZ13" ]]; then
					echo "Using LocusZoom v1.3..."
					cd ${OUTPUTDIR}
					${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --flank ${RANGE}kb ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
				
				elif [[ ${LZVERSION} = "LZ12" ]]; then
					echo "Using LocusZoom v1.2..."
					cd ${OUTPUTDIR}
					${LOCUSZOOM12} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --flank ${RANGE}kb ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
				
				else
				### If arguments are not met than the 
					echo ""
					echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
					echo ""
					echo " You must supply the correct argument:"
					echo " * [LZ13]      -- uses LocusZoom version 1.3 | THIS IS THE DEFAULT."
					echo " * [LZ12]      -- uses LocusZoom version 1.2."
					echo ""
					echo " Please refer to instruction above."
					echo ""
					echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
					# The wrong arguments are passed, so we will exit the script now!
					exit 1
				fi
			done
		done < ${VARIANTLIST}
		echo ""
		echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		# Loading the lookup list file (should be a space-delimited list of variants with range, 1 PER line as they
		# appear in the results output-files, e.g. 'rs12345 chr1 12345 98713'). Can also be a file
		# with just one line - of course. 
		REGIONS_FILE=${9} # depends on arg10
		
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Initiating lookup..."
		echo ""	
		### Making the input file for LocusZoom for the phenotype.
		### Example header of input file
		### MarkerName P-value
		### rs7098888 0.000686966
		### rs9733444 0.00149974
		echo "Making the LocusZoom input-file for the phenotype..."
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
		zcat ${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.txt.gz | tail -n +2 | awk '{ print $'${VARIANTID}', $'${PVALUE}' }' >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
				
		while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
			LINE=${REGIONOFINTEREST}
			VARIANT=$(echo "${LINE}" | awk '{print $1}')
			CHR=$(echo "${LINE}" | awk '{print $2}')
			START=$(echo "${LINE}" | awk '{print $3}')
			END=$(echo "${LINE}" | awk '{print $4}')
			
			echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
			if [[ ${LZVERSION} = "LZ13" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --chr ${CHR} --start ${START} --end ${END} ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
			
			elif [[ ${LZVERSION} = "LZ12" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM12} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --chr ${CHR} --start ${START} --end ${END} ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
			
			else
			### If arguments are not met than the 
				echo ""
				echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
				echo ""
				echo " You must supply the correct argument:"
				echo " * [LZ13]      -- uses LocusZoom version 1.3 | THIS IS THE DEFAULT."
				echo " * [LZ12]      -- uses LocusZoom version 1.2."
				echo ""
				echo " Please refer to instruction above."
				echo ""
				echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
				# The wrong arguments are passed, so we will exit the script now!
					exit 1
			fi
		done < ${REGIONS_FILE}		
		
		echo ""
		echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		### Determine the gene to look at		
		echo "We will lookup the following gene:"
		GENE=${9} # depends on arg9
		echo ${GENE}
		echo ""
		### Determine the range
		RANGE=${10}
		echo "Investigating range: ${RANGE}kb around the gene."
		
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Initiating lookup..."
		echo ""	
		### Making the input file for LocusZoom for the phenotype.
		### Example header of input file
		### MarkerName P-value
		### rs7098888 0.000686966
		### rs9733444 0.00149974
		echo "Making the LocusZoom input-file for the phenotype..."
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
		zcat ${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.txt.gz | tail -n +2 | awk '{ print $'${VARIANTID}', $'${PVALUE}' }' >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom
		echo "Plotting variant: ${GENE}"
			if [[ ${LZVERSION} = "LZ13" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refgene ${GENE} --flank ${RANGE}kb ${LDMAP} theme=publication title="${GENE} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
			
			elif [[ ${LZVERSION} = "LZ12" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM12} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refgene ${GENE} --flank ${RANGE}kb ${LDMAP} theme=publication title="${GENE} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
			
			else
			### If arguments are not met than the 
				echo ""
				echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
				echo ""
				echo " You must supply the correct argument:"
				echo " * [LZ13]      -- uses LocusZoom version 1.3 | THIS IS THE DEFAULT."
				echo " * [LZ12]      -- uses LocusZoom version 1.2."
				echo ""
				echo " Please refer to instruction above."
				echo ""
				echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
				# The wrong arguments are passed, so we will exit the script now!
		  		exit 1
		  		script_copyright_message
			fi

		echo ""
		echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
	else
		### If arguments are not met than the 
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [GWAS]         -- uses a total of 10 arguments | THIS IS THE DEFAULT."
			echo " * [REGION]       -- uses 9 arguments, should include a list with variant(s) and chromosomal range(s)."
			echo " * [GENES]        -- uses 10 arguments, should include a list with gene(s), with the range to plot."
			echo ""
			echo " Please refer to instruction above."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			date
  			exit 1
  			script_copyright_message
	fi

### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message