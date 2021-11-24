#!/usr/bin/perl

use JSON;
use Data::Dumper;
use Term::ANSIColor qw(:constants :constants256 colored);
use Getopt::Long;

my $VERBOSE = 0;

#--------------------------------------------------------------------------

sub usage {

    print <<USAGE;

NAME:              
      octane.pl <options>

DESCRIPTION:       
      Perform complex tasks using the octane data stored in Elasticsearch and any other lengthy 
	  operations that clutter up the aliases_octane.txt file

OPTIONS:      

	  --defects
		
		Parse the output JSON returned from querying the octane Elasticsearch index and format
		the output according to release, owner and other properties. Produces colourised output
		dependant on owner and status.
	  
	  --help
		
		Print this usage guide
	  
	  --legacy_id
	  
		Parse the output JSON returned from querying legacy IDs in the octane Elasticsearch index.
		
	  --verbose
		
		Enable the verbose output option if applicable
	  
USAGE
}

#--------------------------------------------------------------------------

sub parse {
    my $l = shift;
    chomp $l;
    $l =~ s/^\s+\"(\w+)\"\s*:\s+//;
    my $field = $1;
    $l =~ s/^"//;
    $l =~ s/"?,*\s*$//;
    return ( $field, $l );
}

#--------------------------------------------------------------------------

sub sort_by_release {

    # For releases like 'BACKLOG', sort last
    if ( $a !~ /^\d+/ ) { return -1; }
    if ( $b !~ /^\d+/ ) { return 1; }
    my ( $RELA, $RELB, $amaj, $amin, $apatch, $bmaj, $bmin, $bpatch );
    if ( $a =~ /^(\d+)\.(\d+)\s*(?:patch)*\s*(\d+)*$/i ) {
        ( $amaj, $amin, $apatch ) = ( $1, $2, $3 );
        $amin =~ s/^(\d)$/0$1/;
        if ($apatch) { $apatch =~ s/^(\d)$/0$1/; }
        else         { $apatch = "00"; }
        $RELA = $amaj . $amin . $apatch;

        #print "  RELA = $RELA\n";
    }
    else { return -1; }
    if ( $b =~ /^(\d+)\.(\d+)\s*(?:patch)*\s*(\d+)*$/i ) {
        ( $bmaj, $bmin, $bpatch ) = ( $1, $2, $3 );
        $bmin =~ s/^(\d)$/0$1/;
        if ($bpatch) { $bpatch =~ s/^(\d)$/0$1/; }
        else         { $bpatch = "00"; }
        $RELB = $bmaj . $bmin . $bpatch;

        #print "  RELB = $RELB\n";
    }
    else { return 1; }
    return $RELA <=> $RELB;
}

#--------------------------------------------------------------------------
#  *** MODIFY THE CODE ***  below to use the Perl JSON module
#  (See the  'legacyDefectIds' code below )

sub defects {

    @IN = <>;

    #print "RELEASE: ID [phase,severity,priority,defect_type] Summary\n";
    my ( %ids, %releases );
    while ( my $l = shift @IN ) {
        if ( $l =~ /"_id.+:\s+"(\w+)"/ ) {
            my $id = $1;
            my ( $ph, $lm, $sev, $rel, $name, $pr, $det, $typ, $cl, $qa, $ow );
            while ( $l = shift @IN ) {
                if ( $l =~ /^\s+"_id"/ ) {
                    unshift @IN, $l;
                    last;
                }
                my ( $f, $val ) = parse($l);

                #print "F:$f, VAL:$val\n";
                $f =~ /^(_owner)$/ and do {
                    $ow = $val;
                };
                $f =~ /^(_qa_owner)$/ and do {
                    $qa = $val;
                };
                $f =~ /^(closed_on)$/ and do {
                    $cl = $val;
                };
                $f =~ /^(name)$/ and do {
                    $name = $val;
                };
                $f =~ /^(_release)$/ and do {
                    $rel = $val;
                };
                $f =~ /^(_defect_type)$/ and do {
                    $typ = $val;
                };
                $f =~ /^(_phase)$/ and do {
                    $ph = $val;
                };
                $f =~ /^(last_modified)$/ and do {
                    $lm = $val;
                };
                $f =~ /^(_detected_in_release)$/ and do {
                    $det = $val;
                };
                $f =~ /^(_severity)$/ and do {
                    $sev = $val;
                };
                $f =~ /^(_priority)$/ and do {
                    $pr = $val;
                };
            }

            $rel =~ s/^9.50.+$/10.00/;
            $rel =~ s/^(\d+)\.(\d)\s/$1.$+0 /;
            $rel =~ s/^(\d+)\.(\d)$/$1.$+0/;

            # Remove any escaped double quotes from the title
            $name =~ s/\\"/"/g;

            # print "ID:$id\nOWNER:$ow\nPH:$ph\nSEV:$sev\nREL:$rel\n".
            #       "NAM:$name\nPR:$pr\nDET:$det\nTYP:$typ\nQA:$qa\n\n";
            $ids{$id} = {
                id          => $id,
                phase       => $ph,
                severity    => $sev,
                release     => $rel,
                name        => $name,
                priority    => $pr,
                detected_in => $det,
                type        => $typ,
                owner       => $ow,
                qa_owner    => $qa
            };
            push @{ $releases{$rel} }, $id;
        }
    }
    my $SPACE = length("[Awaiting Decision,Critical,Very High,Enhancement]");
    for ( sort sort_by_release keys %releases ) {
        my $rel = $_;
        s/^.+"([\s\w\d\.]+)".*$/$1/;
        my $count = scalar( @{ $releases{$rel} } );
        print BOLD, YELLOW, "\nTarget Release:$_ [$count]\n", RESET;
        my %defects;
        foreach ( sort @{ $releases{$rel} } ) {

            my $id   = $_;
            my $lead = "["
              . $ids{$id}{phase} . ","
              . $ids{$id}{severity} . ","
              . $ids{$id}{priority} . ","
              . $ids{$id}{type} . "] ";
            my $sp      = " " x ( $SPACE - length($lead) );
            my $summary = $ids{$id}{name};
            if ( $ids{$id}{qa_owner} =~ /libauer/i ) {
                my $owner = "[" . $ids{$id}{owner} . "]";
                if ( $ids{$id}{phase} =~ /fixed/i ) {
                    $summary = colored( "$summary (fixed)", 'bright_red' )
                      . colored( " $owner", 'bright_green' );
                }
                else {
                    $summary = colored( $summary, 'bright_blue' )
                      . colored( " $owner", 'bright_green' );
                }
            }
            my $shortSum = substr $summary, 0, 80;
            if ($VERBOSE) {
                if ( length($summary) > 80 ) {
                    $defects{$id} = $lead . $sp . $shortSum . " ...";
                }
                else {
                    $defects{$id} = $lead . $sp . $summary;
                }
            }
            else {
                $defects{$id} = $summary;
            }
        }
        foreach ( reverse sort keys %defects ) {
            print BOLD, CYAN, "  $_: ", RESET, $defects{$_} . "\n";
        }
    }

}

#--------------------------------------------------------------------------

sub legacyDefectIds {

    my @out = <>;
    my $jsonStr;
    for (@out) {
        chomp;
        $jsonStr .= $_;
    }

    #print "JSON:\n$jsonStr\n\n";
    my $json = decode_json($jsonStr);

    #print Dumper($json);

    if ( $json->{hits}{total}{value} > 0 ) {
        print BOLD CYAN, "DEFECT ID     ", YELLOW, "LEGACY ID   ", RESET,
          "TITLE\n";
        print BOLD CYAN, "------------- ", YELLOW, "----------- ", RESET,
          "-----\n";
        for my $hit ( @{ $json->{hits}{hits} } ) {
            my $id    = $hit->{_id};
            my $lid   = $hit->{_source}{legacy_id_udf};
            my $title = $hit->{_source}{name};
            print BOLD CYAN, "$id ", YELLOW, "$lid ", RESET, "$title\n";
        }
    }
    else { print RED, "NO MATCHES FOUND\n", RESET; }

}

#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

my ( $doDefects, $doLegacy, $help );
if (
    GetOptions(
        "defects"   => \$doDefects,
        "help"      => \$help,
        "legacy_id" => \$doLegacy,
        "verbose"   => \$VERBOSE
    )
  )
{
    if ($help) {
        usage();
    }
    elsif($doDefects) {
        defects();
    }
    elsif($doLegacy) {
        legacyDefectIds();
    }
}
else {
    die "Failed to parse command line options: $@\n";
}

