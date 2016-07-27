#! /bin/bash
#
# locuszoom_hits.sh
#
# Script to make LocusZoom plots of hits in meta-GWAS results
#
# author: Sander W. van der Laan
# date: 2016-02-02
# 
#
######## START EXAMPLE -- script + submission ########
### echo "sh locuszoom_hits.sh `pwd`/phenotypes.txt `pwd`/1000g/_model2 `pwd`/clumped_hits.txt aegscombo_pp_1kg_raw_gwasm2 acdat 2 19 \ " > locuszoom.aegspp1kg.sh
### qsub -S /bin/bash -N locuszoom_aegspp1kg -o locuszoom.aegspp1kg.output -e locuszoom.aegspp1kg.errors -q short -M s.w.vanderlaan-2@umcutrecht.nl -m a -cwd locuszoom.aegspp1kg.sh
######## END EXAMPLE ########

#############################################################################
# Clear the scene!
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                            SCRIPT TO MAKE LOCUSZOOM PLOTS FOR (meta-)GWAS HITS"
echo ""
echo " You're here: "`pwd`
echo " Today's:" `date`
echo ""
echo " Version: LOCUSZOOM_HITS.v1.2.20160202"
echo ""
echo " Last update: February 2nd, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)"
echo ""
echo " Description: Plot a LocusZoom for (imputed) (meta-)ExomeChip or (meta-)GWAS hits "
echo "              (determined after clumping!). For this you need to pass [7] arguments:"
echo ""
echo "	locuszoom_hits.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7"
echo "	- Argument #1 is path_to the phenotype file - should be a list of phenotype, with each phenotype "
echo "                on a new row (the last row should be empty). [PHENOTYPEFILE]"
echo "	- Argument #2 is path_to the RESULTS directory of your ([meta-])GWAS analysis. [INPUTDIR]"
echo "	- Argument #3 is path_to the lookup list - should be a list of variantIDs. [LOOKUPLIST]"
echo "	- Argument #4 is the results file BASEFILENAME (e.g. aegscombo_pp_1kg_raw_gwasm2)."
echo "	- Argument #5 is the results file EXTENSION is (e.g. cdat)."
echo "	- Argument #6 is the column number that holds the variantID (e.g. 2)."
echo "	- Argument #7 is the column number that holds the P-values (e.g. 19)."
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 7 ]] 
then 
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                  *** $(basename "$0") error ***"
	echo " Oh oh, computer says no! You must supply [7] arguments:"
	echo " - Argument #1 is path_to the phenotype file - should be a list of phenotype, with each phenotype "
	echo "               on a new row (the last row should be empty). [PHENOTYPEFILE]"
	echo " - Argument #2 is path_to the RESULTS directory of your ([meta-])GWAS analysis. [INPUTDIR]"
	echo " - Argument #3 is path_to the lookup list - can be list of geneIDs of variantIDs. [LOOKUPLIST]"
	echo " - Argument #4 is the results file BASEFILENAME (e.g. aegscombo_pp_1kg_raw_gwasm2) -- this"
	echo "               is used to 1) load the data and 2) write output with a similar name."
	echo " - Argument #5 is the results file EXTENSION is (e.g. out) -- this is used to "
	echo "               1) load the data and 2) write output with a similar name."
	echo " - Argument #6 is the column number that holds the variantID (e.g. 2)."
	echo " - Argument #7 is the column number that holds the P-values (e.g. 19)."
	echo " An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo " Today's: "`date`
	echo " Exiting..."
	# The wrong arguments are passed, so we'll exit the script now!
  		exit 0
else
	echo "All arguments are passed. These are the settings:"
	echo "The phenotype file.................................: "$1
	echo "The results input directory is.....................: "$2
	echo "The lookup list is.................................: "$3
	echo "The results file basefilename is...................: "$4
	echo "The results file extension is......................: "$5
	echo "The variantIDs to use by LocusZoom are in column...: "$6
	echo "The p-values to use by LocusZoom are in column.....: "$7
echo ""	
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### SETTING LOCUSZOOM
# Works for version 1.2 and version 1.3 is forthcoming.
LocusZoom_v12=/hpc/local/CentOS6/dhl_ec/software/locuszoom_1.2/bin/locuszoom
LocusZoom_v13=/hpc/local/CentOS6/dhl_ec/software/locuszoom_1.3/bin/locuszoom

### SETTING VARIABLES BASED ON ARGUMENTS PASSED
# Loading the phenotype file (should be a space-delimited list of phenotypes, 1 PER line as they appear 
# in the results output-files, e.g. 'Calcification_bin Collagen_bin Fat10_bin'). Can also be a file
# with just one phenotype - of course. 
PHENOTYPESFILE=$1 # depends on arg1
echo "We will lookup the following phenotypes:"
while read PHENOTYPE; do 
	for i in $PHENOTYPE; do
	echo "* "$i
	done
done < $PHENOTYPESFILE
echo ""
# Loading the lookup list file (should be a space-delimited list of variants, 1 PER line as they
# appear in the results output-files, e.g. 'rs12345 chr1:12345:C_AAC'). Can also be a file
# with just one variant - of course. 
LOOKUP=$3 # depends on arg3
echo "We will lookup the following variants/genes:"
while read VARIANTS; do 
	for i in $VARIANTS; do
	echo "* "$i
	done
done < $LOOKUP

# Setting the remaining variables
INPUTDIR=$2 # depends on arg2
# Plus make a new directory which will serve as the output directory!
if [ ! -d $INPUTDIR/locuszoom ]; then
  	echo ""
  	mkdir -v $INPUTDIR/locuszoom
  	OUTPUTDIR=$INPUTDIR/locuszoom
  	echo "The output directory is set...: "$OUTPUTDIR
else
	OUTPUTDIR=$INPUTDIR/locuszoom
  	echo "Output directory already exists...: "$OUTPUTDIR
fi
BASEFILENAME=$4 # depends on arg4
EXTENSION=$5 # depends on arg5
VARIANTID=$6 # depends on arg6
PVALUE=$7 # depends on arg7

echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Initiating lookup..."
echo ""	
while read PHENOTYPE; do 
	for i in $PHENOTYPE; do
		echo "Preparing LocusZoom input-file for phenotype: " $i
		### Making the output directory for the phenotype...
		if [ ! -d $OUTPUTDIR/$i ]; then
  			echo ""
  			mkdir -v $OUTPUTDIR/$i
		  	OUTPUTDIR_PHENOTYPE=$OUTPUTDIR/$i
  			echo "The output directory for the phenotype is set...: "$OUTPUTDIR_PHENOTYPE
		else
			OUTPUTDIR_PHENOTYPE=$OUTPUTDIR/$i
		  	echo "Output directory for the phenotype already exists...: "$OUTPUTDIR_PHENOTYPE
		fi
		### Making the input file for LocusZoom for the phenotype.
		### Example header of input file
		### MarkerName P-value
		### rs7098888 0.000686966
		### rs9733444 0.00149974
		echo "Making the LocusZoom input-file for the phenotype..."
		echo "MarkerName P-value" > $OUTPUTDIR_PHENOTYPE/$BASEFILENAME.$i.locuszoom
		tail -n +2 $INPUTDIR/$BASEFILENAME.$i.$EXTENSION | awk '{ print $'$VARIANTID', $'$PVALUE' }' >> $OUTPUTDIR_PHENOTYPE/$BASEFILENAME.$i.locuszoom
		while read VARIANT; do
			for HIT in $VARIANT; do
			echo "Plotting variant: " $HIT
			$LocusZoom_v12 --metal $OUTPUTDIR_PHENOTYPE/$BASEFILENAME.$i.locuszoom --markercol MarkerName --delim space --refsnp $HIT --flank 500kb --pop EUR --build hg19 --source 1000G_March2012 --prefix $OUTPUTDIR_PHENOTYPE/$BASEFILENAME.$i theme=publication showRecomb=TRUE dCol='r^2' ldColors="#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480" refsnpTextSize=0.8 showRug=TRUE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=FALSE bigDiamond=TRUE ymax=9
			done
		done < $LOOKUP
		echo "Done making regional association plots for "$i
		echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
	done
done < $PHENOTYPESFILE
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Today's: "`date`
### END of if-else statement for the number of command-line arguments passed ###
fi 

