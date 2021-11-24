#!/usr/bin/perl

use 5.030;
use strict;
use XML::LibXML qw(:libxml);
use Getopt::Long;
use Data::Dumper;

$| = 1;

my $DEBUG            = 0;
my $defDatasetPath   = "C:/TestDatasets/";
my $scriptName       = "trim.pl";
my $trimProperties   = '/trim/src/Core/Property.cpp';
my $databaseFile     = '/trim/src/DD/DATABASE.TXT';
my $TRIMconfig       = 'TRIMConfig.tcfg';
my $bakFile          = "$TRIMconfig.bak";
my $configFolder     = '/trim/SharedTrimServerData/ServerData';
my $xpathDataSources = "//DataSources";
my $xpathDataset     = $xpathDataSources . "/Dataset";

#---------------------------------------------------------------------------------------------

sub usage {

    print <<USAGE;

NAME:              
  $scriptName <options>

DESCRIPTION:       
  Run perl scripts for aliases in the aliases_trim.txt file
  
OPTIONS:      

  --base_dir <path>
  
	  Specifies the path to the base checkout folder, eg. C:/trunk

	  REQUIRED parameter for the following options;
		--tables
		--merge_config
		--remove_config
	  
  --help

	  Display this usage guide

  --debug

	  Turn on debug output
 
  --merge_config <path|dataset ID>
  
	  Specify a path to the Trim config file, or a dataset ID, in which case, we assume
	  that the dataset resides under $defDatasetPath
	  
	  
  --remove_config
  
	  Will display a list of the configured datasets and prompt to remove one. The default
	  configuration file will be loaded from;
	  
                <base folder>$configFolder/$TRIMconfig

  --tables [name or pattern to match]
   
	  Print a list of all the SQL tables and a description. If an argument is provided, 
	  limit the output to the a pattern match of the argument.

DEFAULTS:

	Path to property file    : <base folder>$trimProperties
	Path to database.txt file: <base folder>$databaseFile
	Path to dataset folders  : $defDatasetPath
	Configuration file name  : $TRIMconfig
	Configuration file folder: $configFolder
	  
USAGE
}

#---------------------------------------------------------------------------------------------

sub debug ($) {
    my $message = shift @_;
    if ($DEBUG) {
        print "$message\n";
    }
}

#---------------------------------------------------------------------------------------------

sub selectDataset {
    my ($datasets) = @_;

    my $idx = 0;
    for my $d (@$datasets) {
        print "\t[$idx] " . $d->{name} . "\n";
        ++$idx;
    }

    print "\nEnter a number or <RETURN> to abort: ";
    my $input = <STDIN>;
    chomp $input;
    if ( $input =~ /^$/ ) {
        print "ABORTED!\n";
        exit;
    }

    my $limit = scalar(@$datasets);
    if ( $input !~ /^\d+$/ or $input > $limit ) {
        die
"Invalid value entered. Expected an integer value between 0 and $limit\n";
    }

    debug("\nYOU ENTERED: <$input>");

    return ( $datasets->[$input]{name}, $datasets->[$input]{node} );
}

#---------------------------------------------------------------------------------------------

sub getDatasets {
    my ( $dom, $path ) = @_;

    my @datasets;
    my @nodes = $dom->findnodes($path);
    foreach my $node (@nodes) {
        debug( "NODE: " . $node->{name} . "\n" . $node->toString(1) );
        push @datasets, { name => $node->{name}, node => $node };
    }

    return \@datasets;
}

#---------------------------------------------------------------------------------------------

sub datasetExistsInTarget {

    my ( $targetDom, $name ) = @_;

    my $datasets = getDatasets( $targetDom, $xpathDataset );
    if ( scalar(@$datasets) > 0 ) {
        for my $d (@$datasets) {
            if ( $d->{name} eq $name ) {
                return 1;
            }
        }
    }
    return 0;
}

#---------------------------------------------------------------------------------------------

sub writeConfig {
    my ( $targetDom, $confFile, $bakFile ) = @_;

    # Backup the original config file and write out a new one.
    system( 'cp', $confFile, $bakFile );
    open CF, ">$confFile" or die "Couldn't write to file $confFile\n";
    print CF $targetDom->toString(1) . "\n";
    close CF;
}

#---------------------------------------------------------------------------------------------

sub mergeConfigs {
    my ( $baseDir, $config ) = @_;

    my $path = $config;
    if ( $config =~ /^[A-z0-9]{2}$/ ) {
        $path = $defDatasetPath . ( uc $config ) . "/backup/TRIMConfig.tcfg";
    }

    if ( not -e $path ) {
        die "The path to the $TRIMconfig file does not exist: $path\n";
    }

    my $configTarget = $baseDir . $configFolder;
    if ( not -d $configTarget ) {
        die "Configuration Target folder not found: $configTarget\n";
    }

    $configTarget .= "/$TRIMconfig";
    if ( not -e $configTarget ) {
        die "No configuration file found: $configTarget\n";
    }
    my $configBak = $baseDir . $configFolder . "/$bakFile";

# no_blanks filters out whitespace which are normally treated as nodes of type #text
    my $dom = XML::LibXML->load_xml( location => $path, no_blanks => 1 );
    my $targetDom =
      XML::LibXML->load_xml( location => $configTarget, no_blanks => 1 );

    my $datasets = getDatasets( $dom, $xpathDataset );
    if ( scalar(@$datasets) == 0 ) {
        die "No datasets available\n";
    }

    print "Available Datasets to Merge:\n\n";
    my ( $name, $node ) = selectDataset($datasets);

    if ( datasetExistsInTarget( $targetDom, $name ) ) {
        die
"The Dataset $name already exists in the target configuration file. Remove it first and then retry.\n";
    }

    if ( $targetDom->exists($xpathDataSources) ) {
        debug("FOUND DataSources");

        my ($dsNode) = $targetDom->findnodes($xpathDataSources);
        $dsNode->appendChild($node);

        debug( "\nDatasets:\n" . $dsNode->toString(1) . "\n" );
    }
    else {
        die
"Failed to find $xpathDataSources in target configuration file $configTarget\n";
    }

    writeConfig( $targetDom, $configTarget, $configBak );
}

#---------------------------------------------------------------------------------------------

sub removeConfig {
    my ($baseDir) = @_;

    my $configBak = $baseDir . $configFolder . "/$bakFile";
    my $config    = $baseDir . $configFolder . "/$TRIMconfig";
    if ( not -e $config ) {
        die "Configuration file $config not found\n";
    }

    my $dom      = XML::LibXML->load_xml( location => $config, no_blanks => 1 );
    my $datasets = getDatasets( $dom, $xpathDataset );
    if ( scalar(@$datasets) == 0 ) {
        die "No datasets available\n";
    }

    print "Available Datasets for REMOVAL:\n\n";
    my ( $name, $node ) = selectDataset($datasets);

    $node->unbindNode();

    writeConfig( $dom, $config, $configBak );
}

#---------------------------------------------------------------------------------------------

sub trimTables {
    my ( $basePath, $table_name ) = @_;

    my $propPath = $basePath . $trimProperties;
    if ( not -e $propPath ) {
        die "Couldn't find the property.cpp file : $propPath\n";
    }

    my $dbPath = $basePath . $databaseFile;
    if ( not -e $dbPath ) {
        die "Couldn't find the DATABASE.TXT file : $propPath\n";
    }

    open DB, $dbPath or die "Couldn't read db file $dbPath\n";
    my @in = <DB>;
    close DB;

    my %tables;
    my $max = 10;

    while ( my $line = shift @in ) {
        chomp $line;
        if ( $line =~ /^table/i ) {
            $_ = $line;
            s/nouri//gi;
            s/basic(plusloc)*\s+\[/[/gi;
            s/sharedbobtype\(\w+\)//i;
            s/sharedtableid\(\w+\)//i;
            s/shared\([\w,\s]+\)//i;
            s/obsoleteafter\(\d+\)//i;
            s/^(table\s+[\d,\s]+)iot /$1/i;

            if (/^table\s+[\d,\s]+(\w+)[\s\d\%]+\[(.+)\]/) {
                my $TBL = uc $1;
                $tables{$TBL}{description} = $2;
                my $l = length $1;
                $max = ( $l > $max ) ? $l : $max;

                # next line should be {
                shift @in;
                my $columns;
                my $max = 10;
                $line = shift @in;
                while ( $line !~ /^\s*\}\s+/ ) {
                    $line =~ s/^\s+|\s+$//;
                    $line =~ s/\s+/ /g;
                    if ( $line ne "" ) {
                        if ( $line =~ /^(\w+)\s*:\s*(.+)$/ ) {
                            push @{ $tables{$TBL}{cols} },
                              { name => $1, val => $2 };
                            $max = length($1) > $max ? length($1) : $max;
                        }
                        $columns .= $line;
                    }
                    $line = shift @in;
                }
                $tables{$TBL}{raw} = $columns;
                $tables{$TBL}{max} = $max;
            }
            else {
                print "FAILED to match line with 'table': $_\n";
                exit;
            }
        }
    }

    for ( sort keys %tables ) {
        my $sp = $max - length($_);
        if ( $table_name ne "" ) {
            if ( $_ =~ /^$table_name/i ) {
                print $_. " - " . $tables{$_}{description} . "\n";

                #print $tables{$_}{raw}."\n";
                my $max = $tables{$_}{max};
                my $i   = 1;
                foreach ( @{ $tables{$_}{cols} } ) {
                    my $len = length( $_->{name} );
                    my $sp  = " " x ( $max - $len + 1 );
                    print "["
                      . $i++ . "]\t"
                      . $_->{name}
                      . $sp . ": "
                      . $_->{val} . "\n";
                }
                print " ---\n";
            }
        }
        else {
            print $_. ( " " x $sp ) . ": " . $tables{$_}{description} . "\n";
        }
    }

    open PP, "$propPath" or die "Could not read $propPath\n";
    my $textTable = "TSTXTIDX";
    my @pp        = <PP>;
    close PP;

    if ($table_name) {
        for (@pp) {
            if (/TRIM::wd_(\w+).+return\s+"(\w+)"/i) {
                my $tblName = $textTable . $2;
                my $str     = "$tblName\t    : SQL Text Index Table for $1\n";
                if ( $1 =~ /$table_name/i or $tblName =~ /$table_name/i ) {
                    print $str;
                }
            }
        }
    }
    else {
        print "\nSQL Text Indexing Tables\n";
        for (@pp) {
            if (/TRIM::wd_(\w+).+return\s+"(\w+)"/i) {
                print $textTable. $2 . "\t    : SQL Text Index Table for $1\n";
            }
        }
    }

}

#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#=============================================================================================

my ( $baseDir, $trimCfg, $help, $removeConf, $trimTables );
if (
    GetOptions(
        "--base_dir=s"     => \$baseDir,
        "--debug"          => \$DEBUG,
        "--help"           => \$help,
        "--merge_config=s" => \$trimCfg,
        "--remove_config"  => \$removeConf,
        "--tables:s"       => \$trimTables
    )
  )
{
    if ($help) {
        usage();
        exit;
    }

    if ( $trimCfg or defined $trimTables or $removeConf ) {
        if ( not -d $baseDir ) {
            die
"A directory path to the checkout folder must be provided with --base_dir (see --help)\n";
        }
    }

    if ($trimCfg) {
        mergeConfigs( $baseDir, $trimCfg );
    }
    elsif ( defined $trimTables ) {
        trimTables( $baseDir, $trimTables );
    }
    elsif ( defined $removeConf ) {
        removeConfig($baseDir);
    }
}
