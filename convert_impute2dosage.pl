#!usr/bin/perl 

# Convert IMPUTE2 to 1 dosage PLINK-format
#
# Description: 	convert IMPUTE2 data to PLINK-format, so 3 dosages (AA, AB, BB) to 1 
# 				dosage (B-allele) for PLINK usage. The resulting file can than be used
#				for polygenic scores or regular PLINK-style --dosage association analyses.
#
# Written by:	Jessica van Setten & Sander W. van der Laan; UMC Utrecht, Utrecht, the 
#               Netherlands, j.vansetten@umcutrecht.nl or s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-01-28
#
# Usage:		convert_impute2dosage.pl [INPUT.gen] [GZIP/NORM] [OUTPUT.dosage]

# Starting conversion
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+                                  CONVERT IMPUTE2DOSAGE                                 +\n";
print "+                                        Version 1.0                                     +\n";
print "+                                         28-01-2016                                     +\n";
print "+                  Written by: Jessica van Setten & Sander W. van der Laan               +\n";
print "+                                                                                        +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "Hello. I am starting the conversion of an IMPUTE2 .gen-file to a PLINK-style .dosage-file.\n";
my $time = localtime; # scalar context
print "The current date and time is: $time.\n";
print "\n";

use strict;
use warnings; 
# Three arguments are required: 
# - the input file (IN)
# - whether the input file is zipped (GZIP/NORM)
# - the output file (OUT)
my $file = $ARGV[0]; # first argument
my $zipped = $ARGV[1]; # second argument
my $output = $ARGV[2]; # third argument

# IF/ELSE STATEMENTS
if ($zipped eq "GZIP") {
	open (IN, "gunzip -c $file |") or die "* ERROR: Couldn't open input file: $!";

} elsif ($zipped eq "NORM") {
	open (IN, $file) or die "* ERROR: Couldn't open input file: $!";

} else {
    print "* ERROR: Please, indicate the type of input file: gzipped [GZIP] or uncompressed [NORM]!\n";
    print "         (Arguments are case-sensitive.)\n";

}


open (OUT, ">$output") or die "Couldn't open output file: $!";

while( <IN> ){

	next if $_ =~ /==>/;
	next unless /\S/;
	
	# Remove newline at end
	chomp; 
	
	# Read in values
	my @fields = split;
	
	# Describe the input file
	my $CHR = shift(@fields);
	my $altID = shift(@fields);
	my $SNP = shift(@fields);
	my $BP = shift(@fields);
	my $alA = shift(@fields);
	my $alB = shift(@fields);
	my @VALS = ();
		while (@fields){
		# Calculate the dosage; $val3 == BB, meaning the dosage will be relative to
		# the B-allele
		my $val1 = (shift(@fields))*0; # dosage AA
		my $val2 = (shift(@fields))*1; # dosage AB
		my $val3 = (shift(@fields))*2; # dosage BB
		my $valT = $val3 + $val2;
		push(@VALS, $valT);
		}
	# Print out the new data - per line
	print OUT "$SNP $alA $alB @VALS \n";
	}
close IN; # stop reading the input-file
close OUT; # stop writing the output-file

print "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print "The current date and time is: $newtime.\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+ The MIT License (MIT)                                                                  +\n";
print "+ Copyright (c) 2016 Jessica van Setten & Sander W. van der Laan                         +\n";
print "+                                                                                        +\n";
print "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this   +\n";
print "+ software and associated documentation files (the \"Software\"), to deal in the         +\n";
print "+ Software without restriction, including without limitation the rights to use, copy,    +\n";
print "+ modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +\n";
print "+ and to permit persons to whom the Software is furnished to do so, subject to the       +\n";
print "+ following conditions:                                                                  +\n";
print "+                                                                                        +\n";
print "+ The above copyright notice and this permission notice shall be included in all copies  +\n";
print "+ or substantial portions of the Software.                                               +\n";
print "+                                                                                        +\n";
print "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  +\n";
print "+ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +\n";
print "+ PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +\n";
print "+ HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +\n";
print "+ CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +\n";
print "+ OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +\n";
print "+                                                                                        +\n";
print "+ Reference: http://opensource.org.                                                      +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";


