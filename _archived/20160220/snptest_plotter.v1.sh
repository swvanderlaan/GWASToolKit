#!/bin/bash

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                                             SNPTEST_PLOTTER.v1"
echo "                                  PLOTTING OF SNPTEST ANALYSIS RESULTS"
echo ""
echo " You're here: "`pwd`
echo " Today's: " `date`
echo ""
echo " Version: SNPTEST_PLOTTER.v1.20160218"
echo ""
echo " Last update: February 18th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl);"
echo ""
echo " Description: Plotting of a SNPTEST analysis: making Manhattan, Z-P, SE-N, and QQ plots."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 2 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [2] argument:"
	echo "- Argument #1 is path_to the output directory."
	echo "- Argument #2 is name of the phenotype."
	echo ""
	echo "An example command would be: snptest_pheno_wrapper.v1.sh [arg1: path_to_output_dir] [arg2: [PHENOTYPE] ] "
  	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	date
  	exit 1
else
	echo "All arguments are passed. These are the settings:"
	# set input-data
	OUTPUT_DIR=${1} # depends on arg1
	cd ${OUTPUT_DIR}
	PHENOTYPE=${2} # depends on arg2
	echo "The output directory is...................: ${OUTPUT_DIR}"
	echo "The phenotypes is.........................: ${PHENOTYPE}"
	echo ""	
	# PLOT GWAS RESULTS
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "                                    PLOTTING SNPTEST ANALYSIS RESULTS"
	echo ""
	echo "Please be patient...this can take a long time depending on the number of files."
	echo "We started at: "`date`
	echo ""
	MANTEL_SCRIPTS=/hpc/local/CentOS6/dhl_ec/software/MANTEL/SCRIPTS
	echo ""
	echo "Plotting reformatted UNFILTERED data. Processing the following dataset: "
	# what is the basename of the file?
	RESULTS=${OUTPUT_DIR}/*.summary_results.txt.gz
	FILENAME=$(basename ${RESULTS} .txt.gz)
	echo "The basename is: "${FILENAME}
	echo ""
	
	### COLUMN NAMES & NUMBERS
	###     1    2   3  4            5            6              7    8      9     10     11     12  13  14  15  16 17  18 19
	### ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE
	
	### QQ-plot including 95%CI and compute lambda [P]
	echo "Making QQ-plot including 95%CI and compute lambda..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $17 } ' | grep -v NA > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.txt -PVAL -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.pdf ${MANTEL_SCRIPTS}/qqplot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.txt -PVAL -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.png ${MANTEL_SCRIPTS}/qqplot.R
	echo ""
	### QQ-plot stratified by effect allele frequency [P, EAF]
	echo "QQ-plot stratified by effect allele frequency..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $17, $15 } ' | grep -v NA > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.txt -PVAL -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.pdf ${MANTEL_SCRIPTS}/qqplot_by_maf.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.txt -PVAL -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.png ${MANTEL_SCRIPTS}/qqplot_by_maf.R
	echo ""
	## QQ-plot stratified by imputation quality (info -- imputation quality) [P, INFO]
	echo "QQ-plot stratified by imputation quality..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $17, $8 } ' | grep -v NA > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.txt -PVAL -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.pdf ${MANTEL_SCRIPTS}/qqplot_by_info.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.txt -PVAL -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.png ${MANTEL_SCRIPTS}/qqplot_by_info.R
	echo ""
	### Plot the imputation quality (info) in a histogram [INFO]
	echo "Plot the imputation quality (info) in a histogram..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $8 } ' > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.txt 
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.txt -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.pdf ${MANTEL_SCRIPTS}/obsexp.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.txt -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.png ${MANTEL_SCRIPTS}/obsexp.R
	echo ""
	### Plot the BETAs in a histogram [BETA]
	echo "Plot the BETAs in a histogram..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $18 } ' > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.txt 
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.txt -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.pdf ${MANTEL_SCRIPTS}/histograms_beta.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.txt -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.png ${MANTEL_SCRIPTS}/histograms_beta.R
	echo ""
	### Plot the Z-score based p-value (calculated from beta/se) and P [BETA, SE, P]
	echo "Plot the Z-score based p-value (calculated from beta/se) and P..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $18, $19, $17 } ' > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.txt 
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.txt -PDF -500000 -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.pdf ${MANTEL_SCRIPTS}/p_z_plot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.txt -PNG -500000 -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.png ${MANTEL_SCRIPTS}/p_z_plot.R
	echo ""
	### Manhattan plot for quick inspection (truncated upto -log10(p-value)) [CHR, BP, P]
	echo "Manhattan plot for quick inspection (truncated upto -log10(p-value)=2)..."
	zcat ${RESULTS} | tail -n +2 | awk ' { print $3, $4, $17 } ' > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.txt -PDF -QC -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.pdf ${MANTEL_SCRIPTS}/manhattan_plot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.txt -PNG -QC -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.png ${MANTEL_SCRIPTS}/manhattan_plot.R
	echo "Finished plotting, zipping up and re-organising intermediate files!"
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.txt
	echo ""

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


