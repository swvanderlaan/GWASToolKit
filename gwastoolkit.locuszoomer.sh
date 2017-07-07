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
	echoerror "$1" # ERROR MESSAGE
	echoerror ""
	echoerror "- Argument #1 is path_to the configuration file."
	echoerror "- Argument #2 is the phenotype analysed."
	echoerror "- Argument #3 is the gene analysed -- gene-based analysis only."
	echoerror ""
	echoerror "An example command would be: gwastoolkit.locuszoomer.sh [arg1: path_to_configuration_file] [arg2: phenotype] [arg3: gene]"
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

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                           GWASTOOLKIT LOCUSZOOMER"
echo "                                regional association plotting of clumped results"
echo ""
echo " Version    : v1.5.0"
echo ""
echo " Last update: 2017-07-07"
echo " Written by : Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echo ""
echo " Description: Plot a LocusZoom for (imputed) (meta-)ExomeChip or (meta-)GWAS hits "
echo "              (determined after clumping!). "
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### LOADING CONFIGURATION FILE
source "$1" # Depends on arg1.

### REQUIRED | GENERALS	
CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
PHENOTYPE="$2" # Depends on arg2

### START of if-else statement for the number of command-line arguments passed ###
if [[ ${ANALYSIS_TYPE} = "GWAS" && $# -lt 2 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [2] arguments for regional association plotting of *** GENOME-WIDE ANALYSIS *** results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "REGION" && $# -lt 3 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [3] arguments for regional association plotting of *** REGIONAL ANALYSIS *** results!"
	script_copyright_message
	
elif [[ ${ANALYSIS_TYPE} = "GENES" && $# -lt 3 ]]; then 
	echo "Oh, computer says no! Number of arguments found "$#"."
	script_arguments_error "You must supply [3] arguments for regional association plotting of *** GENE ANALYSIS *** results!"
	script_copyright_message

else
	
	echo "All arguments are passed. These are the settings:"
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then 
		### SET INPUT-DATA
		INPUTDIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
		RESULTS=${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.txt.gz
		
	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then 
		### SET INPUT-DATA
		INPUTDIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${PHENOTYPE} # depends on arg1
		RESULTS=${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.txt.gz
		
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then 
		### SET INPUT-DATA
		GENE="$3"
		INPUTDIR=${PROJECTDIR}/${PROJECTNAME}/snptest_results/${GENE}/${PHENOTYPE} # depends on arg1
		RESULTS=${INPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.summary_results.QC.txt.gz
		
	else
		echo "Oh, computer says no! Number of arguments found "$#"."
		script_arguments_error "You must supply [2-3] arguments for regional association plotting of *** GWASToolKit *** results!"
		script_copyright_message
	fi

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                             MAKE LOCUSZOOM PLOTS"
	echo ""	
	### CHECKING ARGUMENTS ###

	### Determine which reference and thereby input data to use, arg1 [1kGp3v5GoNL5/1kGp1v3/GoNL4] 
	if [[ ${REFERENCE} = "1kGp3v5GoNL5" ]]; then
		echo "You're references is [${REFERENCE}]; using pop=EUR, build=hg19, and source=1000G_March2012."
		LDMAP="--pop EUR --build hg19 --source 1000G_March2012"
	elif [[ ${REFERENCE} = "1kGp1v3" ]]; then
		echo "You're references is [${REFERENCE}]; using pop=EUR, build=hg19, and source=1000G_March2012."
		LDMAP="--pop EUR --build hg19 --source 1000G_March2012"
	elif [[ ${REFERENCE} = "GoNL4" ]]; then
		echo "You're references is [${REFERENCE}]; using pop=EUR, build=hg19, and source=1000G_March2012."
		LDMAP="--pop EUR --build hg19 --source 1000G_March2012"
	else
	### If arguments are not met than the 
		echoerror ""
		echoerror "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
		echoerror ""
		echoerror " You must supply the correct argument:"
		echoerror " * [1kGp3v5GoNL5] -- for use of data imputed using 1000G (phase 3, version 5, \"Final release\") plus GoNL5."
		echoerror " * [1kGp1v3]      -- for use of data imputed using 1000G (phase 1, version 3)."
		echoerror " * [GoNL4]        -- for use of data imputed using GoNL4, note that this data *does not* include chromosome X."
		echoerror ""
		echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		# The wrong arguments are passed, so we'll exit the script now!
		exit 1
	fi

	### SETTING VARIABLES BASED ON ARGUMENTS PASSED
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

	LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE dCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 showRug=TRUE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=FALSE bigDiamond=TRUE ymax=8 rfrows=10 refsnpLineWidth=2"

	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		### Which variant to look at.
		echo "We will lookup the following variants:"
		VARIANTLIST="${INPUTDIR}/${PHENOTYPE}.summary_results.QC.${CLUMP_R2}.indexvariants.txt" 
		while read VARIANTS; do 
			for VARIANT in ${VARIANTS}; do
			echo "* ${VARIANT}"
			done
		done < ${VARIANTLIST}

		echo ""
		N_VARIANTS=$(cat ${VARIANTLIST} | wc -l)
		echo "Number of variants to plot...: ${N_VARIANTS} variants"
		echo "Investigating range..........: ± ${RANGE}kb around each of these variants."
		
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
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.summary_results.QC.locuszoom
		zcat ${RESULTS} | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col RSID,P | tail -n +2 >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.summary_results.QC.locuszoom
		while read VARIANTS; do
			for VARIANT in ${VARIANTS}; do
			
				echo "Plotting variant: ${VARIANT} ± ${RANGE}kb..."
				cd ${OUTPUTDIR}
				${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --flank ${RANGE}kb ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE} (${EXCLUSION})" ${LOCUSZOOM_SETTINGS}
			
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
		REGIONS_FILE="$3" # depends on arg3
		
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
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom
		zcat ${RESULTS} | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col RSID,P | tail -n +2 >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom
				
		while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
			
			LINE=${REGIONOFINTEREST}
			VARIANT=$(echo "${LINE}" | awk '{print $1}')
			CHR=$(echo "${LINE}" | awk '{print $2}')
			START=$(echo "${LINE}" | awk '{print $3}')
			END=$(echo "${LINE}" | awk '{print $4}')
			
			echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
			cd ${OUTPUTDIR}
			${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --chr ${CHR} --start ${START} --end ${END} ${LDMAP} theme=publication title="${VARIANT} in ${PHENOTYPE} (${EXCLUSION})" ${LOCUSZOOM_SETTINGS}

		done < ${REGIONS_FILE}		
		
		echo ""
		echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		
	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		### Determine the gene to look at		
		echo "We will plot regional association ± ${RANGE}kb around the following [ ${GENE} ]."
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
		echo "MarkerName P-value" > ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom
		zcat ${RESULTS} | ${GWASTOOLKITDIR}/SCRIPTS/parseTable.pl --col RSID,P | tail -n +2 >> ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom
		echo "Plotting variant: ${GENE}"
		
			cd ${OUTPUTDIR}
			${LOCUSZOOM13} --metal ${OUTPUTDIR}/${STUDY_TYPE}.${ANALYSIS_TYPE}.${REFERENCE}.${PHENOTYPE}.${EXCLUSION}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refgene ${GENE} --flank ${RANGELZ}kb ${LDMAP} theme=publication title="${GENE} in ${PHENOTYPE} (${EXCLUSION})" ${LOCUSZOOM_SETTINGS}
		
		echo ""
		echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
	else
		### If arguments are not met then this error message will be displayed 
		script_arguments_error_analysis_type
	fi

### END of if-else statement for the number of command-line arguments passed ###
fi

# script_copyright_message