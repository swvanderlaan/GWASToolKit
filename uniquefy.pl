#!/usr/bin/perl
#
# Last update: 17 July 2006 by Paul de Bakker
#

$in = $ARGV[0];

open(IN, $in) || die("Cannot open $in");
while (<IN>) {
    chomp;
    @fields = split;
    if ( ! exists($seen_already{$fields[0]}) ) {
        print "$_\n";
        $seen_already{$fields[0]} = 1;
    } 
}
close IN;

