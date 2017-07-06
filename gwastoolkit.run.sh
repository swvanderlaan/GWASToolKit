#!/bin/bash

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

# script_arguments_error() {
# 	echoerror "$1" # Additional message
# 	echoerror "- Argument #1 is path_to/filename of the configuration file."
# 	echoerror "- Argument #2 is path_to/filename of the list of GWAS files with names."
# 	echoerror "- Argument #3 is reference to use [1Gp1] for the QC and analysis."
# 	echoerror ""
# 	echoerror "An example command would be: run_metagwastoolkit.sh [arg1] [arg2] [arg3]"
# 	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#  	echo ""
# 	script_copyright_message
# 	exit 1
# }

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                               RUN_ANALYSIS"
echobold "           INDIVIDUAL VARIANT, PER-GENE, REGIONAL OR GENOME-WIDE ASSOCIATION STUDY ON A TRAIT"
echobold ""
echobold " Version    : v1.3.3"
echobold ""
echobold " Last update: 2017-07-07"
echobold " Written by :  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold ""
echobold " Description: Perform individual variant, regional or genome-wide association "
echobold "              analysis on some phenotype(s). It will do the following:"
echobold "              - Run GWAS using SNPTESTv2.5.2 and 1000G (phase 1), GoNL4, or "
echobold "                1000G (phase 3) + GoNL5 data per chromosome."
echobold "              - Collect results in one file upon completion of jobs."
echobold "              - Produce plots (PDF and PNG) for quick inspection and publication."
echobold "              - Lookup individual variant results in AEGS plaque phenotype GWAS."
echobold "              - Lookup gene results in AEGS plaque phenotype VEGAS results."
echobold "              - Lookup gene results in public GWAS VEGAS results."
echobold "              - Produce a ReadMe file."
echobold ""
echobold " REQUIRED: "
echobold " * A high-performance computer cluster with a qsub system."
echobold " * Imputed genotype data with 1000G[p1/p3]/GoNL[4/5] as reference."
echobold " * SNPTEST v2.5+"
echobold " * R v3.2+"
echobold ""
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


##########################################################################################
### SET THE SCENE FOR THE SCRIPT
##########################################################################################

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 1 ]]; then 
	echo ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echoerrorflash "               *** Oh, oh, computer says no! Number of arguments found "$#". ***"
	echoerror "You must supply [1] arguments when running *** GWASToolKit ***!"
	script_arguments_error
else
	echo "These are the "$#" arguments that passed:"
	echo "The configuration file.................: "$(basename ${1}) # argument 1
	
	### SETTING DIRECTORIES (from configuration file).
	# Loading the configuration file (please refer to the GWASToolKit-Manual for specifications of this file). 
	source "$1" # Depends on arg1.
	
	CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!

	### REQUIRED | GENERALS

	### SYSTEM REQUIRED | NEVER CHANGE
	SOFTWARE=${SOFTWARE}
	GWASTOOLKITDIR=${GWASTOOLKITDIR}
	GWASTOOLKITSCRIPTS=${GWASTOOLKITSCRIPTS}

	### PROJECT SETTINGS
	PROJECTROOT=${PROJECTDIR}
	PROJECTNAME=${PROJECTNAME}

	# Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
	if [ ! -d ${PROJECTROOT}/${PROJECTNAME}/ ]; then
		mkdir -v ${PROJECTROOT}/${PROJECTNAME}/
		echo "The project-subdirectory is non-existent. Mr. Bourne will create it for you..."
	else
		echo "Your project-subdirectory already exists..."
	fi
	PROJECT=${PROJECTROOT}/${PROJECTNAME}

	### ANALYSIS SETTINGS
	ANALYSIS_TYPE=${ANALYSIS_TYPE}
	STUDY_TYPE=${STUDY_TYPE}
	REFERENCE=${REFERENCE}
	METHOD=${METHOD}
	EXCLUSION=${EXCLUSION}

	TRAIT_TYPE="QUANT" # QUANT/BINARY
	### PHENOTYPES AND COVARIATES
	# Example phenotype-list format: -- should be 'binary' OR 'continuous'
	# BMI
	# CRP
	# TRAIT3
	if [[ ${TRAIT_TYPE} = "BINARY" ]]; then
		echo "Running a 'binary' analysis...setting the phenotype file appropriately."
		PHENOTYPE_FILE="${PROJECTROOT}/${PROJECTNAME}.phenotypes.bin.txt"
	elif [[ ${TRAIT_TYPE} = "QUANT" ]]; then
		echo "Running a 'quantitative' analysis...setting the phenotype file appropriately."
		PHENOTYPE_FILE="${PROJECTROOT}/${PROJECTNAME}.phenotypes.con.txt"
	else 
		### If arguments are not met than the 
		echo ""
		echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
		echo ""
		echo " You must supply the correct argument:"
		echo " * [BINARY]  -- to run a 'binary' analysis (e.g. on stroke cases vs. controls)."
		echo " * [QUANT]   -- to run a 'quantitative' analysis (e.g. on BMI)."
		echo ""
		echo " Please refer to instruction above."
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		# The wrong arguments are passed, so we'll exit the script now!
		date
		exit 1
	fi

	# Example covariate-list format:
	# COHORT Age sex PC1_2013 PC2_2013 PC3_2013 PC4_2013 PC5_2013 PC6_2013 PC7_2013 PC8_2013 PC9_2013 PC10_2013
	COVARIATE_FILE="${PROJECTROOT}/${PROJECTNAME}.covariates.txt"

	PHENOTYPES=$(cat ${PHENOTYPE_FILE}) # which phenotypes to investigate anyway
	COVARIATES=$(cat ${COVARIATE_FILE}) # covariate list

	### DEFINING QSUB SETTINGS
	# FOR GWAS
	QMEMGWAS="h_vmem=8G" # '8Gb' for GWAS; 
	QTIMEGWAS="h_rt=12:00:00" # 12 hours for GWAS; 
	QMEMGWASCLUMP="h_vmem=180G" # 180Gb needed for clumping;
	QTIMEGWASCLUMP="h_rt=48:00:00" # 12 hours for clumping;
	QMEMGWASPLOT="h_vmem=8G" # 4gb for snptest plotter;
	QTIMEGWASPLOT="h_rt=12:00:00" # 4 hours for plotter;
	QMEMGWASPLOTQC="h_vmem=8G" # 4gb for plotter qc;
	QTIMEGWASPLOTQC="h_rt=12:00:00" # 4 hours for plotter qc;
	QMEMGWASLZOOM="h_vmem=4G" # 4Gb needed for locuszoom;
	QTIMEGWASLZOOM="h_rt=01:00:00" # 15mins for locuszoom;
	QMEMGWASCLEANER="h_vmem=4G" # 4Gb needed for cleaner;
	QTIMEGWASCLEANER="h_rt=01:00:00" # 1hours to clean;

	# FOR VARIANT
	QMEMVAR="h_vmem=8G" # 8Gb for variants;
	QTIMEVAR="h_rt=00:15:00" # 15mins for variants;
	QMEMVARCLEANER="h_vmem=4G" # 4Gb needed for cleaner;
	QTIMEVARCLEANER="h_rt=01:00:00" # 1hours to clean;

	# FOR REGION
	QMEMREG="h_vmem=8G" # 8Gb for regions;
	QTIMEREG="h_rt=00:30:00" # 30mins for regions;
	QMEMREGCLEANER="h_vmem=4G" # 4Gb needed for cleaner;
	QTIMEREGCLEANER="h_rt=01:00:00" # 1hours to clean;

	# FOR GENE
	QMEMGENE="h_vmem=8G" # 8Gb for genes;
	QTIMEGENE="h_rt=00:30:00" # 30 minutes for genes;
	QMEMGENEQC="h_vmem=4G" # 4 Gb for snptest qc;
	QTIMEGENEQC="h_rt=00:30:00" # 30 minutes for snptest qc;
	QMEMGENELZOOM="h_vmem=4G" # 4Gb for locuszoom;
	QTIMEGENELZOOM="h_rt=00:15:00" #15mins for locuszoom;
	QMEMGENECLEANER="h_vmem=4G" # 4Gb needed for cleaner;
	QTIMEGENECLEANER="h_rt=01:00:00" # 1hours to clean;

	# MAILSETTINGS
	YOUREMAIL="s.w.vanderlaan-2@umcutrecht.nl" # you're e-mail address; you'll get an email when the job has ended or when it was aborted
	MAILSETTINGS="a" 
	# 'b' Mail is sent at the beginning of the job; 
	# 'e' Mail is sent at the end of the job; 
	# 'a' Mail is sent when the job is aborted or rescheduled.
	# 's' Mail is sent when the job is suspended;
	# 'n' No mail is sent.

 
	### ANALYSIS SPECIFIC ARGUMENTS
	# For per-variant analysis
	# EXAMPLE FORMAT
	# rs1234 1 12345567
	# rs5678 2 12345567
	# rs4321 14 12345567
	# rs9876 20 12345567
	VARIANTLIST="${PROJECTROOT}/${PROJECTNAME}.variantlist.txt"

	# For GWAS/REGION/GENE analysis
	LZVERSION="LZ13"
	RANGE="200000" # 500000=500kb, needed for GWAS (LocusZoom plots); and GENE analyses (analysis and LocusZoom plots)

	# For GWAS
	CLUMP_P2="1"
	CLUMP_P1="0.000005" # should be of the form 0.005 rather than 5e-3
	CLUMP_R2="0.2"
	CLUMP_KB="500"
	CLUMP_FIELD="P"
	STANDARDIZE="STANDARDIZE" # options: STANDARDIZE/RAW

	# For regional analysis
	CHR="none" # e.g. 1
	REGION_START="none" # e.g. 12345678
	REGION_END="none" # e.g. 87654321

	# For per-gene analysis
	GENES_FILE="${PROJECTROOT}/${PROJECTNAME}.genelist.txt"

	# Filter settings -- specifically, GWAS, GENE and REGIONAL analyses
	INFO="0.3"
	MAC="6"
	CAF="0.005"
	BETA_SE="100"

	### SYSTEM REQUIRED | NEVER CHANGE
	OUTPUT_DIR=${PROJECT}/snptest_results 
	VARIANTID="2"
	PVALUE="17"
	RANGELZ=$(expr "$RANGE" / 1000)

	### RETURNING SETTINGS
	echo "-----------------------------------------"
	echo "            General settings"
	echo "-----------------------------------------"
	echo "The analysis scripts are located here...................................: ${GWASTOOLKITSCRIPTS}"
	echo "The following dataset will be used......................................: ${STUDY_TYPE}"
	echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
	echo "The reference used, either 1kGp3v5+GoNL5, 1kGp1v3, GoNL4................: ${REFERENCE}"
	echo "The analysis will be run using the following method.....................: ${METHOD}"
	echo ""
	echo "-----------------------------------------"
	echo "        Project specific settings"
	echo "-----------------------------------------"
	echo "The project name is.....................................................: ${PROJECTNAME}"
	echo "The project directory is................................................: ${PROJECT}"
	echo "The following e-mail address will be used for communication.............: ${YOUREMAIL}"
	echo "These are you mailsettings..............................................: ${MAILSETTINGS}"
	echo "The analysis will be run using the following exclusion list.............: ${EXCLUSION}"
	echo "The analysis will be run using the following phenotypes.................: ${PHENOTYPE_FILE}"
	echo "The type of phenotypes..................................................: ${TRAIT_TYPE}"
	echo "The analysis will be run using the following covariates.................: ${COVARIATE_FILE}"
	echo "The minimum info-score filter is........................................: ${INFO}"
	echo "The minimum minor allele count is.......................................: ${MAC}"
	echo "The minimum coded allele frequency is...................................: ${CAF}"
	echo "The lower/upper limit of the BETA/SE is.................................: ${BETA_SE}"
	echo "Maximum (largest) p-value to clump......................................: ${CLUMP_P2}"
	echo "Minimum (smallest) p-value to clump.....................................: ${CLUMP_P1}"
	echo "R^2 to use for clumping.................................................: ${CLUMP_R2}"
	echo "The KB range used for clumping..........................................: ${CLUMP_KB}"
	echo "Indicate the name of the clumping field to use (default: p-value, P)....: ${CLUMP_FIELD}"
	echo "The method of handling the phenotype....................................: ${STANDARDIZE}"
	echo "The following list of variants will be analysed.........................: ${VARIANTLIST}"
	echo "The chromosomal region will be analysed.................................: chromosome ${CHR}:${REGION_START}-${REGION_END}"
	echo "The following genes will be analysed....................................: ${GENES_FILE}"
	echo "The following range around genes will be taken..........................: ${RANGE}"
	
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	### SUBMIT SNPTEST_PHENO

	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		echo "Creating jobs to perform GWAS on your phenotype(s)..."
		${GWASTOOLKITDIR}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMGWAS} ${QTIMEGWAS} ${YOUREMAIL} ${MAILSETTINGS} ${TRAIT_TYPE} ${STANDARDIZE}

		### Create QC bash-script to send to qsub
# 		for PHENOTYPE in ${PHENOTYPES}; do
# 	
# 			PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
# 	
# 			echo "${GWASTOOLKITDIR}/snptest_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${INFO} ${MAC} ${CAF} ${BETA_SE}" > ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			### Submit QC script
# 			### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
# 			qsub -S /bin/bash -N QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWAS} -l ${QTIMEGWAS} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			echo ""
# 
# 			### Create plotter bash-script to send to qsub
# 			echo "${GWASTOOLKITDIR}/snptest_plotter.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			### Submit plotter script
# 			qsub -S /bin/bash -N PLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASPLOT} -l ${QTIMEGWASPLOT} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			echo ""
# 
# 			### Create QC plotter bash-script to send to qsub
# 			echo "${GWASTOOLKITDIR}/snptest_plotter_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			### Submit QC plotter script
# 			qsub -S /bin/bash -N QCPLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASPLOTQC} -l ${QTIMEGWASPLOTQC} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			echo ""
# 
# 			#### Create clumper bash-script to send to qsub
# 			echo "${GWASTOOLKITDIR}/snptest_clumper.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${CLUMP_P1} ${CLUMP_P2} ${CLUMP_R2} ${CLUMP_KB} ${CLUMP_FIELD} ${REFERENCE}" > ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			#### Submit clumper script
# 			qsub -S /bin/bash -N CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASCLUMP} -l ${QTIMEGWASCLUMP} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			echo ""
# 	
# 			##### Create locuszoom bash-script to send to qsub
# 			echo "${GWASTOOLKITDIR}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION} ${PHENO_OUTPUT_DIR}/${PHENOTYPE}.summary_results.QC.${CLUMP_R2}.indexvariants.txt ${RANGE}" > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			##### Submit locuszoom script
# 			qsub -S /bin/bash -N LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 
# 			##### Create cleaner bash-script to send to qsub
# 			echo "${GWASTOOLKITDIR}/snptest_cleaner.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${EXCLUSION} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 			##### Submit cleaner script
# 			qsub -S /bin/bash -N CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASCLEANER} -l ${QTIMEGWASCLEANER} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
# 
# 		done

	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then

		echo "Creating jobs to perform an individual variant analysis on your phenotype(s)..."
		${GWASTOOLKITDIR}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMVAR} ${QTIMEVAR} ${YOUREMAIL} ${MAILSETTINGS} ${VARIANTLIST} ${TRAIT_TYPE}

		for PHENOTYPE in ${PHENOTYPES}; do
	
			PHENO_OUTPUT_DIR=${OUTPUT_DIR}/${PHENOTYPE}
	
			##### Create cleaner bash-script to send to qsub
			echo "${GWASTOOLKITDIR}/snptest_cleaner.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${EXCLUSION} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			qsub -S /bin/bash -N CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMVARCLEANER} -l ${QTIMEVARCLEANER} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		
		done
			###### Create summariser bash-script to send to qsub -- SEE REMARKS ABOVE
			echo "${GWASTOOLKITDIR}/summariser.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${OUTPUT_DIR} ${PROJECT} ${PHENOTYPE_FILE} ${TRAIT_TYPE}" > ${OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${TRAIT_TYPE}.${EXCLUSION}.sh
			###### Submit summariser script
			qsub -S /bin/bash -N SUMMARISER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${TRAIT_TYPE}.${EXCLUSION} -hold_jid CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} -o ${OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${TRAIT_TYPE}.${EXCLUSION}.log -e ${OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${OUTPUT_DIR} ${OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${TRAIT_TYPE}.${EXCLUSION}.sh

	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		echo "Creating jobs to perform a regional analysis on your phenotype(s)..."
		${GWASTOOLKITDIR}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMREG} ${QTIMEREG} ${YOUREMAIL} ${MAILSETTINGS} ${CHR} ${REGION_START} ${REGION_END} ${TRAIT_TYPE}

	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		echo "Creating jobs to perform a per-analysis on your phenotype(s)..."
		${GWASTOOLKITDIR}/snptest_pheno.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${METHOD} ${EXCLUSION} ${PHENOTYPE_FILE} ${COVARIATE_FILE} ${PROJECT} ${QMEMGENE} ${QTIMEGENE} ${YOUREMAIL} ${MAILSETTINGS} ${GENES_FILE} ${RANGE} ${TRAIT_TYPE}
 
		### Create QC bash-script to send to qsub
		while read GENES; do
			for GENE in ${GENES}; do
				echo "* ${GENE} ± ${RANGE}"
				for PHENOTYPE in ${PHENOTYPES}; do
 
					GENE_OUTPUT_DIR=${OUTPUT_DIR}/${GENE}
					PHENO_OUTPUT_DIR=${GENE_OUTPUT_DIR}/${PHENOTYPE}
				
					##### Create qc bash-script to send to qsub
					echo "${GWASTOOLKITDIR}/snptest_qc.v1.sh ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${INFO} ${MAC} ${CAF} ${BETA_SE}" > ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
					### Submit qc script
					### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
					qsub -S /bin/bash -N QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE} -o ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGENEQC} -l ${QTIMEGENEQC} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
	
					##### Create locuszoom bash-script to send to qsub
					echo "${GWASTOOLKITDIR}/locuszoom_hits.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} ${VARIANTID} ${PVALUE} ${LZVERSION} ${GENE} ${RANGELZ}" > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
					##### Submit locuszoom script
					#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
					qsub -S /bin/bash -N LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -hold_jid QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGENELZOOM} -l ${QTIMEGENELZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
					echo ""
				done
			done
		done < ${GENES_FILE}
	
		##### Create cleaner bash-script to send to qsub
		echo "${GWASTOOLKITDIR}/snptest_cleaner.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${EXCLUSION} ${PHENO_OUTPUT_DIR} ${PHENOTYPE} " > ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
		##### Submit cleaner script
		qsub -S /bin/bash -N CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} -hold_jid LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} -o ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors -l ${QMEMGENECLEANER} -l ${QTIMEGENECLEANER} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
	
		while read GENES; do
			for GENE in ${GENES}; do
				echo "* ${GENE} ± ${RANGE}"
				GENE_OUTPUT_DIR=${OUTPUT_DIR}/${GENE}
			
				###### Create summariser bash-script to send to qsub
				echo "${GWASTOOLKITDIR}/summariser.v1.sh ${ANALYSIS_TYPE} ${STUDY_TYPE} ${REFERENCE} ${GENE_OUTPUT_DIR} ${PROJECT} ${PHENOTYPE_FILE} ${TRAIT_TYPE} ${GENE}" > ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${GENE}.${TRAIT_TYPE}.${EXCLUSION}.sh
				###### Submit summariser script
				qsub -S /bin/bash -N SUMMARISER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${GENE}.${TRAIT_TYPE}.${EXCLUSION} -hold_jid CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} -o ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${GENE}.${TRAIT_TYPE}.${EXCLUSION}.log -e ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${GENE}.${TRAIT_TYPE}.${EXCLUSION}.errors -l ${QMEMGWASLZOOM} -l ${QTIMEGWASLZOOM} -M ${YOUREMAIL} -m ${MAILSETTINGS} -wd ${PROJECT} ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${GENE}.${TRAIT_TYPE}.${EXCLUSION}.sh
		
			done
		done < ${GENES_FILE}

	else
		### If arguments are not met than the 
		echo ""
		echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
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


	### END of if-else statement for the number of command-line arguments passed ###
fi 

script_copyright_message

### MoSCoW
### - make with arguments/configuration file
### - make parsing results dynamic - independent of 'TRAIT_TYPE'
### - add in VEGAS lookup function
### - add in fastQTLanalysis option
### - add in Variant summarizer (all results in one file)
### - add in readme-generator-function
### - add in gzipper-function
### - add in a function that checks whether the covariates & phenotypes files make sense:
###   * get median, mean, se, sd, min, max, counts
###   * remove covariates/phenotypes dynamically (±3sd?)

### Make a variant wrapper script
### for i in $(ls ../cad/snptest_results) ; do echo "* processing [ "$i" ]..."; echo "$i" >> phenotype.list; done
### echo "Phenotype ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE" > AEGS.VARIANT.1kGp3v5GoNL5.Summary.txt
### for i in $(cat phenotype.list); do echo "* processing [ "$i" ]..."; zcat AEGS.VARIANT.1kGp3v5GoNL5."$i".summary_results.txt.gz | tail -n +2 | awk -v pheno=$i '{ print pheno, $0 }' OFS=","  >> AEGS.VARIANT.1kGp3v5GoNL5.Summary.txt; done

#IN ALL CASES
#	UPON COMPLETION RUN fastQTL FOR mQTL
#	
#	AFTER fastQTL PRODUCE QC PLOTS
#	
#IN CASE OF GWAS
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA (LOOKUP SCRIPT)
#
#IN CASE OF REGION
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA
#	
#IN CASE OF VARIANT
#	
#	LOOKUP GENES IN VEGAS AEGS (LOOKUP SCRIPT)
#	
#	LOOKUP GENES IN VEGAS PUBLIC GWAS DATA (LOOKUP SCRIPT)
#	
#
#PRODUCE RELEVANT README
#
#GZIP
# Put all graphs in one document including readme.


### SET SOME VARIABLES
### This part will determine what lines below will be run.
