#!/usr/bin/perl

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+                              CHECK NUMBER OF COLUMNS PER ROW                           +\n";
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

# VERSION 2
# source: http://stackoverflow.com/questions/18219823/perl-how-to-open-csv-file-count-how-many-rows-and-columns-it-has
##!/usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0]; # first argument 'test.txt';
my $line;
my $lines = 0;
my @columns;

open(my $fh, '<', $filename) or die "Can't open $filename: $!";

$line = <$fh>;
@columns = split(' ', $line);
$lines++ while <$fh>;
close $fh;

print "There were $lines lines in your file entitled $filename' and the number of columns is:\n";
print scalar @columns . " columns present.\n";
print "\n";
print "\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print "The current date and time is: $newtime.\n";
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



