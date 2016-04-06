#! /bin/bash
#
#$ -S /bin/bash
#$ -o /hpc/dhl_ec/Dropzone/lookup.data.output
#$ -e /hpc/dhl_ec/Dropzone/lookup.data.errors
#$ -q long
#$ -M s.w.vanderlaan-2@umcutrecht.nl
#$ -m ea
#$ -cwd
#
# lookup_data.sh
#
# Script to lookup results
#
######## EXAMPLE script + submission ########
### echo "sh lookup_data.sh `pwd`/phenotypes_cyto_blood.txt /hpc/dhl_ec/svanderlaan/projects/gwas_pp_aegs/1000g/_model2 `pwd`/20160129_snvs_cadlaspgc.txt `pwd`/lookup_pp VARIANT CADLASPGC aegscombo_pp_1kg_raw_gwasm2  \ " > lookup_snvs_cadlaspgc_CYTO.sh
### qsub -S /bin/bash -o lookup_snvs_cadlaspgc_CYTO.log -e lookup_snvs_cadlaspgc_CYTO.errors -q long -pe threaded 2 -M s.w.vanderlaan-2@umcutrecht.nl -m ea -cwd lookup_snvs_cadlaspgc_CYTO.sh

#############################################################################
# Clear the scene!
clear
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "             SCRIPT TO LOOKUP VARIANTS OR GENES IN (meta-)GWAS/VEGAS DATA"
echo ""
echo "You're here: "`pwd`
echo "Today's:" `date`
echo ""
echo "Version: LOOKUP_DATA.v2.0.20160203"
echo ""
echo "Last update: February 3rd, 2016"
echo "Written by: Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)"
echo ""
echo " Lookup variants in (imputed) ExomeChip or GWAS data, or lookup genes in VEGAS "
echo " results. "
echo ""
echo " The input files are assumed to be so-called *.CDAT.GZ files, i.e. gzipped dat-files, "
echo " with in column number 2 the SNPID, i.e. rs-number."
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 7 ]] 
then 
	echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "$(basename "$0") error! You must supply [7] arguments:"
	echo "- Argument #1 is path_to the phenotype file [PHENOTYPEFILE]."
	echo "- Argument #2 is path_to the RESULTS directory of your ([meta-])GWAS/VEGAS "
	echo "                analysis [INPUTDIR]."
	echo "- Argument #3 is path_to the lookup list - can be list of geneIDs of "
	echo "                variantIDs [LOOKUPLIST]."
	echo "- Argument #4 is path_to the OUTPUT directory of this lookup [OUTPUTDIR]."
	echo "- Argument #5 is TYPE of lookup [VARIANT/GENE]."
	echo "- Argument #6 is the PROJECT name (will be printed in output-filename)."
	echo "- Argument #7 is the results file BASEFILENAME (e.g. aegscombo_pp_1kg_raw_gwasm2)."
	echo "An example command would be: lookup_data.sh arg1 arg2 arg3 arg4 arg5 arg6 arg7"
	echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
else
	echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "All arguments are passed. These are the settings:"
	echo "The phenotype file.....................: "${1}
	echo "The results input directory is.........: "${2}
	echo "The lookup list is.....................: "${3}
	echo "The output directory is................: "${4}
	echo "The type of lookup is..................: "${5}
	echo "The project name is....................: "${6}
	echo "The results file basefilename is.......: "${7}
echo ""	
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### SETTING VARIABLES BASED ON ARGUMENTS PASSED
SOFTWARE=/hpc/local/CentOS6/dhl_ec/software
# Loading the phenotype file.
# This should be a space-delimited list of phenotypes PER line as they appear 
# in the results output-files, e.g. 
# 		Calcification_bin
# 		Collagen_bin 
# 		Fat10_bin
#
PHENOTYPESFILE=${1} # depends on arg1
echo "We will lookup the following phenotypes:"
while read PHENOTYPE; do 
	for i in ${PHENOTYPEs}; do
	echo "* ${i}"
	done
done < ${PHENOTYPESFILE}
echo "Total phenotypes processed: "
cat ${PHENOTYPESFILE} | wc -l
echo ""
# Loading the lookup list file
# This should be a space-delimited list of 1 variant or 1 gene PER line as they
# appear in the results output-files, e.g. 
#		rs12345
#		chr1:12345:C_AAC
# 
LOOKUP=${3} # depends on arg3 
echo "We will lookup the following variants/genes:"
while read VARIANTGENE; do 
	for i in ${VARIANTGENE}; do
	echo "* ${i}"
	done
done < ${LOOKUP}
echo "Total variants/genes processed: "
cat ${LOOKUP} | wc -l

# Setting the remaining variables
INPUTDIR=${2} # depends on arg2
OUTPUTDIR=${4} # depends on arg4
TYPE=${5} # depends on arg5
PROJECT=${6} # depends on arg6
BASEFILENAME=${7} # depends on arg7

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### SETTING THE TYPE OF LOOKUP DATA AS VARIABLES ###
### We have to set the type (variant or gene) lookup
	if [[ $TYPE = "VARIANT" ]]; then 
		echo "We are looking up variants in ExomeChip or GWAS results files. Initiating..."
		sleep 1s
		while read PHENOTYPES; do 
			for TRAIT in ${PHENOTYPES}; do
				echo "Lookup data for phenotype '${TRAIT}'."
				zcat ${INPUTDIR}/${BASEFILENAME}.${TRAIT}.cdat.gz | head -1 > ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt
				echo "Un-gzipping data..."
				gzip -dv ${INPUTDIR}/${BASEFILENAME}.${TRAIT}.cdat.gz 
				echo "Done. Processing results for '${TRAIT}'."
				$SOFTWARE/overlap.pl ${LOOKUP} 1 ${INPUTDIR}/${BASEFILENAME}.${TRAIT}.cdat 2 >> ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt
				echo "Done. Gzipping results for '${TRAIT}'."
				gzip -v ${INPUTDIR}/${BASEFILENAME}.${TRAIT}.cdat
				### START :: OLD BASH-AWK VERSION
				#while read VARIANT; do
				#	for v in ${VARIANT}; do
				#	echo "Looking for variant '${v}'."
				#	zcat ${INPUTDIR}/${BASEFILENAME}.${TRAIT}.cdat.gz | tail -n +2 | awk '( $2 == "'$v'" )' >> ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt
				#	done
				#done < ${LOOKUP}
				### END :: OLD BASH-AWK VERSION
				
				echo "Done looking up data for '${TRAIT}'."
				echo "Number of looked up variants: "
				cat ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt | tail -n +2 | wc -l
				echo "``````````````````````````````````````````````````"
			done
		done < ${PHENOTYPESFILE}
	elif [[ $TYPE = "GENES" ]]; then 
		echo "We are looking up genes in VEGAS output. Initiating..."
		sleep 1s	
		while read PHENOTYPES; do
			for TRAIT in ${PHENOTYPES}; do
				echo "THIS OPTION IS STILL IN BETA -- NOT WORKING!!!"
				echo "Lookup data for phenotype '${TRAIT}'."
				head -1 ${INPUTDIR}/${TRAIT}/{BASEFILENAME}.${TRAIT}.$EXTENSION > ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt
				while read GENE; do
					for v in ${GENE}; do
					echo "Looking for gene '${v}'."
				#head -1 $INPUTDIR/aegscombo_ppm2_"$i".assoc.dosage.VEGAS.out > $OUTPUTDIR/VEGAS.$i.$LOOKUP
				#grep -w -f $LOOKUP $INPUTDIR/aegscombo_ppm2_"$i".assoc.dosage.VEGAS.out >> $OUTPUTDIR/VEGAS.$i.$LOOKUP
					done
				done < $LOOKUP
				echo "Done looking up data for '${TRAIT}'."
				echo "Number of looked up genes: "
				cat ${OUTPUTDIR}/${TRAIT}.${PROJECT}.${TYPE}.txt | tail -n +2 | wc -l
				echo "``````````````````````````````````````````````````"
			done
		done < ${PHENOTYPESFILE}
	else
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo " Oh, computer says no! Argument not recognised. The options are: [VARIANT] to look up "
		echo " (a list of) individual variants; or [GENES] to look up (a list of) individual "
		echo " genes - note that you have to supply possible synonyms for a given gene. "
		echo " Script is terminated."
		echo ""
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		# The wrong arguments are passed, so we'll exit the script now!
		echo " Script was terminated, as the wrong arguments are passed. Refer to the "
		echo " error/output logs for more information..." 
		exit 1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	fi
echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
### END of if-else statement for the number of command-line arguments passed ###
fi 
date

