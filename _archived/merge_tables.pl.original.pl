#!/usr/bin/env perl
#
# Author: Paul de Bakker, debakker@broad.mit.edu
#
# Last update: 4 July 2014
#

use strict;
use Getopt::Long;

my $Table1 = "";
my $Table2 = "";
my $IndexStr = "";
my $replace = '';

GetOptions(
           "index=s"     => \$IndexStr,
           "file1=s"     => \$Table1,
           "file2=s"     => \$Table2,
           "replace"     => \$replace
           );

if ( $IndexStr eq "" || $Table1 eq "" || $Table2 eq "" ) {
    print "usage: %>merge_tables.pl --file1 datafile_1 --file2 datafile_2 --index index_string [--replace]\n";
    print "Prints all contents of datafile_2, each row is followed by the corresponding columns from datafile_1 (indexed on index_string)\n";
    print "If --replace is specified, only the contents of datafile_2 are output with relevant elements replaced by those in datafile_1\n";
    exit();
}



my @headers1 = ();
my %data1 = ();
open(T1,$Table1);

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
          die "Duplicate index column $fields[$i] in $Table1 - exiting\n";
        }
        $IndexCol = $i;
      } 
      $headers1[$i] = $fields[$i];
    }
  }
  else {
    if ( $IndexCol == -1 ) {
      die "Did not find index column $IndexStr in $Table1 - exiting\n";
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

print STDERR "read $linecount lines from $Table1\n";

open(T2,$Table2);

my @headers2 = ();

$linecount = -1;
$IndexCol = -1;

while(my $c = <T2>) {
  $c=~s/\s+$//;
  $c=~s/^\s+//;
  my @fields = split /\s+/, $c;

  if ( $linecount == -1 ) {
    for (my $i=0; $i<=$#fields; $i++) {
      if ( $fields[$i] eq $IndexStr ) {
        if ( $IndexCol >= 0 ) {
          die "Duplicate index column $fields[$i] in $Table2 - exiting\n";
        }
        $IndexCol = $i;
      }
      $headers2[$i] = $fields[$i];
      print "$fields[$i] ";
    }

    if ( $IndexCol == -1 ) {
      die "Did not find index column $IndexStr in $Table2 - exiting\n";
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

print STDERR "read $linecount lines from $Table2\n";


