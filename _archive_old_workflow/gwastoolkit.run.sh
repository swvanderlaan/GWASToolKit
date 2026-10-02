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

script_arguments_error() {
	echoerror "$1" # Additional message
	echoerror "- Argument #1 is path_to/filename of the configuration file."
	echoerror ""
	echoerror "An example command would be: gwastoolkit [arg1]"
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 	echo ""
	script_copyright_message
	exit 1
}

script_arguments_error_analysis_type() {
			echo "$1"
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument:"
			echo " * [GWAS]         -- genome-wide association study of traits in ${PHENOTYPE_FILE}."
			echo " * [VARIANT]      -- genetic analysis of variants in ${VARIANTLIST} for traits in ${PHENOTYPE_FILE}."
			echo " * [REGION]       -- genetic analysis of a specific region [chr${CHR}:${REGION_START}-${REGION_END}] for traits in ${PHENOTYPE_FILE}."
			echo " * [GENE]         -- genetic analysis of specific genes in ${GENES_FILE} for traits in ${PHENOTYPE_FILE}."
			echo ""
			echo " Please refer to instruction above."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			exit 1
}

script_arguments_error_gwas_type() {
			echo "$1"
			echo ""
			echo "      *** ERROR *** ERROR --- $(basename "${0}") --- ERROR *** ERROR ***"
			echo ""
			echo " You must supply the correct argument for GWAS:"
			echo " * [SNPTEST]      -- genome-wide association study of traits in ${PHENOTYPE_FILE} using SNPTEST."
			echo " * [REGENIE]      -- genome-wide association study of traits in ${PHENOTYPE_FILE} using REGENIE."
			echo ""
			echo " Please refer to instruction above."
			echo ""
			echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			# The wrong arguments are passed, so we'll exit the script now!
  			exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "                                               GWASTOOLKIT"
echobold "           individual variant, per-gene, regional, or genome-wide association study of a trait"
echobold ""
echobold " Version    : v1.4.4"
echobold ""
echobold " Last update: 2026-01-21"
echobold " Written by :  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)."
echobold ""
echobold " Testers:     - Saskia Haitjema (s.haitjema@umcutrecht.nl)"
echobold "              - Aisha Gohar (a.gohar@umcutrecht.nl)"
echobold "              - Jessica van Setten (j.vansetten@umcutrecht.nl)"
echobold "              - Tim Bezemer (t.bezemer-2@umcutrecht.nl)"
echobold "              - Lennart P.L. Landsmeer (l.p.l.landsmeer-2@umcutrecht.nl)"
echobold "              - Tim S. Peters (t.s.peters-4@umcutrecht.nl)"
echobold ""
echobold " Description: Perform individual variant, regional or genome-wide association "
echobold "              analysis on some phenotype(s). It will do the following:"
echobold "              - Run GWAS using SNPTESTv2.5.2+ and 1000G (phase 1), GoNL4, or "
echobold "                1000G (phase 3) + GoNL5 data per chromosome."
echobold "              - Collect results in one file upon completion of jobs."
echobold "              - Produce plots (PDF and PNG) for quick inspection and publication."
echobold "              - Lookup individual variant results in AEGS plaque phenotype GWAS."
echobold "              - Lookup gene results in AEGS plaque phenotype VEGAS results."
echobold "              - Lookup gene results in public GWAS VEGAS results."
echobold "              - Produce a ReadMe file."
echobold ""
echoerrorflashnooption "*Development Version Notes*"
echoerrorflashnooption "Pending imputation, analysis of chromosome X is not possible"
echoerrorflashnooption "First we will implement new SNPTEST flags (-[in]exclude_samples_where)."
echoerrorflashnooption "Second we will update to SLURM."
echoerrorflashnooption "An estimated timeline will be given in due time"
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

	### REQUIRED | GENERALS
	CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!

	# Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
	if [ ! -d ${PROJECTDIR}/${PROJECTNAME}/ ]; then
		mkdir -v ${PROJECTDIR}/${PROJECTNAME}/
		echo "The project-subdirectory is non-existent. Mr. Bourne will create it for you..."
	else
		echo "Your project-subdirectory already exists..."
	fi
	PROJECT=${PROJECTDIR}/${PROJECTNAME}

	# Using date to track an ANALYSIS

	DATE_TRACK=`printf '%(%Y%m%d_%H%M%S)T\n' -1`
	echo "${DATE_TRACK}"

	# Loading covariate and phenotype files
	PHENOTYPES=$(cat ${PHENOTYPE_FILE}) # which phenotypes to investigate anyway
	COVARIATES=$(cat ${COVARIATE_FILE}) # covariate list

	### RETURNING SETTINGS
	echo ""
	echo "-----------------------------------------"
	echo "            General settings"
	echo "-----------------------------------------"
	echo "The analysis scripts are located here...................................: ${GWASTOOLKITDIR}"
	echo "The following dataset will be used......................................: ${STUDY_TYPE}"
	echo "The following analysis type will be run.................................: ${ANALYSIS_TYPE}"
	if [[ ${ANALYSIS_TYPE} = "GWAS" ]]; then
		echo "The following GWAS method will be used.................................: ${GWAS_TYPE}"
	fi
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
		if [[ ${GWAS_TYPE} = "SNPTEST" ]]; then
			echo "Creating jobs to perform SNPTEST GWAS on your phenotype(s)..."
			### Sending analizer.sh to sbatch
			${GWASTOOLKITDIR}/gwastoolkit.analyzer.sh ${CONFIGURATIONFILE} ${DATE_TRACK}
			### Create QC bash-script to send to qsub
			for PHENOTYPE in ${PHENOTYPES}; do

				PHENO_OUTPUT_DIR=${PROJECT}/snptest_results/${PHENOTYPE}

				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.qc.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				### Submit QC script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_QC=$(sbatch --parsable -J QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:$(squeue --noheader --format %i --name ANALYZER.DONE.${DATE_TRACK}) -o ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWAS} -t ${QTIMEGWAS} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)
				echo ""

				### Create plotter bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.plotter.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				### Submit plotter script
				JOB_ID_PLOTTER=$(sbatch --parsable -J PLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:$(squeue --noheader --format %i --name ANALYZER.DONE.${DATE_TRACK}) -o ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWASPLOT} -t ${QTIMEGWASPLOT} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/plotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)
				echo ""

				### Create QC plotter bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.plotter.qc.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				### Submit QC plotter script
				JOB_ID_QCPLOTTER=$(sbatch --parsable -J QCPLOTTER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:${JOB_ID_QC} -o ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWASPLOTQC} -t ${QTIMEGWASPLOTQC} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qcplotter.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)
				echo ""

				#### Create clumper bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.clumper.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				#### Submit clumper script
				JOB_ID_CLUMPER=$(sbatch --parsable -J CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:${JOB_ID_QC} -o ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWASCLUMP} -t ${QTIMEGWASCLUMP} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/clumper.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)
				echo ""

				##### Create locuszoom bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.locuszoomer.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				##### Submit locuszoom script
				JOB_ID_LZ=$(sbatch --parsable -J LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:${JOB_ID_CLUMPER} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWASLZOOM} -t ${QTIMEGWASLZOOM} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)

				##### Create cleaner bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.cleaner.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
				##### Submit cleaner script
				JOB_ID_CLEANER=$(sbatch --parsable -J CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION} --depend=afterany:${JOB_ID_LZ} -o ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMGWASCLEANER} -t ${QTIMEGWASCLEANER} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)

			done

		elif [[ ${GWAS_TYPE} = "REGENIE" ]]; then
			echo "Creating jobs to perform REGENIE GWAS on your phenotype(s)..."

			### vcf.gx -> pgen ??

			### merge seperate pgen chromosomes into one

			### Create QC Pre-processing bash-script to send to sbatch
			echo "SUBMITTING JOB: Regenie Quality Control (Pre-processing)"
			printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.qc.sh ${CONFIGURATIONFILE} " > ${PROJECT}/regenie.qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
			### Submit QC Pre-processing script
			### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
			JOB_ID_QC=$(sbatch --parsable -J REGENIE.QC.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE} -t ${QTIMEGWASREGENIE} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
			echo ""

			##### Running REGENIE for BINARY Traits
			if [ -n "$PHENOTYPE_BINARY" ]; then
				echo "*** BINARY Phenotypes found ***"
				echo "-	SUBMITTING JOB: Regenie Step 1"
				##### Regenie step 1
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.step1.sh ${CONFIGURATIONFILE} BINARY " > ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_BT_STEP1=$(sbatch --parsable -J REGENIE.BT.STEP1.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_QC} -o ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE1} -t ${QTIMEGWASREGENIE1} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_BT_STEP1=$(sbatch --parsable -J REGENIE.BT.STEP1.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE1} -t ${QTIMEGWASREGENIE1} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""

				echo "-	SUBMITTING JOB: Regenie Step 2"
				##### Regenie step 2 
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.step2.sh ${CONFIGURATIONFILE} BINARY " > ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_BT_STEP2=$(sbatch --parsable -J REGENIE.BT.STEP2.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_REGENIE_BT_STEP1} -o ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE2} -t ${QTIMEGWASREGENIE2} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_BT_STEP2=$(sbatch --parsable -J REGENIE.BT.STEP2.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE2} -t ${QTIMEGWASREGENIE2} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""

				echo "-	SUBMITTING JOB: Regenie Wrapper"
				##### Regenie wrapup
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.wrapper.sh ${CONFIGURATIONFILE} BINARY " > ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_BT_WRAPPER=$(sbatch --parsable -J REGENIE.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_REGENIE_BT_STEP2} -o ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIEWRAP} -t ${QTIMEGWASREGENIEWRAP} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_BT_WRAPPER=$(sbatch --parsable -J REGENIE.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIEWRAP} -t ${QTIMEGWASREGENIEWRAP} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.BT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""
				echo ""
			else
				echo "*** No BINARY Phenotypes give ***"
				echo ""
			fi
			
			##### Running REGENIE for QUANTATIVE Traits
			if [ -n "$PHENOTYPE_QUANTATIVE" ]; then
				echo "*** QUANTATIVE Phenotypes found ***"
				echo "-	SUBMITTING JOB: Regenie Step 1"
				##### Regenie step 1
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.step1.sh ${CONFIGURATIONFILE} QUANTATIVE " > ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_QT_STEP1=$(sbatch --parsable -J REGENIE.QT.STEP1.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_QC} -o ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE1} -t ${QTIMEGWASREGENIE1} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_QT_STEP1=$(sbatch --parsable -J REGENIE.QT.STEP1.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE1} -t ${QTIMEGWASREGENIE1} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.step1.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""

				echo "-	SUBMITTING JOB: Regenie Step 2"
				##### Regenie step 2
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.step2.sh ${CONFIGURATIONFILE} QUANTATIVE " > ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_QT_STEP2=$(sbatch --parsable -J REGENIE.QT.STEP2.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_REGENIE_QT_STEP1} -o ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE2} -t ${QTIMEGWASREGENIE2} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_QT_STEP2=$(sbatch --parsable -J REGENIE.QT.STEP2.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIE2} -t ${QTIMEGWASREGENIE2} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.step2.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""

				echo "-	SUBMITTING JOB: Regenie Wrapper"
				##### Regenie wrapup
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.regenie.wrapper.sh ${CONFIGURATIONFILE} QUANTATIVE " > ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh
				### Submit QC Pre-processing script
				### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N SOMENAMEFORTHESCRIPT' are finished
				JOB_ID_REGENIE_QT_WRAPPER=$(sbatch --parsable -J REGENIE.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE} --depend=afterany:${JOB_ID_REGENIE_QT_STEP2} -o ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIEWRAP} -t ${QTIMEGWASREGENIEWRAP} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				
				# DEBUG
				# JOB_ID_REGENIE_QT_WRAPPER=$(sbatch --parsable -J REGENIE.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE} -o ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.log -e ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.errors --mem=${QMEMGWASREGENIEWRAP} -t ${QTIMEGWASREGENIEWRAP} -c 8 --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/regenie.QT.wrapper.${STUDY_TYPE}.${ANALYSIS_TYPE}.sh)
				echo ""
				echo ""
			else
				echo "No QUANTATIVE Phenotypes give"
				echo ""
			fi
		else
			### If arguments are not met then this error message will be displayed
			script_arguments_error_gwas_type

		fi

	elif [[ ${ANALYSIS_TYPE} = "VARIANT" ]]; then

    ### Sending analizer.sh
    ${GWASTOOLKITDIR}/gwastoolkit.analyzer.sh ${CONFIGURATIONFILE} ${DATE_TRACK}

    JOB_IDS_c=0
    ### This variable holds the Job_IDs which we will use for setting dependency on the wrapper script
    JOB_IDS_PHENO=""
		for PHENOTYPE in ${PHENOTYPES}; do

			PHENO_OUTPUT_DIR=${PROJECT}/snptest_results/${PHENOTYPE}

			##### Create cleaner bash-script to send to qsub
			printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.cleaner.sh ${CONFIGURATIONFILE} ${PHENOTYPE} " > ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh
			JOB_ID_CLEANER_i=$(sbatch --parsable -J CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} --depend=afterany:$(squeue --noheader --format %i --name ANALYZER.DONE.${DATE_TRACK}) -o ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.log -e ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.errors --mem=${QMEMVARCLEANER} -t ${QTIMEVARCLEANER} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.sh)
		if [[ ${JOB_IDS_c} == 0 ]]; then
			JOB_IDS_PHENO="${JOB_ID_CLEANER_i}"
			JOB_IDS_c=$((JOB_IDS_c + 1))
		else
			JOB_IDS_PHENO="${JOB_IDS_PHENO},${JOB_ID_CLEANER_i}"
			JOB_IDS_c=$((JOB_IDS_c + 1))
		fi
		done
			###### Create summariser bash-script to send to qsub -- SEE REMARKS ABOVE
			printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/summariser.sh ${CONFIGURATIONFILE} " > ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.sh
			###### Submit summariser script
			JOB_ID_SUMMARISER=$(sbatch  --parsable -J SUMMARISER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION} --depend=afterany:${JOB_IDS_PHENO} -o ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.log -e ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.errors --mem=${QMEMGWASLZOOM} -t ${QTIMEGWASLZOOM} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PROJECT} ${PROJECT}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.sh)

	elif [[ ${ANALYSIS_TYPE} = "REGION" ]]; then
		echo "Creating jobs to perform a regional analysis on your phenotype(s)..."
		${GWASTOOLKITDIR}/gwastoolkit.analyzer.sh ${CONFIGURATIONFILE} ${DATE_TRACK}

		echo ""
		echo "NOTE: no QC, plotting and cleaning is implemented yet. This will be there in the next version - similar to 'GENES' option."

	elif [[ ${ANALYSIS_TYPE} = "GENES" ]]; then
		echo "Creating jobs to perform a per-analysis on your phenotype(s)..."
		${GWASTOOLKITDIR}/gwastoolkit.analyzer.sh ${CONFIGURATIONFILE} ${DATE_TRACK}

	### Create QC bash-script to send to qsub
	JOB_IDS_c=0
	### This variable holds the Job_IDs which we will use for setting dependency on the wrapper script
	JOB_IDS_PHENO=""
		while IFS='' read -r GENEOFINTEREST || [[ -n "$GENEOFINTEREST" ]]; do
			for GENE in ${GENEOFINTEREST}; do
				for PHENOTYPE in ${PHENOTYPES}; do

					GENE_OUTPUT_DIR=${PROJECT}/snptest_results/${GENE}
					PHENO_OUTPUT_DIR=${GENE_OUTPUT_DIR}/${PHENOTYPE}

					##### Create qc bash-script to send to qsub
					printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.qc.sh ${CONFIGURATIONFILE} ${PHENOTYPE} ${GENE} " > ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh
					### Submit qc script
					### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N WRAP_UP.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
					JOB_ID_QC=$(sbatch --parsable -J QC.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE} --depend=afterany:$(squeue --noheader --format %i --name ANALYZER.DONE.${DATE_TRACK}) -o ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.errors --mem=${QMEMGENEQC} -t ${QTIMEGENEQC} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/qc.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh)

					##### Create locuszoom bash-script to send to qsub
					printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.locuszoomer.sh ${CONFIGURATIONFILE} ${PHENOTYPE} ${GENE} " > ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh
					##### Submit locuszoom script
					#### The option '-hold_jid' indicates that the following qsub will not start until all jobs with '-N CLUMPER.${STUDY_TYPE}.${ANALYSIS_TYPE}' are finished
					JOB_ID_LZ=$(sbatch --parsable -J LZ.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE} --depend=afterany:${JOB_ID_QC} -o ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.errors --mem=${QMEMGENELZOOM} -t ${QTIMEGENELZOOM} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/locuszoom.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh)

					##### Create cleaner bash-script to send to qsub
					printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/gwastoolkit.cleaner.sh ${CONFIGURATIONFILE} ${PHENOTYPE} ${GENE} " > ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh
					##### Submit cleaner script
					JOB_ID_CLEANER_i=$(sbatch --parsable -J CLEANER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE} --depend=afterany:${JOB_ID_LZ} -o ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.log -e ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.errors --mem=${QMEMGENECLEANER} -t ${QTIMEGENECLEANER} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${PHENO_OUTPUT_DIR} ${PHENO_OUTPUT_DIR}/cleaner.${STUDY_TYPE}.${ANALYSIS_TYPE}.${PHENOTYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh)
					echo ""
			if [[ ${JOB_IDS_c} == 0 ]]; then
				JOB_IDS_PHENO="${JOB_ID_CLEANER_i}"
				JOB_IDS_c=$((JOB_IDS_c + 1))
			else
				JOB_IDS_PHENO="${JOB_IDS_PHENO},${JOB_ID_CLEANER_i}"
				JOB_IDS_c=$((JOB_IDS_c + 1))
			fi
				done
			done
		done < ${GENES_FILE}

		while IFS='' read -r GENEOFINTEREST || [[ -n "$GENEOFINTEREST" ]]; do
			for GENE in ${GENEOFINTEREST}; do
				GENE_OUTPUT_DIR=${PROJECT}/snptest_results/${GENE}

				###### Create summariser bash-script to send to qsub
				printf "%s\n" "#!/bin/bash" "#" "${GWASTOOLKITDIR}/summariser.sh ${CONFIGURATIONFILE} ${GENE}" > ${GENE_OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh
				###### Submit summariser script
				sbatch  --parsable -J SUMMARISER.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE} --depend=afterany:${JOB_IDS_PHENO} -o ${GENE_OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE}.log -e ${GENE_OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE}.errors --mem=${QMEMGWASLZOOM} -t ${QTIMEGWASLZOOM} --mail-user=${YOUREMAIL} --mail-type=${MAILSETTINGS} -D ${GENE_OUTPUT_DIR} ${GENE_OUTPUT_DIR}/summariser.${STUDY_TYPE}.${ANALYSIS_TYPE}.${EXCLUSION}.${GENE}_${RANGE}.sh

			done
		done < ${GENES_FILE}

	else
		### If arguments are not met then this error message will be displayed
		script_arguments_error_analysis_type
	fi


	### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message
