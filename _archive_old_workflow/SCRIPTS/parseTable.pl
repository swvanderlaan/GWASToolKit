#!/usr/bin/perl
#
##########################################################################################
#
# Version				: v1.1
#
# Last update			: 2017-04-24
# Updated by			: Sander W. van der Laan | s.w.vanderlaan@gmail.com.
# Originally written by	: Paul I.W. de Bakker | UMC Utrecht, p.i.w.debakker-2@umcutrecht.nl.
#
# Website				: http://www.atheroexpress.nl/software
#
# Given a space/tab delimited file as input, this script will collect the columns as 
# indicated by the comma-separated list after the '--col'-flag, and return these.
#
# Usage:		cat [table.txt] | parse.pl --col COL1[,COL2,COL3...]
#
##########################################################################################

use strict;
use Getopt::Long;

my @Columns = ();
my $Sep = " ";
my $noheader = '';

GetOptions(     
           "col=s"       => \@Columns,
           "sep=s"       => \$Sep, 
           "no-header"   => \$noheader 
           );

@Columns = split(/,/, join(',',@Columns));

if ( $#Columns < 0 ) {
    print "usage: %>parseTable.pl --col COL1[,COL2,COL3,...] \n";
    print "Prints specified columns from STDIN\n";
    exit();
}   

my @column_index = ();

for ( my $i=0; $i <= $#Columns; $i++ ) {
  $column_index[$i] = -1;
#  print "$Columns[$i] \n";
}


my $linecount = 0;

while(my $c = <STDIN>) {
  $c=~s/\s+$//;
  $c=~s/^\s+//;
  my @fields = split /\s+/, $c;

  if ( $linecount == 0 ) {
    for (my $i=0; $i<=$#fields; $i++) {
      for (my $j=0; $j<=$#Columns; $j++) {
        if ( $fields[$i] eq $Columns[$j] ) {
          $column_index[$j] = $i;  
          next;
        }
      } 
    }

    for (my $j=0; $j<=$#Columns; $j++) {
      if ( $column_index[$j] == -1 ) { die "*** ERROR *** $Columns[$j] is not recognized. Please double back.\n"; }
      if ( ! $noheader ) { 
        print STDOUT $j>0 ? $Sep : "", $Columns[$j];
      }
    }
    if ( ! $noheader ) { print STDOUT "\n"; }
  }
  else {
    for (my $i=0; $i<=$#Columns; $i++) {
      print STDOUT $i>0 ? $Sep : "", $fields[$column_index[$i]];
    }
    print STDOUT "\n";
  } 

  $linecount++;
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + The MIT License (MIT)                                                                  +
# + Copyright (c) 2016 Sander W. van der Laan                                              +
# +                                                                                        +
# + Permission is hereby granted, free of charge, to any person obtaining a copy of this   +
# + software and associated documentation files (the \"Software\"), to deal in the         +
# + Software without restriction, including without limitation the rights to use, copy,    +
# + modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +
# + and to permit persons to whom the Software is furnished to do so, subject to the       +
# + following conditions:                                                                  +
# +                                                                                        +
# + The above copyright notice and this permission notice shall be included in all copies  +
# + or substantial portions of the Software.                                               +
# +                                                                                        +
# + THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  +
# + INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +
# + PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +
# + HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +
# + CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +
# + OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +
# +                                                                                        +
# + Reference: http://opensource.org.                                                      +
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

