#!/usr/bin/perl

use 5.032;
use strict;
use JSON;
use Getopt::Long;
use Term::ANSIColor qw(:constants :constants256 colored);
use File::Spec;
use File::Basename;

$| = 1;

my $scriptPath = File::Spec->rel2abs(__FILE__);
my $dirPath    = dirname($scriptPath);
my $scriptName = basename($scriptPath);

#---------------------------------------------------------------------------------------------

sub usage {

    print <<USAGE;

NAME:              
  $scriptName <options>

DESCRIPTION:       
  Run perl scripts for aliases in the aliases_XXX.txt file
  
OPTIONS:      

  --help
            Print usage guide

PATHS:
  
  Script Directory: $dirPath


USAGE
}

#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#=============================================================================================

my ($help);
GetOptions(
    'help'            => \$help
);

if ($help) {
    usage();
    exit;
}
