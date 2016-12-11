#!/usr/bin/perl

# Parse VCF file
#
# Description: 	this script will check which modules are installed, and installs required
#               modules where needed.
#
# Written by:	Sander W. van der Laan | UMC Utrecht, Utrecht, the Netherlands | s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0.0
# Update date: 	2016-12-11
#
# Reference(s): https://www.cyberciti.biz/faq/list-installed-perl-modules-unix-linux-appleosx-bsd/
# Usage:		checkPerlModules.pl

# Starting parsing
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "+                             INSTALLED PERL MODULES CHECKER                             +\n";
print STDERR "+                                         V1.0.0                                         +\n";
print STDERR "+                                                                                        +\n";
print STDERR "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print STDERR "\n";
print STDERR "Hello. I am starting the overlapping of the files you've provided.\n";
my $time = localtime; # scalar context
print STDERR "The current date and time is: $time.\n";
print STDERR "\n";

use ExtUtils::Installed; # to show all installed modules

### First, check if all the required modules have been installed inthe system this script will run on.
print STDERR "* Checking if required modules are present.\n";

BEGIN {
    my @import_modules = (
        #'YAML',
        'Getopt::Long',
        'Statistics::Distributions'
        );

    my ($inst) = ExtUtils::Installed->new();
    my (@installed_modules) = $inst->modules();

    for ( @import_modules ) {

        eval{ $inst->validate($_) };
        if($@) {
            print qq{\n*** ERROR *** Module [ $_ ] does not seem to be installed in this system. Please install the module and try again!\n};
            exit 1;

        } # end 'if'
		else {
			print STDERR "\n. The required modules $import_modules exist."
		}
    } # end 'for'

} # end 'BEGIN' block

print STDERR "* Listing all installed modules.\n";
my $inst    = ExtUtils::Installed->new();
my @modules = $inst->modules();
foreach $module (@modules){
     print $module . "\n";
}

print STDERR "\n";
print STDERR "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print STDERR "The current date and time is: $newtime.\n";
print STDERR "\n";
print STDERR "\n";
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
