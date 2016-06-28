#!/usr/bin/perl

# Overlap some data with some other data
#
# Description: 	this script can overlap data. Provided with one file (LOOKUP.txt) it will
#               lookup something in [COLUMN#] in another file [SOURCE.txt] in a certain
#               [COLUMN#]. The whole line of the [SOURCE.txt] will be printed to the 
#               standard out
#
# Written by:	Jessica van Setten & Sander W. van der Laan; UMC Utrecht, Utrecht, the 
#               Netherlands, j.vansetten@umcutrecht.nl or s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-02-02
#
# Usage:		overlap.pl [LOOKUP.txt] [COLUMN#] [SOURCE.txt] [COLUMN#] []

# Starting conversion
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+                                        OVERLAP DATA                                    +\n";
print STDERR "+                                            V2.0                                        +\n";
print STDERR "+                                         28-06-2016                                     +\n";
print STDERR "+                  Written by: Jessica van Setten & Sander W. van der Laan               +\n";
print STDERR "+                                                                                        +\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "\n";
print STDERR "Hello. I am starting the overlapping of the files you've prodided.\n";
my $time = localtime; # scalar context
print STDERR "The current date and time is: $time.\n";
print STDERR "\n";

#use strict;
#use warnings; 
 
# Five arguments are required: 
# - the input file (IN)
# - column number in (IN)
# - the output file (SOURCE)
# - column number in (SOURCE)
# - whether the input file is zipped (GZIP/NORM)
my $file1 = $ARGV[0];
my $col1 = $ARGV[1];
my $file2 = $ARGV[2];
my $col2 = $ARGV[3];
my $neg = $ARGV[4];
###my $zipped = $ARGV[5];

my %present = ();

### IF/ELSE STATEMENTS
##if ($zipped eq "GZIP") {
##	open (IN, "gunzip -c $file1 |") or die "* ERROR: Couldn't open input file: $!";
##
##} elsif ($zipped eq "NORM") {
##	open (IN, $file1) or die "* ERROR: Couldn't open input file: $!";
##
##} else {
##    print "* ERROR: Please, indicate the type of input file: gzipped [GZIP] or uncompressed [NORM]!\n";
##    print "         (Arguments are case-sensitive.)\n";
##
##}

open (F1, $file1);
while(<F1>){
    chomp;
    @fields = split;
    $present{ $fields[$col1-1] } = 1;
}
close F1;

open (F2, $file2);
while (<F2>){
    chomp;
    @fields = split;
    if ( ( $neg eq "-v" && ! exists $present{$fields[$col2-1]} ) || ( $neg eq "" && exists $present{$fields[$col2-1]} ) ) { print "$_\n"; }
}
close F2;

print STDERR "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print STDERR "The current date and time is: $newtime.\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "\n";
print STDERR "\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+ The MIT License (MIT)                                                                  +\n";
print STDERR "+ Copyright (c) 2016 Jessica van Setten & Sander W. van der Laan                         +\n";
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




