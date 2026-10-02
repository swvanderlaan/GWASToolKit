#!/bin/bash
#
#$ -S /bin/bash 																	# the type of BASH you'd like to use
#$ -N resource.creator  															# the name of this script
# -hold_jid some_other_basic_bash_script  											# the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
#$ -o /hpc/local/CentOS7/dhl_ec/software/GWASToolKit/resource.creator.log  		# the log file of this job
#$ -e /hpc/local/CentOS7/dhl_ec/software/GWASToolKit/resource.creator.errors	# the error file of this job
#$ -l h_rt=04:00:00  																# h_rt=[max time, e.g. 02:02:01] - this is the time you think the script will take
#$ -l h_vmem=8G  																	#  h_vmem=[max. mem, e.g. 45G] - this is the amount of memory you think your script will use
# -l tmpspace=64G  																	# this is the amount of temporary space you think your script will use
#$ -M s.w.vanderlaan-2@umcutrecht.nl  												# you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
#$ -m beas  																		# you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send
#$ -cwd  																			# set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# You can use the variables above (indicated by "#$") to set some things for the submission system.
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
#
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!

### Creating display functions
### Setting colouring
NONE='\033[00m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
STRIKETHROUGH='\033[9m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoitalic { 
    echo -e "${ITALIC}${1}${NONE}" 
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

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                      GWASToolKit: Resource Creator"
echobold ""
echobold "* Version:      v0.0.2"
echobold ""
echobold "* Last update:  2017-02-08"
echobold "* Written by:   Sander W. van der Laan | s.w.vanderlaan@gmail.com."
echobold "* Testers:      Jessica van Setten."
echobold "* Testers:      Tim Bezemer."
echobold "* Description:  Downloads, parses and creates the necessary resources for GWASToolKit."
echobold ""
echobold "* REQUIRED: "
echobold "  - A high-performance computer cluster with a qsub system"
echobold "  - R v3.2+, Python 2.7+, Perl."
echobold "  - Required Python 2.7+ modules: [pandas], [scipy], [numpy]."
echobold "  - Required Perl modules: [YAML], [Statistics::Distributions], [Getopt::Long]."
echobold "  - Note: it will also work on a Mac OS X system with R and Python installed."
### ADD-IN: function to check requirements...
### This might be a viable option! https://gist.github.com/JamieMason/4761049
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
##########################################################################################
### SET THE SCENE FOR THE SCRIPT
##########################################################################################

	# Where GWASToolKit resides
	SOFTWARE="/hpc/local/CentOS7/dhl_ec/software"
	GWASTOOLKIT="${SOFTWARE}/GWASToolKit"
	SCRIPTS=${GWASTOOLKIT}/SCRIPTS
	RESOURCES=${GWASTOOLKIT}/RESOURCES
# 	
# 	### THIS SHOULD BE A COMMAND LINE OPTION -- via a configuration file, but some how this screws up 'awking'
# 	### in the script below (lines 145, 232, 243)
# 	### "1Gp1          PAN, EUR, AFR, AMR, ASN\n";
# 	### "[1Gp3          PAN, EUR, AFR, AMR, EAS, SAS] - not available yet\n";
# 	### "[GoNL4         NL] - not available yet\n";
# 	### "[GoNL5         NL] - not available yet\n";
# 	### "[1Gp3GONL5     PAN] - not available yet\n";
# 	POPULATION="EUR"
# 	POPULATION1Gp3="EUR"
# 	
 
	echo ""
	echobold "#########################################################################################################"
	echobold "### *** WARNING *** NOT IMPLEMENTED YET DOWNLOADING HapMap 2 reference b36 hg18"
	echobold "#########################################################################################################"
	echobold "#"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Downloading and parsing 'HapMap 2 b36 hg18'. "

	echo ""	
	echo "All done submitting jobs for downloading and parsing HapMap 2 reference! 🖖"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo ""
	echobold "#########################################################################################################"
	echobold "### *** WARNING *** NOT IMPLEMENTED YET DOWNLOADING 1000G phase 1 and phase 3"
	echobold "#########################################################################################################"
	echobold "#"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Downloading and parsing '1000G phase 1 and phase 3'. "


	echo ""	
	echo "All done submitting jobs for downloading and parsing 1000G references! 🖖"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
	echo ""
	echobold "#########################################################################################################"
	echobold "### DOWNLOADING GENCODE and refseq gene lists"
	echobold "#########################################################################################################"
	echobold "#"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Downloading and parsing 'GENCODE and refseq gene lists'. "
	
	echo "* downloading [ GENCODE ] ... "
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/wgEncodeGencodeBasicV19.txt.gz -O ${RESOURCES}/GENCODE_wgEncodeBasicV19_GRCh37_hg19_Feb2009.txt.gz
	### HEAD
	### 585	ENST00000456328.2	chr1	+	11868	14409	11868	11868	3	11868,12612,13220,	12227,12721,14409,	0	DDX11L1	none	none	-1,-1,-1,
	### 585	ENST00000607096.1	chr1	+	30365	30503	30365	30365	1	30365,	30503,	0	MIR1302-11	none	none	-1,
	### 585	ENST00000417324.1	chr1	-	34553	36081	34553	34553	3	34553,35276,35720,	35174,35481,36081,	0	FAM138A	none	none	-1,-1,-1,
	### 585	ENST00000335137.3	chr1	+	69090	70008	69090	70008	1	69090,	70008,	0	OR4F5	cmpl	cmpl	0,
	
	echo "* parsing [ GENCODE ] ... "
	#zcat ${RESOURCES}/GENCODE_wgEncodeBasicV19_GRCh37_hg19_Feb2009.txt.gz | awk '{ print $3, $5, $6, $13, $2, $4}' | awk -F" " '{gsub(/chr/, "", $1)}1' | tail -n +2 > ${RESOURCES}/gencode_v19_GRCh37_hg19_Feb2009.txt 
	${RESOURCES}/parser.genelist.py ${RESOURCES}/GENCODE_wgEncodeBasicV19_GRCh37_hg19_Feb2009.txt.gz ${RESOURCES}/gencode_v19_GRCh37_hg19_Feb2009.txt
	#gzip -fv ${RESOURCES}/gencode_v19_GRCh37_hg19_Feb2009.txt 
	#rm -fv ${RESOURCES}/GENCODE_wgEncodeBasicV19_GRCh37_hg19_Feb2009.txt.gz
	
	echo "* downloading [ refseq ] ... "
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz -O ${RESOURCES}/refGene_GRCh37_hg19_Feb2009.txt.gz
	### HEAD
	### 585	NR_046018	chr1	+	11873	14409	14409	14409	3	11873,12612,13220,	12227,12721,14409,	0	DDX11L1	unk	unk	-1,-1,-1,
	### 585	NR_024540	chr1	-	14361	29370	29370	29370	11	14361,14969,15795,16606,16857,17232,17605,17914,18267,24737,29320,	14829,15038,15947,16765,17055,17368,17742,18061,18366,24891,29370,	0	WASH7P	unk	unk	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,

	echo "* parsing [ refseq ] ... "
	#zcat ${RESOURCES}/refGene_GRCh37_hg19_Feb2009.txt.gz | awk '{ print $3, $5, $6, $13, $2, $4 }' | awk -F" " '{gsub(/chr/, "", $1)}1' > ${RESOURCES}/refseq_GRCh37_hg19_Feb2009.txt
	#gzip -fv ${RESOURCES}/refseq_GRCh37_hg19_Feb2009.txt
	#rm -fv ${RESOURCES}/refGene_GRCh37_hg19_Feb2009.txt.gz
	${RESOURCES}/parser.genelist.py ${RESOURCES}/refGene_GRCh37_hg19_Feb2009.txt.gz ${RESOURCES}/refseq_GRCh37_hg19_Feb2009.txt

	echo ""	
	echo "All done submitting jobs for downloading and parsing gene lists! 🖖"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


script_copyright_message

