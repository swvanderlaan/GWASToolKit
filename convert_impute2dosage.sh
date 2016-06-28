#!/bin/bash
#
clear
echo "////////////////////////////////////////////////////////////////////////////////////"
echo "                            CONVERT IMPUTE2 TO DOSAGE"
echo "____________________________________________________________________________________"
echo "                              CONVERT_IMPUTE2DOSAGE"
echo "                                        --"
echo "                               version v1.1.20160628"
echo ""
echo ""
echo " Description: Convert IMPUTE2 data to PLINK-format, so 3 dosages (AA, AB, BB) to 1 "
echo "              1 dosage (B-allele) for PLINK usage. The resulting files can than be used"
echo "              used for polygenic scores analyses or regular PLINK-style association"
echo "              analyses with the --dosage flag."
echo "              Output will automatically be gzipped."
echo "              Files made:"
echo "              - *.dose.gz -- the new DOSAGE file in PLINK style"
echo "              - *.map     -- the new MAP file in PLINK style"
echo "              - *.fam     -- the new FAM file in PLINK style"
echo ""
echo " NOTES:       - A [*.gen.gz] extension, i.e. a gzipped [*.gen] file is expected."
echo "              - The FAM file only contains the sample IDs and has PID, MID, Sex and "
echo "                Phenotype set to -9."
echo ""
echo " Update date: 2016-06-28"
echo " Written by:  Sander W. van der Laan"
echo ""
echo "Today's "$(date)
echo "////////////////////////////////////////////////////////////////////////////////////"

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# != 3 ]] 
then 
	echo ""
	echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
	echo ""
	echo " You must supply [3] arguments:"
	echo " Argument #1 is [path_to/INPUT.gen] the IMPUTE2 dosage file which needs conversion."
	echo " Argument #2 is [path_to/OUTPUT] the output file - script will produce [path_to/OUTPUT].dose."
	echo " Argument #3 is the SNPID type to be used, either dbSNP rsID or "
	echo "                the chr:bp:A_B [CHRBP] convention."
	echo ""
	echo " An example command would be: convert_impute2dosage.sh arg1 arg2 arg3"
	echo ""
	echo "////////////////////////////////////////////////////////////////////////////////////"
	date
	exit 0
else
	echo ""
	echo "------------------------------------------------------------------------------------"
	echo "All arguments are passed, setting variables internally."
INPUT=$1 # depends on arg1
OUTPUT=$2 # depends on arg2
IMPLEMENTATION=$3 # depends on arg3
echo "Input file          : "${INPUT}
echo "Output file         : "${OUTPUT}
echo "Implementation type : "${IMPLEMENTATION}
echo ""
echo "------------------------------------------------------------------------------------"
echo "Converting..."
### CHECK IMPLEMENTATION IN UNIX/Mac OS X (Lion+)
# 1.	Unzips the IMPUTE2 file [--- !!! ASSUMES UNZIPPED FILE !!! ---]
# 2.	Implementation 1:
#			Prints the chromosome number, the SNP name (in Phase3 release, this is also 
#           the CHR, BP positions and alleles, CHR:BP:A_B, or it can be the dbSNP rsID), 
#           and the two alleles (A and B). This is done in the following order: 
#
#             CHR SNP alB alA
#
#           Since the dosages are referring to the B-allele, this is allele A1 in PLINK.
#			
#		Implementation 2:
#			As above, but the SNP name is only the CHR:BP:A_B convention.
#
# 3.	Iterates through the impute2 file and makes single-value dosage score for each 
#		line. This can be used with PLINK v1.07+, note that with large datasets, like
#		1000G imputed data or a large number of samples, one needs to use PLINK2.
# 4.	Gzips the output file. [--- !!! NOT IMPLEMENTED !!! ---]
#
# Fields in a regular IMPUTE2 .gen file are:
# - 1 CHR = chromosome
# - 2 altID = alternate SNP ID, indicates the ID of the SNP which was genotyped
# - 3 SNP = rsID or the CHR:BP:A_B convention
# - 4 BP = base pair position
# - 5 alA = allele A (other allele) > converted to A2
# - 6 alB = allele B (coded allele) > converted to A1
# - 7+ the remaining fields are the dosages of AA AB BB, i.e. A2A2, A2A1, A1A1 in other 
#		words the dosages refer to the B=A1 allele.
if [[ ${IMPLEMENTATION} = "CHRBP" ]]; then
	### IMPLEMENTATION 1 ###
	# make the dosage file, based on .gen file
	cat ${INPUT}.gen | awk '{ gsub("^0","",$1); print $0 }' | awk '{ printf "chr"$1":"$4":"$6"_"$5" "$6" "$5; for(i=7; i<NF; i+=3) { printf " "$(i+0)*0+$(i+1)*1+$(i+2)*2 }; printf "\n" }' > ${OUTPUT}.dose
	# make the map file, based on .gen file
	cat ${INPUT}.gen | awk '{ gsub("^0","",$1); print $0 }' | awk ' { print $1, "chr"$1":"$4":"$6"_"$5, 0, $4 } ' > ${OUTPUT}.map
	# make the fam file, based on sample file
	tail -n +3 ${INPUT}.sample | awk ' { print $1, $1, -9, -9, -9, -9 } ' > ${OUTPUT}.fam
elif [[ ${IMPLEMENTATION} = "RSID" ]]; then
    ### IMPLEMENTATION 2 ###
	# make the dosage file, based on .gen file
	cat ${INPUT}.gen | awk '{ printf $3" "$6" "$5; for(i=7; i<NF; i+=3) { printf " "$(i+0)*0+$(i+1)*1+$(i+2)*2 }; printf "\n" }' > ${OUTPUT}.dose
	# make the map file, based on .gen file
	cat ${INPUT}.gen | awk '{ gsub("^0","",$1); print $0 }' | awk ' { print $1, $3, 0, $4 } ' > ${OUTPUT}.map
	# make the fam file, based on sample file
	tail -n +3 ${INPUT}.sample | awk ' { print $1, $1, -9, -9, -9, -9 } ' > ${OUTPUT}.fam
else
	echo ""
	echo "      *** ERROR *** ERROR --- $(basename "$0") --- ERROR *** ERROR ***"
	echo ""
	echo " You must supply the correct third [3] argument:"
	echo " * [RSID] -- for the dbSNP rsID convention"
	echo " * [CHRBP] --  for the chr:bp:A_B convention "
	echo ""
	echo "////////////////////////////////////////////////////////////////////////////////////"
	date
	exit 0
fi
echo ""
echo "All's done. Let's have a beer, buddy."
echo ""
echo "    *** Thank you for using CONVERT_IMPUTE2DOSAGE - $(basename "$0") ***"
echo ""
echo "////////////////////////////////////////////////////////////////////////////////////"
echo ""
### END of if-else statement for the number of command-line arguments passed ###
fi 

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ The MIT License (MIT)                                                                  +"
echo "+ Copyright (c) 2016 Sander W. van der Laan                                              +"
echo "+                                                                                        +"
echo "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this   +"
echo "+ software and associated documentation files (the \"Software\"), to deal in the         +"
echo "+ Software without restriction, including without limitation the rights to use, copy,    +"
echo "+ modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +"
echo "+ and to permit persons to whom the Software is furnished to do so, subject to the       +"
echo "+ following conditions:                                                                  +"
echo "+                                                                                        +"
echo "+ The above copyright notice and this permission notice shall be included in all copies  +"
echo "+ or substantial portions of the Software.                                               +"
echo "+                                                                                        +"
echo "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  +"
echo "+ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +"
echo "+ PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +"
echo "+ HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +"
echo "+ CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +"
echo "+ OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +"
echo "+                                                                                        +"
echo "+ Reference: http://opensource.org.                                                      +"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


