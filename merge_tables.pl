#!/usr/bin/env perl
#
# Merge two files into one.
#
# Description: 	merges two files based on some key-column into one file. The lines do not 
#               have to be sorted.
#				BETA: USE WITH EITHER OR BOTH FILES GZIPPED.
#
# Original written and published by:
# 		* Paul I.W. de Bakker, piwdebakker@mac.com
#		* 4 July 2014
# Written by:	Sander W. van der Laan; UMC Utrecht, Utrecht, the Netherlands; 
#               s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-02-17
#
# Usage:		perl merge_tables.pl --file1 [INPUT_FILE_1] --file2 [INPUT_FILE_2] --index [INDEX_STRING] --format [GZIP1/GZIP2/GZIPB/NORM] (optional: --replace)

# Starting merging
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+                                   MERGE TABLES FILES                                   +\n";
print STDERR "+                                           V1.0                                         +\n";
print STDERR "+                                         17-02-2016                                     +\n";
print STDERR "+                              Written by: Sander W. van der Laan                        +\n";
print STDERR "+                                                                                        +\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+ \n";
print STDERR "+ Hello. I am starting the merging of two files.\n";
my $time = localtime; # scalar, i.e. non-numeric, context
print STDERR "+ The current date and time is: $time.\n";
print STDERR "+ \n";

use strict;
use warnings;
use Getopt::Long;

# Four (or five) arguments are required: 
# - the first input file (FILE1)
# - the second input file (FILE2)
# - the index string
# - whether the input file is zipped (GZIP/NORM)
# - the output file (OUT)
my $Table1 = ""; # first argument
my $Table2 = ""; # second argument
my $IndexStr = ""; # third argument
my $zipped = ""; # fourth argument: four options: GZIP1 (first file gzipped) GZIP2 (second file gzipped) GZIPB (both files gzipped) NORM (none gzipped)
###my $outfile = "";
my $replace = ''; # fifth optional (!) argument

GetOptions(
           "index=s"     => \$IndexStr,
           "file1=s"     => \$Table1,
           "file2=s"     => \$Table2,
           "format=s"     => \$zipped,
           ###"out=s"     => \$outfile,
           "replace"     => \$replace
           );
# IF STATEMENT TO CHECK CORRECT INPUT
#if ( $IndexStr eq "" || $Table1 eq "" || $Table2 eq "" || $zipped eq "" || $outfile eq "" ) {
if ( $IndexStr eq "" || $Table1 eq "" || $Table2 eq "" || $zipped eq "" ) {
    print "Usage: %>merge_tables.pl --file1 datafile_1 --file2 datafile_2 --index index_string --format [GZIP1/GZIP2/GZIPB/NORM] [--replace]\n";
    print "";
    print "Prints all contents of datafile_2, each row is followed by the corresponding columns from datafile_1 (indexed on index_string).\n";
    print "The argument --format indicates which of the files are gzipped.\n";
    print "If --replace is specified, only the contents of datafile_2 are output with relevant elements replaced by those in datafile_1.\n";
    exit();
}

my @headers1 = ();
my %data1 = ();

### IF/ELSE STATEMENTS to determine the GZIPPED nature of the file1
if ($zipped eq "GZIP1" || $zipped eq "GZIPB" ) {
	open (T1, "gunzip -c $Table1 |") or die "*** ERROR ***  Couldn't open input file 1: $!";

} elsif ($zipped eq "NORM" || $zipped eq "GZIP2" ) {
	open (T1, $Table1) or die "*** ERROR *** Couldn't open input file 1: $!";

} else {
    die "*** ERROR ***  Please, indicate the type of input file: gzipped [GZIP1/2/B] or uncompressed [NORM]! (Arguments are case-sensitive.)\n";
}

my $linecount = -1;
my $IndexCol = -1;

while(my $c = <T1>) {
  $c=~s/\s+$//;
  $c=~s/^\s+//;
  my @fields = split /\s+/, $c;

  if ( $linecount == -1 ) {
    for (my $i=0; $i<=$#fields; $i++) {
      if ( $fields[$i] eq $IndexStr ) {
        if ( $IndexCol >= 0 ) {
          die "*** ERROR *** Duplicate index column $fields[$i] in $Table1 -- exiting.\n";
        }
        $IndexCol = $i;
      } 
      $headers1[$i] = $fields[$i];
    }
  }
  else {
    if ( $IndexCol == -1 ) {
      die "*** ERROR *** Did not find index column $IndexStr in $Table1 -- exiting.\n";
    }

    for (my $i=0; $i<=$#fields; $i++) {
      my $index = $fields[$IndexCol];
      if ( $index ne "NA" ) {
        $data1{$index}{$headers1[$i]} = $fields[$i];
      }
    }
  } 

  $linecount++;
}
close(T1);

print STDERR "*** Read $linecount lines from $Table1. \n";

### IF/ELSE STATEMENTS to determine the GZIPPED nature of the file2
if ($zipped eq "GZIP2" || $zipped eq "GZIPB" ) {
	open (T2, "gunzip -c $Table2 |") or die "*** ERROR ***  Couldn't open input file 2: $!";

} elsif ($zipped eq "NORM" || $zipped eq  "GZIP1" ) {
	open (T2, $Table2) or die "*** ERROR ***  Couldn't open input file 2: $!";

} else {
    die "*** ERROR ***  Please, indicate the type of input file: gzipped [GZIP1/2/B] or uncompressed [NORM]! (Arguments are case-sensitive.)\n";
}

#open (OUT, ">$outfile") or die "* ERROR: Couldn't open output file: $!"; 

my @headers2 = ();

$linecount = -1;
$IndexCol = -1;

while(my $c = <T2>) {
  $c=~s/\s+$//; #strip leading/trailing whitespace
  $c=~s/^\s+//;
  my @fields = split /\s+/, $c;

  if ( $linecount == -1 ) {
    for (my $i=0; $i<=$#fields; $i++) {
      if ( $fields[$i] eq $IndexStr ) {
        if ( $IndexCol >= 0 ) {
          die "*** ERROR *** Duplicate index column $fields[$i] in $Table2 -- exiting.\n";
        }
        $IndexCol = $i;
      }
      $headers2[$i] = $fields[$i];
      print "$fields[$i] ";
    }

    if ( $IndexCol == -1 ) {
      die "*** ERROR *** Did not find index column $IndexStr in $Table2 -- exiting.\n";
    }

    if ( ! $replace ) {
      foreach my $header1 ( @headers1 ) {
        if ( $header1 ne $IndexStr ) {
          print "$header1 ";
        }
      }
    }

    print "\n";
  }
  else {
    my $index = $fields[$IndexCol];

    if ( ! $replace ) { 
      for (my $i=0; $i<=$#fields; $i++) {
        print "$fields[$i] "; 
      } 
      foreach my $header1 ( @headers1 ) {
        if ( $header1 ne $IndexStr ) {
          if ( exists( $data1{$index}{$header1} ) ) { 
            print "$data1{$index}{$header1} ";
          } else {
            print "NA ";
          }
        }
      }
    }
    else { 
      for (my $i=0; $i<=$#fields; $i++) {
        my $header2 = $headers2[$i];
        if ( exists( $data1{$index}{$header2} ) ) {
          print "$data1{$index}{$header2} ";
        } else {
          print "$fields[$i] ";
        } 
      }
    }
    print "\n";
  }

  $linecount++;
}
close(T2);

print STDERR "*** Read $linecount lines from $Table2. \n";
print STDERR "+ \n";
print STDERR "+ Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print STDERR "+ The current date and time is: $newtime.\n";
print STDERR "+ \n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+ The MIT License (MIT)                                                                  +\n";
print STDERR "+ Copyright (c) 2016 Sander W. van der Laan                                              +\n";
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


