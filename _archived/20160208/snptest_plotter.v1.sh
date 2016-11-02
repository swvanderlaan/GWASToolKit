#! /bin/bash -x

# Clear the scene!
clear
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                        SNPTEST_PLOTTER.v1: PLOTTING OF SNPTEST ANALYSIS RESULTS"
echo ""
echo " You're here: "`pwd`
echo " Today's: " `date`
echo ""
echo " Version: SNPTEST_PLOTTER.v1.1.20160208"
echo ""
echo " Last update: February 8th, 2016"
echo " Written by:  Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl);"
echo ""
echo " Description: Plotting of a SNPTEST analysis: making Manhattan, Z-P, SE-N, and QQ plots."
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	
### Set the analysis type.
ANALYSIS_TYPE=${1} # depends on arg1

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 6 ]]; then 
	echo "Oh, computer says no! Argument not recognised: $(basename "${0}") error! You must supply [6] argument:"
	echo "- Argument #1 is path_to the output directory."
	echo "- Argument #2 is name of the phenotype."
	echo "- Argument #3 is minimum info-score [INFO]."
	echo "- Argument #4 is minimum minor allele count [MAC]."
	echo "- Argument #5 is minimum coded allele frequency [CAF]."
	echo "- Argument #6 is lower/upper limit of the BETA/SE [BETA_SE]."
	echo ""
	echo "An example command would be: snptest_pheno_wrapper.v1.sh [arg1: path_to_output_dir] [arg2: [PHENOTYPE] ] [arg3: [INFO] ] [arg4: [MAC] ] [arg5: [CAF] ] [arg6: [BETA_SE] ]"
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
	INFO=${3} # depends on arg3
	MAC=${4} # depends on arg4
	CAF=${5} # depends on arg5
	BETA_SE=${6} # depends on arg6
	echo "The output directory is...................: ${OUTPUT_DIR}"
	echo "The phenotypes is.........................: ${PHENOTYPE}"
	echo "The minimum info-score filter is..........: ${INFO}"
	echo "The minimum minor allele count is.........: ${MAC}"
	echo "The minimum coded allele frequency is.....: ${CAF}"
	echo "The lower/upper limit of the BETA/SE is...: ${BETA_SE}"
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
	RESULTS=${OUTPUT_DIR}/summary_results.txt.gz
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
	echo "Zipping up..."
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_CI.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_EAF.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QQplot_INFO.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_INFO.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Histogram_BETA.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.PZ_Plot.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.Manhattan_forQuickInspect.txt
	echo ""
	echo ""
	echo "/////////////////////////////////////////////////////////////////////////////////////////////////////////"
	echo "Plotting reformatted FILTERED data."
	echo ""
	echo "Filtering data, using the following criteria: "
	echo "  * ${INFO} <= INFO < 1 "
	echo "  * CAF > ${CAF} "
	echo "  * MAC >= ${MAC} "
	echo "  * BETA/SE/P != NA "
	echo "  * -${BETA_SE} <= BETA/SE < ${BETA_SE}. "
	zcat ${RESULTS} | head -1 > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt
	### COLUMN NAMES & NUMBERS
	###     1    2   3  4            5            6              7    8      9     10     11     12  13  14  15  16 17  18 19
	### ALTID RSID CHR BP OtherAlleleA CodedAlleleB AvgMaxPostCall Info all_AA all_AB all_BB TotalN MAC MAF CAF HWE P BETA SE
	zcat ${RESULTS} | awk '( $8 >= '${INFO}' && $8 < 1 && $13 >= '${MAC}' &&  $15 >= '${CAF}' && $17 != "NA" && $17 <= 1 && $17 >= 0 && $18 != "NA" && $18 < '${BETA_SE}' && $18 > -'${BETA_SE}' && $19 != "NA" && $19 < '${BETA_SE}' && $19 > -'${BETA_SE}' )' >> ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt
	echo "Number of QC'd variants:"
	cat ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt | wc -l
	echo "Head of QC'd file:"
	head ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt
	echo ""
	echo "Tail of QC'd file:"
	tail ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt
	echo ""
	echo ""
	#### QQ-plot including 95%CI and compute lambda [P]
	echo "Making QQ-plot including 95%CI and compute lambda..."
	tail -n +2 ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt | awk ' { print $17 } ' | grep -v NA > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.txt -PVAL -PDF -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.pdf ${MANTEL_SCRIPTS}/qqplot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.txt -PVAL -PNG -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.png ${MANTEL_SCRIPTS}/qqplot.R
	echo ""
	### Manhattan plot for publications [CHR, BP, P]
	echo "Manhattan plot for publications ..."
	tail -n +2 ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt | awk ' { print $3, $4, $17 } ' > ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt -PDF -FULL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.ManhattanFULL.pdf ${MANTEL_SCRIPTS}/manhattan_plot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt -PNG -FULL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.ManhattanFULL.png ${MANTEL_SCRIPTS}/manhattan_plot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt -PDF -TWOCOLOR -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.ManhattanTWOCOLOR.pdf ${MANTEL_SCRIPTS}/manhattan_plot.R
		R CMD BATCH -CL -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt -PNG -TWOCOLOR -${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.ManhattanTWOCOLOR.png ${MANTEL_SCRIPTS}/manhattan_plot.R
	echo "Finished plotting, zipping up and re-organising intermediate files!"
	echo "Zipping up..."
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.QQplot.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.Manhattan.txt
	gzip -v ${OUTPUT_DIR}/${PHENOTYPE}.${FILENAME}.QC.txt
	echo ""
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


