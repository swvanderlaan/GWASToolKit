#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
#$ -S /bin/bash # the type of BASH you'd like to use
#$ -o /hpc/dhl_ec/svanderlaan/projects/4c/locuszoom_all_gwas_loci.log # the log file of this job
#$ -e /hpc/dhl_ec/svanderlaan/projects/4c/locuszoom_all_gwas_loci.errors # the error file of this job
#$ -q veryshort # which queue you'd like to use
#$ -pe threaded 1 # how many threads (1 = 15 Gb) you want for the job
#$ -M s.w.vanderlaan-2@umcutrecht.nl # you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
#$ -m ea # you can choose: b=begin of job; e=end of job; a=abort of job; s=
#$ -cwd # set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
# Further instructions: https://wiki.bioinformatics.umcutrecht.nl/bin/view/HPC/HowToS#Run_a_job_after_your_other_jobs
#
# The command 'clear' cleares the screen.
clear
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                           PLOT ALL LOCI FOR ALL GWAS"
echo "                             version 1.0 (20160208)"
echo ""
echo "* Written by  : Sander W. van der Laan"
echo "* E-mail      : s.w.vanderlaan-2@umcutrecht.nl"
echo "* Last update : 2016-02-08"
echo "* Version     : locuszoom_hits_region_v1_20160208"
echo ""
echo "* Description : This script will set some directories, execute something in a for "
echo "                loop, and will then submit this in a job."
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's: "`date`
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "The following directories are set."
# Software
SOFTWARE=/hpc/local/CentOS6/dhl_ec/software
LOCUSZOOM13=$SOFTWARE/locuszoom_1.3/bin/locuszoom
QCTOOL=$SOFTWARE/qctool_v1.5-linux-x86_64/qctool
# Imputed AEGS data
ORIGINALS_1kGp3GoNL5=/hpc/dhl_ec/data/_ae_originals/AEGS_COMBINED_IMPUTE2_1000Gp3_GoNL5
ORIGINALS_1kGp1=/hpc/dhl_ec/data/_ae_originals/AEGS_COMBINED_IMPUTE2_BBMRI_1000Gp1v3
ORIGINALS_GoNL4=/hpc/dhl_ec/data/_ae_originals/AEGS_COMBINED_IMPUTE2_BBMRI_GoNL4
# GWAS results
CARDIOGRAMplusC4D_1kG=/hpc/dhl_ec/data/_cardiogram/cardiogramplusc4d_1kg_cad_add #cad.add.160614.website.locuszoom
CARDIOGRAMplusC4D_HM2=/hpc/dhl_ec/data/_cardiogram #cardiogramgwas_plus_c4dmetabo.locuszoom
#METASTROKE_1kG=/hpc/dhl_ec/data/_metastroke/1000g #METAANALYSIS1_LAS.locuszoom
#METASTROKE_HM2=/hpc/dhl_ec/data/_metastroke/hapmap2 #LAS.locuszoom

# Project directories
PROJECT=/hpc/dhl_ec/svanderlaan/projects/4C

### Make directory
if [ ! -d ${PROJECT}/locuszoom/ ]; then
  mkdir -v ${PROJECT}/locuszoom/
fi
LOCUSZOOM=${PROJECT}/locuszoom

if [ ! -d $LOCUSZOOM/CAD/ ]; then
  mkdir -v $LOCUSZOOM/CAD/
fi
LZ_CAD=$LOCUSZOOM/CAD

if [ ! -d $LOCUSZOOM/CAD_HM2/ ]; then
  mkdir -v $LOCUSZOOM/CAD_HM2/
fi
LZ_CAD_HM2=$LOCUSZOOM/CAD_HM2

echo ""
echo " * Original 1000G (phase 1, version 3), 1kG (phase 3, version 5) + GoNL5, GoNL4 data:"
echo "  "$ORIGINALS_1kGp3GoNL5
echo "  "$ORIGINALS_1kGp1
echo "  "$ORIGINALS_GoNL4
echo " * Project directory:"
echo "  "${PROJECT}
echo ""
LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE dCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 showRug=TRUE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=FALSE bigDiamond=TRUE ymax=8 rfrows=10 refsnpLineWidth=2"

echo "LocusZoom settings: "$LOCUSZOOM_SETTINGS
echo ""

echo ""

REGIONS=${PROJECT}/regions_of_interest.txt
echo "Plotting this list of regions: "
cat ${PROJECT}/regions_of_interest.txt
cat ${PROJECT}/regions_of_interest.txt | wc -l

### HEADER
### rs2107595	7	19057977	19058556
### rs17114036	1	56960936	5696130
### rs9818870	3	138119792	138120191
### rs9369640	6	12903454	12903869

cd $LZ_CAD
echo "You are here:"
pwd
while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		LINE=${REGIONOFINTEREST}
		VARIANT=`echo "${LINE}" | awk '{print $1}'`
		CHR=`echo "${LINE}" | awk '{print $2}'`
		START=`echo "${LINE}" | awk '{print $3}'`
		END=`echo "${LINE}" | awk '{print $4}'`
		echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
		$LOCUSZOOM13 --metal $CARDIOGRAMplusC4D_1kG/cad.add.160614.website.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --chr ${CHR} --start ${START} --end ${END} --pop EUR --build hg19 --source 1000G_March2012 theme=publication title="${VARIANT} in CARDIoGRAMplusC4D (1kG)" ${LOCUSZOOM_SETTINGS}
done < ${REGIONS}

cd $LZ_CAD_HM2
echo "You are here:"
pwd
while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		LINE=${REGIONOFINTEREST}
		VARIANT=`echo "${LINE}" | awk '{print $1}'`
		CHR=`echo "${LINE}" | awk '{print $2}'`
		START=`echo "${LINE}" | awk '{print $3}'`
		END=`echo "${LINE}" | awk '{print $4}'`
		echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
		$LOCUSZOOM13 --metal $CARDIOGRAMplusC4D_HM2/cardiogramgwas_plus_c4dmetabo.locuszoom --markercol MarkerName --delim space --refsnp ${VARIANT} --chr ${CHR} --start ${START} --end ${END} --pop EUR --build hg19 --source 1000G_March2012 theme=publication title="${VARIANT} in CARDIoGRAMplusC4D (1kG)" ${LOCUSZOOM_SETTINGS}
done < ${REGIONS}

THISYEAR=$(date +'%Y')
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ The MIT License (MIT)                                                                                 +"
echo "+ Copyright (c) ${THISYEAR} Sander W. van der Laan                                                             +"
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