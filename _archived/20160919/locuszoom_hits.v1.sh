#! /bin/bash
#
# locuszoom_hits.sh
#
# Script to make LocusZoom plots of hits in meta-GWAS results
#
# author: Sander W. van der Laan
# date: 2016-02-04
# 
#
######## START EXAMPLE -- script + submission ########
### echo "sh locuszoom_hits.sh `pwd`/phenotypes.txt `pwd`/1000g/_model2 `pwd`/clumped_hits.txt aegscombo_pp_1kg_raw_gwasm2 acdat 2 19 \ " > locuszoom.aegspp1kg.sh
### qsub -S /bin/bash -N locuszoom_aegspp1kg -o locuszoom.aegspp1kg.output -e locuszoom.aegspp1kg.errors -q short -M s.w.vanderlaan-2@umcutrecht.nl -m a -cwd locuszoom.aegspp1kg.sh
######## END EXAMPLE ########

# Clear the scene!
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                            SCRIPT TO MAKE LOCUSZOOM PLOTS FOR (meta-)GWAS HITS"
echo ""
echo " You're here: "`pwd`
echo " Today's: " `date`
echo ""
echo " Version: LOCUSZOOM_HITS.v1.3.20160205"
echo ""
echo " Last update: February 5th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)"
echo ""
echo " Description: Plot a LocusZoom for (imputed) (meta-)ExomeChip or (meta-)GWAS hits "
echo "              (determined after clumping!). For this you need to pass [6] arguments:"
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 6 ]]; then 
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! "
	echo "You must supply at [6] arguments:"
	echo " - Argument #1 is path_to the RESULTS directory of your ([meta-])GWAS analysis. [INPUTDIR]"
	echo " - Argument #2 is path_to the lookup list - can be list of geneIDs of variantIDs. [LOOKUPLIST]"
	echo " - Argument #3 is the results file PHENOTYPE (e.g. EP_composite_LA.summary_results.QC) -- this"
	echo "               is used to 1) load the data and 2) write output with a similar name."
	echo " - Argument #4 is the column number that holds the variantID (e.g. 2)."
	echo " - Argument #5 is the column number that holds the P-values (e.g. 19)."
	echo " - Argument #6 to indicate which version of LocusZoom to use [LZ12/LZ13] | DEFAULT IS LZ13."
	echo " An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 "
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo " Today's: "`date`
	echo " Exiting..."
	# The wrong arguments are passed, so we'll exit the script now!
  	exit 1
else
	echo "All arguments are passed. These are the settings:"
	echo "The results input directory is.....................: ${1}"
	echo "The lookup list is.................................: ${2}"
	echo "The results file PHENOTYPE is......................: ${3}"
	echo "The variantIDs to use by LocusZoom are in column...: ${4}"
	echo "The p-values to use by LocusZoom are in column.....: ${5}"
	echo "We are going to use this version of LocusZoom......: ${6}"
echo ""	
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	### SETTING LOCUSZOOM
	# Works for version 1.2 and version 1.3 is forthcoming.
	LOCUSZOOM12=/hpc/local/CentOS6/dhl_ec/software/locuszoom_1.2/bin/locuszoom
	LOCUSZOOM13=/hpc/local/CentOS6/dhl_ec/software/locuszoom_1.3/bin/locuszoom
	
	### SETTING VARIABLES BASED ON ARGUMENTS PASSED
	# Setting the remaining variables
	INPUTDIR=${1} # depends on arg1
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

	# Loading the lookup list file (should be a space-delimited list of variants, 1 PER line as they
	# appear in the results output-files, e.g. 'rs12345 chr1:12345:C_AAC'). Can also be a file
	# with just one variant - of course. 
	LOOKUP=${2} # depends on arg2
	echo "We will lookup the following variants/genes:"
	while read VARIANTS; do 
		for HIT in ${VARIANTS}; do
		echo "* ${HIT}"
		done
	done < ${LOOKUP}
	
	PHENOTYPE=${3} # depends on arg3
	VARIANTID=${4} # depends on arg4
	PVALUE=${5} # depends on arg5
	LZVERSION=${6} # depends on arg6
	
	LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE dCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 showRug=TRUE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=FALSE bigDiamond=TRUE ymax=8 rfrows=10 refsnpLineWidth=2"

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
	echo "MarkerName P-value" > ${OUTPUTDIR}/${PHENOTYPE}.summary_results.QC.locuszoom
	zcat ${INPUTDIR}/${PHENOTYPE}.summary_results.QC.txt.gz | tail -n +2 | awk '{ print $'${VARIANTID}', $'${PVALUE}' }' >> ${OUTPUTDIR}/${PHENOTYPE}.summary_results.QC.locuszoom
	while read VARIANTS; do
		for HIT in ${VARIANTS}; do
			echo "Plotting variant: ${HIT}"
			if [[ ${LZVERSION} = "LZ13" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM13} --metal ${OUTPUTDIR}/${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${HIT} --flank 500kb --pop EUR --build hg19 --source 1000G_March2012 theme=publication title="${HIT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
			elif [[ ${LZVERSION} = "LZ12" ]]; then
				cd ${OUTPUTDIR}
				${LOCUSZOOM12} --metal ${OUTPUTDIR}/${PHENOTYPE}.summary_results.QC.locuszoom --markercol MarkerName --delim space --refsnp ${HIT} --flank 500kb --pop EUR --build hg19 --source 1000G_March2012 theme=publication title="${HIT} in ${PHENOTYPE}" ${LOCUSZOOM_SETTINGS}
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
	done < $LOOKUP
	echo ""
	echo "All finished. Done making regional association plots for ${PHENOTYPE} data."
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	date

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


