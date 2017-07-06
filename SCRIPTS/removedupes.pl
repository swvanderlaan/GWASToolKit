#!usr/bin/perl 
#
# Remove duplicate lines from a (gzipped) file.
#
# Description: 	removes duplicate lines from a (gzipped) file. The lines do not have to be
#               sorted.
#
# Written by:	Sander W. van der Laan; UMC Utrecht, Utrecht, the Netherlands; 
#               s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-01-28
#
# Usage:		removedupes.pl [INPUT] [GZIP/NORM] [OUTPUT]
#
# Starting removal
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+                                       REMOVE DUPES                                     +\n";
print "+                                           V2.0                                         +\n";
print "+                                         03-11-2016                                     +\n";
print "+                              Written by: Sander W. van der Laan                        +\n";
print "+                                                                                        +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "Hello. I am starting the removal of duplicate lines.\n";
my $time = localtime; # scalar, i.e. non-numeric, context
print "The current date and time is: $time.\n";
print "\n";

use strict;
use warnings;

# Three arguments are required: 
# - the input file (IN)
# - whether the input file is zipped (GZIP/NORM)
# - the output file (OUT)
my $origfile = $ARGV[0]; # first argument
my $zipped = $ARGV[1]; # second argument
my $outfile = $ARGV[2]; # third argument
my %hTMP;

# IF/ELSE STATEMENTS
if ($zipped eq "GZIP") {
	open (IN, "gunzip -c $origfile |") or die "* ERROR: Couldn't open input file: $!";

} elsif ($zipped eq "NORM") {
	open (IN, $origfile) or die "* ERROR: Couldn't open input file: $!";

} else {
    print "* ERROR: Please, indicate the type of input file: gzipped [GZIP] or uncompressed [NORM]!\n";
    print "         (Arguments are case-sensitive.)\n";

}
#my $fh, '>', 'report.txt'
open (OUT, ">$outfile") or die "* ERROR: Couldn't open output file: $!"; 
 
while (my $sLine = <IN>) {
  next if $sLine =~ m/^\s*$/;  #remove empty lines. Without this, still destroys empty lines except for the first one.
  $sLine=~s/^\s+//;            #strip leading/trailing whitespace
  $sLine=~s/\s+$//;
  print OUT qq{$sLine\n} unless ($hTMP{$sLine}++);
}
close OUT;
close IN;

print "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print "The current date and time is: $newtime.\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+ The MIT License (MIT)                                                                  +\n";
print "+ Copyright (c) 2016 Sander W. van der Laan                                              +\n";
print "+                                                                                        +\n";
print "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this   +\n";
print "+ software and associated documentation files (the \"Software\"), to deal in the           +\n";
print "+ Software without restriction, including without limitation the rights to use, copy,    +\n";
print "+ modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +\n";
print "+ and to permit persons to whom the Software is furnished to do so, subject to the       +\n";
print "+ following conditions:                                                                  +\n";
print "+                                                                                        +\n";
print "+ The above copyright notice and this permission notice shall be included in all copies  +\n";
print "+ or substantial portions of the Software.                                               +\n";
print "+                                                                                        +\n";
print "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,    +\n";
print "+ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +\n";
print "+ PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +\n";
print "+ HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +\n";
print "+ CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +\n";
print "+ OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +\n";
print "+                                                                                        +\n";
print "+ Reference: http://opensource.org.                                                      +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";



