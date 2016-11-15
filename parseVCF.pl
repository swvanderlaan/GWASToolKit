# Overlap some data with some other data
#
# Description: 	this script parse VCF files of 1000G phase 1 or phase 3. It will make a new 
#				file containing variantIDs, alleles and frequencies. Can be used to align
#				GWAS results in terms of allele coding, and variantID nomenclature.
#
# Written by:	Vinicius Tragante dó Ó & Sander W. van der Laan; UMC Utrecht, Utrecht, the 
#               Netherlands, v.tragantew@umcutrecht.nl or s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-11-15
#
# Usage:		parseVCF.pl --file [input.vcf.gz] --out [output.txt]

# Starting parsing
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+                                     PARSE VCF FILES                                    +\n";
print STDERR "+                                            V1.0                                        +\n";
print STDERR "+                                                                                        +\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "\n";
print STDERR "Hello. I am starting the overlapping of the files you've prodided.\n";
my $time = localtime; # scalar context
print STDERR "The current date and time is: $time.\n";
print STDERR "\n";

use strict;
use warnings;
use Getopt::Long;

### ARGUMENTS
# Two arguments are required: 
# - the input file (file)
# - the output file (output)
print STDERR "Reading options...\n";

my $file = "";
my $output = "";

GetOptions(
           "file=s"	=> \$file,
           "out=s"	=> \$output,
           );
# IF STATEMENT TO CHECK CORRECT INPUT
if ( $file eq "" || $output eq "" ) {
    print "Usage: %>parseVCF.pl --file input.vcf.gz --out output.txt\n";
    print "";
    print "Parses the input file, expected to be a VCF file (format 4.1+) and outputs a file containing allele frequencies, and alternate variantIDs.\n";
    exit();
}


#### SETTING OTHER VARIABLES -- see below for header of VCF-file
print STDERR "Setting variables...\n";

my $chr = "";
my $bp = "";
my $vid = ""; # 'rs[xxxx]' or 'chr[X]:bp[XXXXX]:A1_A2'
my $vid1 = ""; # 'rs[xxxx]' or 'chr[X]:bp[XXXXX]:[I/D]_[D/I]'
my $vid2 = ""; # 'rs[xxxx]' or '[X]:bp[XXXXX]:A1_A2'
my $vid3 = ""; # 'rs[xxxx]' or '[X]:bp[XXXXX]:[I/D]_[D/I]'
my $vid4 = ""; # '[X]:bp[XXXXX]:A1_A2'
my $vid5 = ""; # '[X]:bp[XXXXX]:[REF/I/D]_[ALT/D/I]'
my $vid6 = ""; # 'chr[X]:bp[XXXXX]:A1_A2'
my $vid7 = ""; # 'chr[X]:bp[XXXXX]:[REF/I/D]_[ALT/D/I]'
my $REF = ""; # reference allele
my $ALT = ""; # other allele
my $AlleleA = ""; # reference allele, with [REF/I/D] nomenclature
my $AlleleB = ""; # other allele, with [REF/I/D] nomenclature
my $INFO = "";
my $VT = ""; # type of variant
my $AF = "";
my $EURAF = "";
my $AFRAF = "";
my $AMRAF = "";
my $ASNAF = "";
my $EASAF = "";
my $SASAF = "";

#my $file = 'ALL.wgs.integrated_phase1_v3.20101123.snps_indels_sv.sites.vcf.gz';

### READING INPUT FILE
print STDERR "Reading input file...\n";
if ($file =~ /.gz$/) {
open(IN, "gunzip -c $file | grep -v '##' |") || die "* ERROR: Cannot open pipe to [ $file ]!";
}
else {
open(IN, $file) || die "* ERROR: Cannot open [ $file ]!";
}

### CREATING OUTPUT FILE
print STDERR "Creating output file...\n";
open(OUT, '>', $output) or die "* ERROR: Could not create the output file [ $output ]!";

print STDERR "* create header...\n";
print OUT "VariantID\tVariantID_alt1\tVariantID_alt2\tVariantID_alt3\tVariantID_alt4\tVariantID_alt5\tVariantID_alt6\tVariantID_alt7\tCHR\tBP\tREF\tALT\tAlleleA\tAlleleB\tVT\tAF\tEURAF\tAFRAF\tAMRAF\tASNAF\tEASAF\tSASAF\n";

print STDERR "* looping over file to extract relevant data...\n";
my $dummy=<IN>;
while (my $row = <IN>) {
	  chomp $row;
	  my @vareach=split(/(?<!,)\t/,$row); # splitting based on tab '\t'
	  $chr = $vareach[0]; # chromosome
	  $bp = $vareach[1]; # base pair position
	  $REF = $vareach[3]; # reference allele
	  $ALT = $vareach[4]; # alternate allele
	  $INFO = $vareach[7]; # info column -- refer to below for information

### get variant type
  if ($INFO =~ m/VT\=(SNP.*?)/){
  	$VT = "SNP";
  } elsif ($INFO =~ m/VT\=(INDEL.*?)/){
  		$VT = "INDEL"
  		} else {
  		$VT = "NA"
  		}

### get allele frequencies
  if ($INFO =~ m/\;AF\=(.*?)(;)/){
	$AF = $1;
  } else {
  	$AF = "NA"
  	}

### get asian allele frequencies -- 1000Gp1v3
  if ($INFO =~ m/ASN\_AF\=(.*?)(;)/){
	$ASNAF = $1;
  } else {
  	$ASNAF = "NA"
  	}

### get EAST asian allele frequencies -- 1000Gp3v5
  if ($INFO =~ m/EAS\_AF\=(.*?)(;)/){
	$EASAF = $1;
  } else {
  	$EASAF = "NA"
  	}
  	
### get SOUTH asian allele frequencies -- 1000Gp3v5
  if ($INFO =~ m/SAS\_AF\=(.*?)(;)/){
	$SASAF = $1;
  } else {
  	$SASAF = "NA"
  	}

### get european allele frequencies
  if ($INFO =~ m/EUR\_AF\=(.*?)(;)/){
	$EURAF = $1;
  } else {
  	$EURAF = "NA"
  	}

### get american allele frequencies
  if ($INFO =~ m/AMR\_AF\=(.*?)(;)/){
	$AMRAF = $1;
  } else {
  	$AMRAF = "NA"
  	}

### get african allele frequencies
  if ($INFO =~ m/AFR\_AF\=(.*?)(;)/){
	$AFRAF = $1;
  } else {
  	$AFRAF = "NA"
  	}

### adjust the key variantID -- # 'rs[xxxx]' or 'chr[X]:bp[XXXXX]:A1_A2'
  if ($vareach[2] =~ m/(\.)/){
  	$vid = "chr$chr\:$bp\:$REF\_$ALT";
  } else {
  	$vid = $vareach[2]
  	}

### adjust the key variantID1 -- # 'rs[xxxx]' or 'chr[X]:bp[XXXXX]:[I/D]_[D/I]'
  if ($vareach[2] =~ m/(\.)/ and length($REF) == 1 and length($ALT) == 1){
  	$vid1 = "chr$chr\:$bp\:$REF\_$ALT";
  	$AlleleA = "$REF";
  	$AlleleB = "$ALT";
  } elsif ($vareach[2] =~ m/(\.)/ and length($REF) > 1){ 
  		$vid1 = "chr$chr\:$bp\:I\_D";
	  	$AlleleA = "I";
  		$AlleleB = "D";
  		} elsif ($vareach[2] =~ m/(\.)/ and length($ALT) > 1){ 
  			$vid1 = "chr$chr\:$bp\:D\_I";
  			$AlleleA = "D";
	  		$AlleleB = "I";
  			} else { 
  				$vid1 = $vareach[2];
  				$AlleleA = "$REF";
		  		$AlleleB = "$ALT";
  				}

## adjust the key variantID2 -- # 'rs[xxxx]' or '[X]:bp[XXXXX]:A1_A2'
  if ($vareach[2] =~ m/(\.)/ and length($REF) == 1 and length($ALT) == 1){
  	$vid2 = "$chr\:$bp\:$REF\_$ALT";
  	$AlleleA = "$REF";
	$AlleleB = "$ALT";
  } elsif ($vareach[2] =~ m/(\.)/ and length($REF) > 1){ 
  		$vid2 = "$chr\:$bp\:$REF\_$ALT";
  		$AlleleA = "$REF";
		$AlleleB = "$ALT";
  		} elsif ($vareach[2] =~ m/(\.)/ and length($ALT) > 1){ 
  			$vid2 = "$chr\:$bp\:$REF\_$ALT";
  			$AlleleA = "$REF";
		  	$AlleleB = "$ALT";
  			} else { 
  				$vid2 = $vareach[2];
  				$AlleleA = "$REF";
		  		$AlleleB = "$ALT";
  				}
## adjust the key variantID3 -- # 'rs[xxxx]' or '[X]:bp[XXXXX]:[I/D]_[D/I]'
  if ($vareach[2] =~ m/(\.)/ and length($REF) == 1 and length($ALT) == 1){
  	$vid3 = "$chr\:$bp\:$REF\_$ALT";
  	$AlleleA = "$REF";
	$AlleleB = "$ALT";
  } elsif ($vareach[2] =~ m/(\.)/ and length($REF) > 1){ 
  		$vid3 = "$chr\:$bp\:I\_D";
  		$AlleleA = "I";
		$AlleleB = "D";
  		} elsif ($vareach[2] =~ m/(\.)/ and length($ALT) > 1){ 
  			$vid3 = "$chr\:$bp\:D\_I";
  			$AlleleA = "D";
		  	$AlleleB = "I";
  			} else { 
  				$vid3 = $vareach[2];
  				$AlleleA = "$REF";
		  		$AlleleB = "$ALT";
  				}
## adjust the key variantID4 -- # '[X]:bp[XXXXX]:A1_A2'
  	$vid4 = "$chr\:$bp\:$REF\_$ALT";

## adjust the key variantID5 -- # '[X]:bp[XXXXX]:[REF/I/D]_[ALT/D/I]'
  if (length($REF) == 1 and length($ALT) == 1){
  	$vid5 = "$chr\:$bp\:$REF\_$ALT";
  	$AlleleA = "$REF";
	$AlleleB = "$ALT";
  } elsif (length($REF) > 1){ 
  		$vid5 = "$chr\:$bp\:I\_D";
  		$AlleleA = "I";
		$AlleleB = "D";
  		} elsif (length($ALT) > 1){ 
  			$vid5 = "$chr\:$bp\:D\_I";
  			$AlleleA = "D";
		  	$AlleleB = "I";
  			} else { 
  				$vid5 = "$chr\:$bp\:$REF\_$ALT";
  				$AlleleA = "$REF";
		  		$AlleleB = "$ALT";
  				}
## adjust the key variantID6 -- # 'chr[X]:bp[XXXXX]:A1_A2'
  $vid6 = "chr$chr\:$bp\:$REF\_$ALT";
  
## adjust the key variantID7 -- # 'chr[X]:bp[XXXXX]:[REF/I/D]_[ALT/D/I]'
  if (length($REF) == 1 and length($ALT) == 1){
  	$vid7 = "chr$chr\:$bp\:$REF\_$ALT";
  	$AlleleA = "$REF";
	$AlleleB = "$ALT";
  } elsif (length($REF) > 1){ 
  		$vid7 = "chr$chr\:$bp\:I\_D";
  		$AlleleA = "I";
		$AlleleB = "D";
  		} elsif (length($ALT) > 1){ 
  			$vid7 = "chr$chr\:$bp\:D\_I";
  			$AlleleA = "D";
			$AlleleB = "I";
  			} else { 
  				$vid7 = "chr$chr\:$bp\:$REF\_$ALT";
  				$AlleleA = "$REF";
		  		$AlleleB = "$ALT";
  				}

print OUT "$vid\t$vid1\t$vid2\t$vid3\t$vid4\t$vid5\t$vid6\t$vid7\t$chr\t$bp\t$REF\t$ALT\t$AlleleA\t$AlleleB\t$VT\t$AF\t$EURAF\t$AFRAF\t$AMRAF\t$ASNAF\t$EASAF\t$SASAF\t\n";

}

close OUT;
close IN;

print STDERR "\n";
print STDERR "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print STDERR "The current date and time is: $newtime.\n";
print STDERR "\n";
print STDERR "\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+ The MIT License (MIT)                                                                  +\n";
print STDERR "+ Copyright (c) 2016 Vinicius Tragante dó Ó & Sander W. van der Laan                     +\n";
print STDERR "+                                                                                        +\n";
print STDERR "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this   +\n";
print STDERR "+ software and associated documentation files (the \"Software\"), to deal in the         +\n";
print STDERR "+ Software without restriction, including without limitation the rights to use, copy,    +\n";
print STDERR "+ modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +\n";
print STDERR "+ and to permit persons to whom the Software is furnished to do so, subject to the       +\n";
print STDERR "+ following conditions:                                                                  +\n";
print STDERR "+                                                                                        +\n";
print STDERR "+ The above copyright notice and this permission notice shall be included in all copies  +\n";
print STDERR "+ or substantial portions of the Software.                                               +\n";
print STDERR "+                                                                                        +\n";
print STDERR "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  +\n";
print STDERR "+ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +\n";
print STDERR "+ PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +\n";
print STDERR "+ HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +\n";
print STDERR "+ CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +\n";
print STDERR "+ OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +\n";
print STDERR "+                                                                                        +\n";
print STDERR "+ Reference: http://opensource.org.                                                      +\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";


### HEADER of VCF-file, version 4.1 -- 1000G, PHASE 1
### ##fileformat=VCFv4.1
### ##INFO=<ID=LDAF,Number=1,Type=Float,Description="MLE Allele Frequency Accounting for LD">
### ##INFO=<ID=AVGPOST,Number=1,Type=Float,Description="Average posterior probability from MaCH/Thunder">
### ##INFO=<ID=RSQ,Number=1,Type=Float,Description="Genotype imputation quality from MaCH/Thunder">
### ##INFO=<ID=ERATE,Number=1,Type=Float,Description="Per-marker Mutation rate from MaCH/Thunder">
### ##INFO=<ID=THETA,Number=1,Type=Float,Description="Per-marker Transition rate from MaCH/Thunder">
### ##INFO=<ID=CIEND,Number=2,Type=Integer,Description="Confidence interval around END for imprecise variants">
### ##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS for imprecise variants">
### ##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant described in this record">
### ##INFO=<ID=HOMLEN,Number=.,Type=Integer,Description="Length of base pair identical micro-homology at event breakpoints">
### ##INFO=<ID=HOMSEQ,Number=.,Type=String,Description="Sequence of base pair identical micro-homology at event breakpoints">
### ##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Difference in length between REF and ALT alleles">
### ##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
### ##INFO=<ID=AC,Number=.,Type=Integer,Description="Alternate Allele Count">
### ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total Allele Count">
### ##ALT=<ID=DEL,Description="Deletion">
### ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
### ##FORMAT=<ID=DS,Number=1,Type=Float,Description="Genotype dosage from MaCH/Thunder">
### ##FORMAT=<ID=GL,Number=.,Type=Float,Description="Genotype Likelihoods">
### ##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele, ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/technical/reference/ancestral_alignments/README">
### ##INFO=<ID=AF,Number=1,Type=Float,Description="Global Allele Frequency based on AC/AN">
### ##INFO=<ID=AMR_AF,Number=1,Type=Float,Description="Allele Frequency for samples from AMR based on AC/AN">
### ##INFO=<ID=ASN_AF,Number=1,Type=Float,Description="Allele Frequency for samples from ASN based on AC/AN">
### ##INFO=<ID=AFR_AF,Number=1,Type=Float,Description="Allele Frequency for samples from AFR based on AC/AN">
### ##INFO=<ID=EUR_AF,Number=1,Type=Float,Description="Allele Frequency for samples from EUR based on AC/AN">
### ##INFO=<ID=VT,Number=1,Type=String,Description="indicates what type of variant the line represents">
### ##INFO=<ID=SNPSOURCE,Number=.,Type=String,Description="indicates if a snp was called when analysing the low coverage or exome alignment data">
### ##reference=GRCh37
### #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO


### HEADER of VCF-file, version 4.1 -- 1000G, PHASE 3, VERSION 5
### ##fileformat=VCFv4.1
### ##FILTER=<ID=PASS,Description="All filters passed">
### ##fileDate=20150218
### ##reference=ftp://ftp.1000genomes.ebi.ac.uk//vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz
### ##source=1000GenomesPhase3Pipeline
### ##contig=<ID=1,assembly=b37,length=249250621>
### ##contig=<ID=2,assembly=b37,length=243199373>
### ##contig=<ID=3,assembly=b37,length=198022430>
### ##contig=<ID=4,assembly=b37,length=191154276>
### ##contig=<ID=5,assembly=b37,length=180915260>
### ##contig=<ID=6,assembly=b37,length=171115067>
### ##contig=<ID=7,assembly=b37,length=159138663>
### ##contig=<ID=8,assembly=b37,length=146364022>
### ##contig=<ID=9,assembly=b37,length=141213431>
### ##contig=<ID=10,assembly=b37,length=135534747>
### ##contig=<ID=11,assembly=b37,length=135006516>
### ##contig=<ID=12,assembly=b37,length=133851895>
### ##contig=<ID=13,assembly=b37,length=115169878>
### ##contig=<ID=14,assembly=b37,length=107349540>
### ##contig=<ID=15,assembly=b37,length=102531392>
### ##contig=<ID=16,assembly=b37,length=90354753>
### ##contig=<ID=17,assembly=b37,length=81195210>
### ##contig=<ID=18,assembly=b37,length=78077248>
### ##contig=<ID=19,assembly=b37,length=59128983>
### ##contig=<ID=20,assembly=b37,length=63025520>
### ##contig=<ID=21,assembly=b37,length=48129895>
### ##contig=<ID=22,assembly=b37,length=51304566>
### ##contig=<ID=GL000191.1,assembly=b37,length=106433>
### ##contig=<ID=GL000192.1,assembly=b37,length=547496>
### ##contig=<ID=GL000193.1,assembly=b37,length=189789>
### ##contig=<ID=GL000194.1,assembly=b37,length=191469>
### ##contig=<ID=GL000195.1,assembly=b37,length=182896>
### ##contig=<ID=GL000196.1,assembly=b37,length=38914>
### ##contig=<ID=GL000197.1,assembly=b37,length=37175>
### ##contig=<ID=GL000198.1,assembly=b37,length=90085>
### ##contig=<ID=GL000199.1,assembly=b37,length=169874>
### ##contig=<ID=GL000200.1,assembly=b37,length=187035>
### ##contig=<ID=GL000201.1,assembly=b37,length=36148>
### ##contig=<ID=GL000202.1,assembly=b37,length=40103>
### ##contig=<ID=GL000203.1,assembly=b37,length=37498>
### ##contig=<ID=GL000204.1,assembly=b37,length=81310>
### ##contig=<ID=GL000205.1,assembly=b37,length=174588>
### ##contig=<ID=GL000206.1,assembly=b37,length=41001>
### ##contig=<ID=GL000207.1,assembly=b37,length=4262>
### ##contig=<ID=GL000208.1,assembly=b37,length=92689>
### ##contig=<ID=GL000209.1,assembly=b37,length=159169>
### ##contig=<ID=GL000210.1,assembly=b37,length=27682>
### ##contig=<ID=GL000211.1,assembly=b37,length=166566>
### ##contig=<ID=GL000212.1,assembly=b37,length=186858>
### ##contig=<ID=GL000213.1,assembly=b37,length=164239>
### ##contig=<ID=GL000214.1,assembly=b37,length=137718>
### ##contig=<ID=GL000215.1,assembly=b37,length=172545>
### ##contig=<ID=GL000216.1,assembly=b37,length=172294>
### ##contig=<ID=GL000217.1,assembly=b37,length=172149>
### ##contig=<ID=GL000218.1,assembly=b37,length=161147>
### ##contig=<ID=GL000219.1,assembly=b37,length=179198>
### ##contig=<ID=GL000220.1,assembly=b37,length=161802>
### ##contig=<ID=GL000221.1,assembly=b37,length=155397>
### ##contig=<ID=GL000222.1,assembly=b37,length=186861>
### ##contig=<ID=GL000223.1,assembly=b37,length=180455>
### ##contig=<ID=GL000224.1,assembly=b37,length=179693>
### ##contig=<ID=GL000225.1,assembly=b37,length=211173>
### ##contig=<ID=GL000226.1,assembly=b37,length=15008>
### ##contig=<ID=GL000227.1,assembly=b37,length=128374>
### ##contig=<ID=GL000228.1,assembly=b37,length=129120>
### ##contig=<ID=GL000229.1,assembly=b37,length=19913>
### ##contig=<ID=GL000230.1,assembly=b37,length=43691>
### ##contig=<ID=GL000231.1,assembly=b37,length=27386>
### ##contig=<ID=GL000232.1,assembly=b37,length=40652>
### ##contig=<ID=GL000233.1,assembly=b37,length=45941>
### ##contig=<ID=GL000234.1,assembly=b37,length=40531>
### ##contig=<ID=GL000235.1,assembly=b37,length=34474>
### ##contig=<ID=GL000236.1,assembly=b37,length=41934>
### ##contig=<ID=GL000237.1,assembly=b37,length=45867>
### ##contig=<ID=GL000238.1,assembly=b37,length=39939>
### ##contig=<ID=GL000239.1,assembly=b37,length=33824>
### ##contig=<ID=GL000240.1,assembly=b37,length=41933>
### ##contig=<ID=GL000241.1,assembly=b37,length=42152>
### ##contig=<ID=GL000242.1,assembly=b37,length=43523>
### ##contig=<ID=GL000243.1,assembly=b37,length=43341>
### ##contig=<ID=GL000244.1,assembly=b37,length=39929>
### ##contig=<ID=GL000245.1,assembly=b37,length=36651>
### ##contig=<ID=GL000246.1,assembly=b37,length=38154>
### ##contig=<ID=GL000247.1,assembly=b37,length=36422>
### ##contig=<ID=GL000248.1,assembly=b37,length=39786>
### ##contig=<ID=GL000249.1,assembly=b37,length=38502>
### ##contig=<ID=MT,assembly=b37,length=16569>
### ##contig=<ID=NC_007605,assembly=b37,length=171823>
### ##contig=<ID=X,assembly=b37,length=155270560>
### ##contig=<ID=Y,assembly=b37,length=59373566>
### ##contig=<ID=hs37d5,assembly=b37,length=35477943>
### ##ALT=<ID=CNV,Description="Copy Number Polymorphism">
### ##ALT=<ID=DEL,Description="Deletion">
### ##ALT=<ID=DUP,Description="Duplication">
### ##ALT=<ID=INS:ME:ALU,Description="Insertion of ALU element">
### ##ALT=<ID=INS:ME:LINE1,Description="Insertion of LINE1 element">
### ##ALT=<ID=INS:ME:SVA,Description="Insertion of SVA element">
### ##ALT=<ID=INS:MT,Description="Nuclear Mitochondrial Insertion">
### ##ALT=<ID=INV,Description="Inversion">
### ##ALT=<ID=CN0,Description="Copy number allele: 0 copies">
### ##ALT=<ID=CN1,Description="Copy number allele: 1 copy">
### ##ALT=<ID=CN2,Description="Copy number allele: 2 copies">
### ##ALT=<ID=CN3,Description="Copy number allele: 3 copies">
### ##ALT=<ID=CN4,Description="Copy number allele: 4 copies">
### ##ALT=<ID=CN5,Description="Copy number allele: 5 copies">
### ##ALT=<ID=CN6,Description="Copy number allele: 6 copies">
### ##ALT=<ID=CN7,Description="Copy number allele: 7 copies">
### ##ALT=<ID=CN8,Description="Copy number allele: 8 copies">
### ##ALT=<ID=CN9,Description="Copy number allele: 9 copies">
### ##ALT=<ID=CN10,Description="Copy number allele: 10 copies">
### ##ALT=<ID=CN11,Description="Copy number allele: 11 copies">
### ##ALT=<ID=CN12,Description="Copy number allele: 12 copies">
### ##ALT=<ID=CN13,Description="Copy number allele: 13 copies">
### ##ALT=<ID=CN14,Description="Copy number allele: 14 copies">
### ##ALT=<ID=CN15,Description="Copy number allele: 15 copies">
### ##ALT=<ID=CN16,Description="Copy number allele: 16 copies">
### ##ALT=<ID=CN17,Description="Copy number allele: 17 copies">
### ##ALT=<ID=CN18,Description="Copy number allele: 18 copies">
### ##ALT=<ID=CN19,Description="Copy number allele: 19 copies">
### ##ALT=<ID=CN20,Description="Copy number allele: 20 copies">
### ##ALT=<ID=CN21,Description="Copy number allele: 21 copies">
### ##ALT=<ID=CN22,Description="Copy number allele: 22 copies">
### ##ALT=<ID=CN23,Description="Copy number allele: 23 copies">
### ##ALT=<ID=CN24,Description="Copy number allele: 24 copies">
### ##ALT=<ID=CN25,Description="Copy number allele: 25 copies">
### ##ALT=<ID=CN26,Description="Copy number allele: 26 copies">
### ##ALT=<ID=CN27,Description="Copy number allele: 27 copies">
### ##ALT=<ID=CN28,Description="Copy number allele: 28 copies">
### ##ALT=<ID=CN29,Description="Copy number allele: 29 copies">
### ##ALT=<ID=CN30,Description="Copy number allele: 30 copies">
### ##ALT=<ID=CN31,Description="Copy number allele: 31 copies">
### ##ALT=<ID=CN32,Description="Copy number allele: 32 copies">
### ##ALT=<ID=CN33,Description="Copy number allele: 33 copies">
### ##ALT=<ID=CN34,Description="Copy number allele: 34 copies">
### ##ALT=<ID=CN35,Description="Copy number allele: 35 copies">
### ##ALT=<ID=CN36,Description="Copy number allele: 36 copies">
### ##ALT=<ID=CN37,Description="Copy number allele: 37 copies">
### ##ALT=<ID=CN38,Description="Copy number allele: 38 copies">
### ##ALT=<ID=CN39,Description="Copy number allele: 39 copies">
### ##ALT=<ID=CN40,Description="Copy number allele: 40 copies">
### ##ALT=<ID=CN41,Description="Copy number allele: 41 copies">
### ##ALT=<ID=CN42,Description="Copy number allele: 42 copies">
### ##ALT=<ID=CN43,Description="Copy number allele: 43 copies">
### ##ALT=<ID=CN44,Description="Copy number allele: 44 copies">
### ##ALT=<ID=CN45,Description="Copy number allele: 45 copies">
### ##ALT=<ID=CN46,Description="Copy number allele: 46 copies">
### ##ALT=<ID=CN47,Description="Copy number allele: 47 copies">
### ##ALT=<ID=CN48,Description="Copy number allele: 48 copies">
### ##ALT=<ID=CN49,Description="Copy number allele: 49 copies">
### ##ALT=<ID=CN50,Description="Copy number allele: 50 copies">
### ##ALT=<ID=CN51,Description="Copy number allele: 51 copies">
### ##ALT=<ID=CN52,Description="Copy number allele: 52 copies">
### ##ALT=<ID=CN53,Description="Copy number allele: 53 copies">
### ##ALT=<ID=CN54,Description="Copy number allele: 54 copies">
### ##ALT=<ID=CN55,Description="Copy number allele: 55 copies">
### ##ALT=<ID=CN56,Description="Copy number allele: 56 copies">
### ##ALT=<ID=CN57,Description="Copy number allele: 57 copies">
### ##ALT=<ID=CN58,Description="Copy number allele: 58 copies">
### ##ALT=<ID=CN59,Description="Copy number allele: 59 copies">
### ##ALT=<ID=CN60,Description="Copy number allele: 60 copies">
### ##ALT=<ID=CN61,Description="Copy number allele: 61 copies">
### ##ALT=<ID=CN62,Description="Copy number allele: 62 copies">
### ##ALT=<ID=CN63,Description="Copy number allele: 63 copies">
### ##ALT=<ID=CN64,Description="Copy number allele: 64 copies">
### ##ALT=<ID=CN65,Description="Copy number allele: 65 copies">
### ##ALT=<ID=CN66,Description="Copy number allele: 66 copies">
### ##ALT=<ID=CN67,Description="Copy number allele: 67 copies">
### ##ALT=<ID=CN68,Description="Copy number allele: 68 copies">
### ##ALT=<ID=CN69,Description="Copy number allele: 69 copies">
### ##ALT=<ID=CN70,Description="Copy number allele: 70 copies">
### ##ALT=<ID=CN71,Description="Copy number allele: 71 copies">
### ##ALT=<ID=CN72,Description="Copy number allele: 72 copies">
### ##ALT=<ID=CN73,Description="Copy number allele: 73 copies">
### ##ALT=<ID=CN74,Description="Copy number allele: 74 copies">
### ##ALT=<ID=CN75,Description="Copy number allele: 75 copies">
### ##ALT=<ID=CN76,Description="Copy number allele: 76 copies">
### ##ALT=<ID=CN77,Description="Copy number allele: 77 copies">
### ##ALT=<ID=CN78,Description="Copy number allele: 78 copies">
### ##ALT=<ID=CN79,Description="Copy number allele: 79 copies">
### ##ALT=<ID=CN80,Description="Copy number allele: 80 copies">
### ##ALT=<ID=CN81,Description="Copy number allele: 81 copies">
### ##ALT=<ID=CN82,Description="Copy number allele: 82 copies">
### ##ALT=<ID=CN83,Description="Copy number allele: 83 copies">
### ##ALT=<ID=CN84,Description="Copy number allele: 84 copies">
### ##ALT=<ID=CN85,Description="Copy number allele: 85 copies">
### ##ALT=<ID=CN86,Description="Copy number allele: 86 copies">
### ##ALT=<ID=CN87,Description="Copy number allele: 87 copies">
### ##ALT=<ID=CN88,Description="Copy number allele: 88 copies">
### ##ALT=<ID=CN89,Description="Copy number allele: 89 copies">
### ##ALT=<ID=CN90,Description="Copy number allele: 90 copies">
### ##ALT=<ID=CN91,Description="Copy number allele: 91 copies">
### ##ALT=<ID=CN92,Description="Copy number allele: 92 copies">
### ##ALT=<ID=CN93,Description="Copy number allele: 93 copies">
### ##ALT=<ID=CN94,Description="Copy number allele: 94 copies">
### ##ALT=<ID=CN95,Description="Copy number allele: 95 copies">
### ##ALT=<ID=CN96,Description="Copy number allele: 96 copies">
### ##ALT=<ID=CN97,Description="Copy number allele: 97 copies">
### ##ALT=<ID=CN98,Description="Copy number allele: 98 copies">
### ##ALT=<ID=CN99,Description="Copy number allele: 99 copies">
### ##ALT=<ID=CN100,Description="Copy number allele: 100 copies">
### ##ALT=<ID=CN101,Description="Copy number allele: 101 copies">
### ##ALT=<ID=CN102,Description="Copy number allele: 102 copies">
### ##ALT=<ID=CN103,Description="Copy number allele: 103 copies">
### ##ALT=<ID=CN104,Description="Copy number allele: 104 copies">
### ##ALT=<ID=CN105,Description="Copy number allele: 105 copies">
### ##ALT=<ID=CN106,Description="Copy number allele: 106 copies">
### ##ALT=<ID=CN107,Description="Copy number allele: 107 copies">
### ##ALT=<ID=CN108,Description="Copy number allele: 108 copies">
### ##ALT=<ID=CN109,Description="Copy number allele: 109 copies">
### ##ALT=<ID=CN110,Description="Copy number allele: 110 copies">
### ##ALT=<ID=CN111,Description="Copy number allele: 111 copies">
### ##ALT=<ID=CN112,Description="Copy number allele: 112 copies">
### ##ALT=<ID=CN113,Description="Copy number allele: 113 copies">
### ##ALT=<ID=CN114,Description="Copy number allele: 114 copies">
### ##ALT=<ID=CN115,Description="Copy number allele: 115 copies">
### ##ALT=<ID=CN116,Description="Copy number allele: 116 copies">
### ##ALT=<ID=CN117,Description="Copy number allele: 117 copies">
### ##ALT=<ID=CN118,Description="Copy number allele: 118 copies">
### ##ALT=<ID=CN119,Description="Copy number allele: 119 copies">
### ##ALT=<ID=CN120,Description="Copy number allele: 120 copies">
### ##ALT=<ID=CN121,Description="Copy number allele: 121 copies">
### ##ALT=<ID=CN122,Description="Copy number allele: 122 copies">
### ##ALT=<ID=CN123,Description="Copy number allele: 123 copies">
### ##ALT=<ID=CN124,Description="Copy number allele: 124 copies">
### ##INFO=<ID=CIEND,Number=2,Type=Integer,Description="Confidence interval around END for imprecise variants">
### ##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS for imprecise variants">
### ##INFO=<ID=CS,Number=1,Type=String,Description="Source call set.">
### ##INFO=<ID=END,Number=1,Type=Integer,Description="End coordinate of this variant">
### ##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description="Imprecise structural variation">
### ##INFO=<ID=MC,Number=.,Type=String,Description="Merged calls.">
### ##INFO=<ID=MEINFO,Number=4,Type=String,Description="Mobile element info of the form NAME,START,END<POLARITY; If there is only 5' OR 3' support for this call, will be NULL NULL for START and END">
### ##INFO=<ID=MEND,Number=1,Type=Integer,Description="Mitochondrial end coordinate of inserted sequence">
### ##INFO=<ID=MLEN,Number=1,Type=Integer,Description="Estimated length of mitochondrial insert">
### ##INFO=<ID=MSTART,Number=1,Type=Integer,Description="Mitochondrial start coordinate of inserted sequence">
### ##INFO=<ID=SVLEN,Number=.,Type=Integer,Description="SV length. It is only calculated for structural variation MEIs. For other types of SVs, one may calculate the SV length by INFO:END-START+1, or by finding the difference between lengthes of REF and ALT alleles">
### ##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
### ##INFO=<ID=TSD,Number=1,Type=String,Description="Precise Target Site Duplication for bases, if unknown, value will be NULL">
### ##INFO=<ID=AC,Number=A,Type=Integer,Description="Total number of alternate alleles in called genotypes">
### ##INFO=<ID=AF,Number=A,Type=Float,Description="Estimated allele frequency in the range (0,1)">
### ##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of samples with data">
### ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
### ##INFO=<ID=EAS_AF,Number=A,Type=Float,Description="Allele frequency in the EAS populations calculated from AC and AN, in the range (0,1)">
### ##INFO=<ID=EUR_AF,Number=A,Type=Float,Description="Allele frequency in the EUR populations calculated from AC and AN, in the range (0,1)">
### ##INFO=<ID=AFR_AF,Number=A,Type=Float,Description="Allele frequency in the AFR populations calculated from AC and AN, in the range (0,1)">
### ##INFO=<ID=AMR_AF,Number=A,Type=Float,Description="Allele frequency in the AMR populations calculated from AC and AN, in the range (0,1)">
### ##INFO=<ID=SAS_AF,Number=A,Type=Float,Description="Allele frequency in the SAS populations calculated from AC and AN, in the range (0,1)">
### ##INFO=<ID=DP,Number=1,Type=Integer,Description="Total read depth; only low coverage data were counted towards the DP, exome data were not used">
### ##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele. Format: AA|REF|ALT|IndelType. AA: Ancestral allele, REF:Reference Allele, ALT:Alternate Allele, IndelType:Type of Indel (REF, ALT and IndelType are only defined for indels)">
### ##INFO=<ID=VT,Number=.,Type=String,Description="indicates what type of variant the line represents">
### ##INFO=<ID=EX_TARGET,Number=0,Type=Flag,Description="indicates whether a variant is within the exon pull down target boundaries">
### ##INFO=<ID=MULTI_ALLELIC,Number=0,Type=Flag,Description="indicates whether a site is multi-allelic">
### ##INFO=<ID=OLD_VARIANT,Number=1,Type=String,Description="old variant location. Format chrom:position:REF_allele/ALT_allele">
### #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
### 
### 