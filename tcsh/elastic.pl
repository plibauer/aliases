#!/usr/bin/perl

use 5.032;
use strict;
use JSON;
use Getopt::Long;
use Term::ANSIColor qw(:constants :constants256 colored);
use File::Spec;
use File::Basename;
use JSON::MaybeXS;
use DateTime;
use Time::Piece;

$| = 1;

my $scriptPath = File::Spec->rel2abs(__FILE__);
my $dirPath    = dirname($scriptPath);
my $scriptName = basename($scriptPath);

require "$dirPath/../../perl/unicode.pl";

#---------------------------------------------------------------------------------------------

sub usage {

    print <<USAGE;

NAME:              
  $scriptName <options>

DESCRIPTION:       
  Run perl scripts for aliases in the aliases_elastic.txt file
  
OPTIONS:      

  --help
            Print usage guide

PATHS:
  
  Script Directory: $dirPath


USAGE
}

#---------------------------------------------------------------------------------------------

sub es_help {

    print <<ES_HELP;

For elastic search commands                 : eshelpsearch                                    
For curl commands, see                      : eshelpcurl                                      
For auto-classification commands, see       : eshelpauto                                      
For subversion related commands, see        : eshelpsvn                                       
For octane searches, see                    : eshelpoctane                                    
For usage of the Python elastic script, see : eshelppy

---      Basics        ---                                                              
  esinfo              : Show the current configuration                                  
  eshost <host:port>  : Set the default host server and port                            
  esindex <name>      : Set the default index                                           
                                                                                        
---   Elastic Index    ---                                                              
  mapping           : Show mapping for the default elastic index                           
  espym "index"     : Show mapping for "index"                                 
  settings          : Show settings for default index                                      
  espys "index"     : Show settings for "index"                                
  espyhelp(espyh)   : See examples of extended espy commands                               
  esindexproperties : Show index properties                                             
  esmetadata        : Show metadata fields (use 'metadata' for brief output)            
  espolicy          : Show the policy settings if ILM is enabled on the index           
  estemplate        : Show the template settings if ILM is enabled on the index         
ES_HELP

}

#---------------------------------------------------------------------------------------------

sub es_help_search {

    print <<ES_HELP_SEARCH;
For elastic help : elastichelp (or eshelp)                                              
                                                                                        
------ Using IDs -------                                                                
  docid <id>          : print doc with given id                                         
  contents <id>       : print the Document.Content field for given id as original text  
  recid <number>      : print doc with record number ("REC_" is prefixed)         
  allids              : print every elastic document id found                           
  trimallids          : print every unique URI found                                    
  delid <id>          : delete the doc with given id                                    
                                                                                        
------- Content --------                                                                
  NOTE: contentsrch and phrasesrch will print the actual contents of the document,      
        converting "\\n" into newlines, whereas the 'trim' variants return the metadata 
        documents                                                                       
                                                                                        
  content <id>        : print all the child Document.Content fields for parent id       
  contentsrecnum      : Same as "contents" above, but can take a record number or 
                        URI, eg. 9000000020 or REC_20 or just 20                        
  contentsrch         : Search for term(s) in child Document.Content fields             
  contentsrchids      : Search for term(s) in Document.Content and return the ids       
  phrasesrch          : Search for a phrase in child Document.Content fields            
  phrasesrchids       : Search for a phrase in Document.Content and return the ids      
  ---                                                                                   
  trimcontent         : Search in Document.Content with same query syntax as TRIM       
  trimcontentid       : As above, but return the URIs                                   
  trimcontentidsorted : As above, but return the URIs sorted by URI                     
  not_trimcontent     : As above, but negated                                           
  not_trimcontentid   : As above, but return the URIs                                   
  ---                                                                                   
  trimphrase          : Search in Document.Content as above, but perform a phrase search
  trimphraseids       : As above, but return the URIs                                   
  not_trimphrase      : As above, but negated                                           
  not_trimphraseids   : As above, but return the URIs                                   
                                                                                        
------- books -------                                                                   
booktitles            : Print URIs => Title Acronym and vice versa                      
booktitlesv           : Print URIs, Acronym and Title                                   
docid2acronym         : Pipe output of commands that return a list of URIs to this      
                        command to convert them to acronyms                             
toacronyms,getacronyms: Same as above                                                   
                                                                                        
                                                                                        
------- Metadata -------                                                                
  metadatasrch        : Search on a metadata field (eg. Notes:spoon). Spaces need to be 
                        encoded as %20, Eg. Notes:spoon%20AND%20Title:refresh           
  metasearch          : Same as above                                                   
  hasallcontacts      : Show records with the field "AllContacts"                 
  hasclassification   : Show records with the field "Classification"              
  hascontainer        : Show records with the field "Container"                 
  hascontent          : Show records with the field "Document.Content"            
  hascontenttrim      : As above, but only shows parent URIs, not child documents       
  withandwithout      : Shows output of above with the gaps in a second column          
  hasexternalref      : Show records with the field "ExternalReference"           
  hasnotes            : Show records with the field "Notes"                       
  containers          : Show container records with their contained records             
  esgetfield <arg>    : Show the document id and field specified by <arg> (eg Title)    
  esfield <arg>       : Get specific field for all records that have it. This version   
                        Allows compound fields, eg. Document.Status.Reason              
  esrectypes          : Show record uris and their associated record types              
                                                                                       
ES_HELP_SEARCH

}

#---------------------------------------------------------------------------------------------

sub es_help_autoclass {

    print <<ES_HELP_AC;
For curl commands, see : eshelpcurl                                                     
For elastic search commands, see : elastichelp (or eshelp)                              
                                                                                        
To build the auto-classification dataset, run the following commands;                   
   popdbac - runs podpb with --dbid AC and --dbname elastic_autoclass                   
   saveac  - save the dataset with above data                                           
   testac  - runs testttrim with above for autoclassification test --all and then       
             call saveac                                                                
   restoreac - load the above saved data                                                
                                                                                        
buildac is a shortcut to run both popdbac and testac                                    
                                                                                        
--- Autoclassification ---                                                              
  acmapping      : Show mapping for the autoclassification index                        
  acsettings     : Show settings for autoclassification index                           
  autoclassinfo  : Show a summary of the autoclassification index                       
  autoclasstypes : Show the different table <types>                                     
  estype <type>  : Query one of the types from the previous command                     
  aclabels       : Print _id, document count, uri and name for all categories/labels    
                                                                                        
---   Word statistics  ---                                                              
                                                                                        
  getwords "id"  <arg1> <arg2> <arg3>                                             
             Print tabulated words using _id from acwordlabels                          
                                                                                        
      ARG1  - search string which will be matched against each pair                     
              Eg. "^un" will only match words beginning with 'un'           
      ARG2  - number of columns (default 10)                                            
      ARG3  - size of columns (default 30)                                              
                                                                                        
  If all words should be printed, but you want to change arg2 or arg3, then;            
  getwords "^.+" 8 25   (all words with 8 columns and col width 25)               
                                                                                        
Manipulate word counts and test classification process                                  
                                                                                        
  testac --inplace --classify --input "hockey science ..." --debug > output.txt   
  espy --ac_analyse output.txt                                                          
             With the WGS running, run testtrim with the text input and see how         
             terms are scored.  Feed the output into espy to analyse the results        
                                                                                        
  espy --ac_modify 9000000018:zubkoff:1                                                 
             Change the word count for "zubkoff" to a value of 1. Changing        
             a value to 0 will remove the word for the given label.                     
                                                                                                                                                         
ES_HELP_AC
}

#---------------------------------------------------------------------------------------------

sub es_help_py {

    print <<ES_HELP_PY;
                                                                                           
  espy           Show all indexes and assign integer value to each index                      
  espy 'index'   Show info for specific index (can use an integer for 'index')    
                                                                                            
  espy s/5/q:a   (long form: search/5/query:all)                                              
                 Search(s) the 5th index and Query(q) All(a)                                  
                                                                                            
  espy s/5/9000000020  (long form: search/5/9000000020)                                       
                 Show document with _id (uri) 9000000020                                      
                                                                                            
  espy s/5       (long form: search/5)                                                        
                 Show top 10 documents for index 5                                            
                                                                                            
  espy s/5 -s Number:Title                                                                    
                 As above but only show Number and Title fields                               
                                                                                            
  espy s/5 -s Number:Title --compact                                                          
                 As above but remove _index,_score,_source,_type fields                       
                                                                                            
  espy s/5 -e Document                                                                        
                 Exclude 'Document' from the _source properties                         
                                                                                            
  espy s/cm_m1 --brief --size 100                                                             
                 Get the first 100 documents with 1 entry per line (_id,_sore,Title)          
                                                                                            
  espy s/cm_m1/query:Notes:"patterson" -s Notes --compact                               
                 Search all 'Notes' fields in cm_m1 for the string "patterson" and
                 limit the output to only the 'Notes' field                             
                                                                                            
  espy s/cm_m1/q:Document.Content:trim -s Document --compact                                  
                 Search in the document content field for all occurrences of 'trim'     
                 and limit the output to only the 'Document.Content' field              
                                                                                            
  espy s/cm_m1/q:Document.Content:trim --brief                                                
                 As above, but just print the matching URIs                                   


ES_HELP_PY
}

#---------------------------------------------------------------------------------------------

sub index_template {

    my @in       = <>;
    my $template = shift @in;
    chomp $template;
    my $input = shift @in;

    my $j      = JSON->new->allow_nonref;
    my $parsed = $j->decode($input);

    #print $j->pretty->encode($parsed->{$template}{"mappings"});
    my $map = $parsed->{$template}{"mappings"}{properties};

    my %mapping;
    my $max = 15;
    for ( sort keys %$map ) {
        $max = $max > length($_) ? $max : length($_);
        if ( $map->{$_}{type} ) {
            $mapping{$_} = $map->{$_}{type};
        }
        else {
            $mapping{$_} = "";
        }
    }

    for ( sort keys %mapping ) {
        my $sp = " " x ( $max - length($_) + 1 );
        print $_. $sp . ": " . $mapping{$_} . "\n";
    }
}

#---------------------------------------------------------------------------------------------

sub index_metadata {

    my @input = <>;
    my ( $max1, $max2, $max3, $max4 ) = ( 15, 5, 8, 8 );
    my %fields;
    my $j      = JSON->new;
    my $parsed = $j->decode("@input");

    #print $j->pretty->encode($parsed->{"_source"}{Metadata});
    my $meta = $parsed->{"_source"}{Metadata};
    for ( keys %$meta ) {
        my $typ     = $meta->{$_}{ElasticType};
        my $isdef   = $meta->{$_}{IsDefault} ? "true" : "false";
        my $enabled = $meta->{$_}{Enabled}   ? "true" : "false";
        my $pid     = $meta->{$_}{PropertyOrFieldID};

        $max1 = length($_) > $max1   ? length($_)   : $max1;
        $max2 = length($pid) > $max2 ? length($pid) : $max2;
        $max3 = length($typ) > $max3 ? length($typ) : $max3;

        $fields{$_} = [ $typ, $enabled, $isdef, $pid ];
    }

    ++$max1;
    ++$max2;
    ++$max3;
    my $n     = "NAME";
    my $s     = " " x ( $max1 - length($n) );
    my $i     = "ID";
    my $s1    = " " x ( $max2 - length($i) );
    my $t     = "TYPE";
    my $s2    = " " x ( $max3 - length($t) );
    my $title = $n . $s . $i . $s1 . $t . $s2 . "DEFAULT ENABLED";
    my $len   = length($title);

    print BRIGHT_BLUE, $title, RESET, "\n" . ( "-" x $len ) . "\n";

    for ( sort keys %fields ) {
        my ( $typ, $enab, $def, $prop ) = @{ $fields{$_} };
        $s  = " " x ( $max1 - length($_) );
        $s1 = " " x ( $max2 - length($prop) );
        $s2 = " " x ( $max3 - length($typ) );
        my $s3 = " " x ( $max4 - length($def) );
        print BRIGHT_YELLOW, $_, $s, BRIGHT_RED, $prop, $s1, BRIGHT_GREEN,
          $typ, RESET, $s2, $def, $s3, $enab, "\n";
    }
}

#---------------------------------------------------------------------------------------------

sub container_records {

    my @in = <>;
    my %containers;
    while ( my $l = shift @in ) {
        my ( $cont, $uri );
        if ( $l =~ /"_source"/ ) {
            $l = shift @in;
            while ( $l and $l !~ /"_source"/ ) {
                if ( $l =~ /"Container":\s+(\d+)/i ) {
                    $cont = $1;
                }
                elsif ( $l =~ /"Uri":\s+(\d+)/i ) {
                    $uri = $1;
                }
                $l = shift @in;
            }
            push @{ $containers{$cont} }, $uri;
            if ( $l =~ /"_source"/ ) {
                unshift @in, $l;
            }
        }
    }
    for ( sort keys %containers ) {
        my $k = $_;
        print "$k:\n";
        for ( sort @{ $containers{$k} } ) {
            print "\t$_\n";
        }
    }
}

#---------------------------------------------------------------------------------------------

sub records_with_and_without {

    my @in      = <>;
    my $current = 0;
    my ( $next, $prev, $missing, $current );
    print "WITH CONTENT", BRIGHT_BLUE, " WITHOUT CONTENT", RESET, "\n";
    for (@in) {
        chomp;
        if ($current) {
            $next = $current + 1;
            if ( $next == $_ ) {
                print "$_\n";
            }
            else {
                $prev = $_ - 1;
                my $sp = " " x length($current);
                if ( $next == $prev ) {
                    $missing = "$sp$next";
                }
                else {
                    my $diff = $prev - $next;
                    $missing = "$sp$next -> $prev ($diff)";
                }
                print BRIGHT_BLUE, " $missing\n", RESET, "$_\n";
            }
        }
        else { print "$_\n" }
        $current = $_;
    }
}

#---------------------------------------------------------------------------------------------

sub get_field {

    my @in    = <>;
    my $field = shift @in;
    chomp $field;
    my $j      = JSON->new->allow_nonref;
    my $parsed = $j->decode("@in");
    my $count  = $parsed->{hits}{total}{value};
    my $hits   = $parsed->{hits}{hits};
    if ( $count > 0 ) {
        say "[Hits $count]";
        for my $hit (@$hits) {
            my $id  = $hit->{_id};
            my $src = $hit->{_source};

            if ( $field =~ /\./ ) {
                my @f = split /\./, $field;
                print "$id: $field { ";
                my @out;
                my $len = scalar @f;
                if ( $len == 2 ) {
                    @out = split /\n/,
                      $j->pretty->encode( $src->{ $f[0] }{ $f[1] } );
                }
                if ( $len == 3 ) {
                    @out = split /\n/,
                      $j->pretty->encode( $src->{ $f[0] }{ $f[1] }{ $f[2] } );
                }
                if ( $len == 4 ) {
                    @out = split /\n/,
                      $j->pretty->encode(
                        $src->{ $f[0] }{ $f[1] }{ $f[2] }{ $f[3] } );
                }
                if ( $len == 5 ) {
                    @out = split /\n/,
                      $j->pretty->encode(
                        $src->{ $f[0] }{ $f[1] }{ $f[2] }{ $f[3] }{ $f[4] } );
                }
                if ( $out[0] =~ /^\{/ ) {
                    shift @out;
                }
                if ( $out[$#out] =~ /^\}/ ) {
                    pop @out;
                }
                my $l = join " ", map { s/^\s+//; s/\s+$//; $_ } @out;
                printAsUTF8("$l }\n");
            }
            else {
                printAsUTF8( "$id: " . $src->{$field} . "\n" );
            }
        }
    }
}

#---------------------------------------------------------------------------------------------

sub book_ids_2_acronyms {

    open IN, "C:/temp/xxx.txt" or die "Couldnt read /c/temp/xxx.txt";
    my @input = <IN>;
    close IN;

    my $docids;
    for (@input) {
        chomp;
        s/\s+//;
        $docids .= "$_,";
    }
    chop $docids;

    open F, "C:/temp/booktitles.txt"
      or die "Couldnt read /c/temp/booktitles.txt\n";
    my @in = <F>;
    my %uri;
    for (@in) {
        chomp;
        if (/^(\d+)\s+(\w+)/) {
            $uri{$1} = $2;
        }
    }

    my %ids = map { s/^(\d+).*$/$1/; $_ => 1 } split /,/, $docids;

    my %valid;
    for ( keys %ids ) {
        if ( exists $uri{$_} ) { $valid{$_} = 1; }
    }
    my $COUNT = scalar( keys %valid );

    my ( $missing, @missSorted );
    for ( keys %uri ) {
        if ( not exists $valid{$_} ) {
            $missing .= $uri{$_} . ",";
            push @missSorted, $uri{$_};
        }
    }
    $missing =~ s/,$//;
    my $miss_sort     = join ",", sort @missSorted;
    my $COUNT_NOMATCH = scalar(@missSorted);

    my $acr     = join ",",  sort map { $uri{$_} } ( keys %valid );
    my $acrbyid = join ",",  map      { $uri{$_} } ( sort keys %valid );
    my $uribyid = join "\n", map { "$_\t" . $uri{$_} } ( sort keys %valid );
    $acr     =~ s/^,|,$//;
    $acrbyid =~ s/^,|,$//;
    $acr     =~ s/,+/,/g;
    $acrbyid =~ s/,+/,/g;

    #print "\n$acr\n\n"; print "ORDERED BY ID:\n$acrbyid\n\n";

    print "\nMatched: $COUNT (unmatched $COUNT_NOMATCH)\n"
      . "Matches: $acr\n"
      . "By ID  : $acrbyid\n\n$uribyid\n";

    if ( $missing ne "" ) {
        print "\n[Count      : $COUNT_NOMATCH]\n";
        print "[NOT MATCHED: $missing]\n";
        print "[SORTED     : $miss_sort]\n";
    }

}

#---------------------------------------------------------------------------------------------

sub book_dates {
    my ( %title, %date, %byDate );
    while (<>) {
        chomp;

        if (/^(\d+)\s+(\w+)\s+(\w.+)$/) {
            my ( $u, $a, $t ) = ( $1, $2, $3 );
            $title{$u} = $t;
        }
        elsif (/^(\d+)\s+"([^"]+)"/) {
            my ( $u, $d ) = ( $1, $2 );
            $date{$u}   = $d;
            $byDate{$d} = $u;
        }
    }

    for ( sort keys %title ) {
        my $date = $date{$_};
        print "$_  $date  $title{$_}\n";
    }

    print "\n---- BY DATE ----\n\n";
    for ( sort keys %byDate ) {
        my $uri = $byDate{$_};
        if ( exists $title{$uri} ) {
            my $title = $title{$uri};
            print "$_  $uri  $title\n";
        }
    }
}

#---------------------------------------------------------------------------------------------

sub autoclassification_getwords {

    my ( $cols, $width ) = ( 10, 30 );
    my @a = split /\s+/, $ENV{AC_SEARCH_STR};
    #
    #  We may have added a missing wlc_ prefix using elastic_add_wlc_prefix
    my $ind = shift @a;
    $ind =~ s/^(\d)/wlc_$1/;
    #
    my ( @tooLong, $out, $outf, @args );
    $out = "INDEX: $ind";
    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        if ( $a[$i] eq ">" ) {
            $outf = $a[ $i + 1 ];
            last;
        }
        @args[$i] = $a[$i];
    }

    my $srchStr;
    if ( scalar(@args) >= 1 ) {
        $srchStr = $args[0];
        $out .= ", SEARCH: \"$srchStr\"";
    }
    if ( scalar(@args) >= 2 ) {
        $cols = $args[1];
        $out .= ", COLUMNS: $cols";
    }
    if ( scalar(@args) >= 3 ) {
        $width = $args[2];
        $out .= ", WIDTH: $width";
    }

    if ($outf) {
        print "OutputFile => $outf\n";
    }

    $out .= "\n";
    while (<>) {
        chomp;
        if (/^\s+"word_count":\s+"(.+)"$/) {
            my @pairs = split /,/, $1;
            $out .= "WORD Count = " . scalar(@pairs) . "\n";
            my $i = 1;
            for (@pairs) {
                if ($srchStr) {
                    next unless /$srchStr/;
                }
                if ( length($_) >= $width ) {
                    push @tooLong, $_;
                    next;
                }
                my $space = " " x ( $width - length($_) );
                $out .= $_ . $space;
                ++$i;
                if ( $i % $cols == 0 ) {
                    $out .= "\n";
                }
            }
        }
    }

    $out .= "\n\n";
    for (@tooLong) {
        $out .= "$_\n";
    }
    if ($outf) {
        open OUT, ">$outf" or die "Couldnt open $outf\n";
        print OUT $out;
        close OUT;
    }
    else {
        print $out;
    }
}

#---------------------------------------------------------------------------------------------

sub es_process_log {

    my @log;
    while (<>) {
        chomp $_;
        if (/^[\d:]+\s+[A-z]{2}\s+(\d+)/) {
            my $thread = $1;
            push @{ $log[$thread] }, "$_\n";
        }
        else {
            print "$_\n";
        }
    }

    for ( my $i = 1 ; $i <= $#log ; $i++ ) {
        print "Thread\t$i (" . scalar( @{ $log[$i] } ) . " entries) \t";
        open T, ">Thread_$i.txt" or die;

        for ( @{ $log[$i] } ) {
            print T $_;
        }
        close T;
        print "=> Thread_$i.txt\n";
    }

    print "\nTo get the list of files for a thread;\n\n\t";
    print ">esgetfiles 'Thread_1.txt'\n\n";
}

#---------------------------------------------------------------------------------------------

sub svn_look_for_author {

    my $verbose = $ENV{ESSVNFILE};
    my @in      = <>;
    my $json    = join "", map { chomp $_; $_ } @in;
    my $obj     = decode_json($json);
    my $out     = encode_json($obj);
    my $maxa    = 10;
    my %hits;

    if ( exists $obj->{hits}{total}{value} ) {

        print "[" . $obj->{hits}{total}{value} . " hits]\n";

        for my $h ( @{ $obj->{hits}{hits} } ) {
            my $rev  = $h->{_id};
            my $auth = $h->{_source}{author};
            $maxa = length($auth) > $maxa ? length($auth) : $maxa;
            $hits{$rev}{source} = $h->{_source};
        }

        my ( $curDay, $prevDay, $first );
        my $first = 0;

        for ( sort keys %hits ) {
            my $s = $hits{$_}{source};
            my ( $auth, $date, $message, $files ) =
              ( $s->{author}, $s->{date}, $s->{message}, $s->{files} );

            if ( not $verbose and $auth =~ /trimbuild/ ) {
                next;
            }

            $curDay = $date;
            $curDay =~ s/^([\d-]+)\s.+$/$1/;

            if ( $curDay ne $prevDay ) {
                my $t = Time::Piece->strptime( $curDay, "%F" );
                my $human =
                    $t->fullday . " "
                  . $t->mday . " "
                  . $t->month;    # alt. $t->strftime("%A %d %b");
                my $header =
                  ( "_" x 20 ) . " $curDay ($human) " . ( "_" x 20 ) . "\n";

                if ($first) {
                    say BRIGHT_MAGENTA, $header, RESET;
                }
                else {
                    say BRIGHT_GREEN, $header, RESET;
                    ++$first;
                }

                $prevDay = $curDay;
            }
            my $sp = " " x ( $maxa - length($auth) + 1 );
            $message =~ s/^\s+$//gm;
            print CYAN, $_, RESET, "\t$auth$sp", RED, "$date\n", YELLOW,
              $message, RESET, "\n";

            if ($verbose) {
                for my $f (@$files) {
                    my $act = $f->{action};
                    $act =~ s/^(...).+$/$1/;
                    print GREEN,
                      "\t$act " . $f->{parent} . "/" . $f->{name} . "\n";
                }
                print RESET;
            }
        }
    }
}

#---------------------------------------------------------------------------------------------

sub svn_look_for_file {

    my $verbose    = $ENV{ESSVNFILE};
    my @in         = <>;
    my $json       = join "", map { chomp $_; $_ } @in;
    my $obj        = decode_json($json);
    my $out        = encode_json($obj);
    my $maxa       = 10;
    my $maxParent  = 40;
    my $maxMessage = 100;
    my %hits;

    if ( exists $obj->{hits}{total}{value} ) {
        print "[" . $obj->{hits}{total}{value} . " hits]\n";
        for my $h ( @{ $obj->{hits}{hits} } ) {
            my $r = $h->{_source}{revision};
            my $a = $h->{_source}{author};
            $maxa = length($a) > $maxa ? length($a) : $maxa;
            $hits{$r}{source} = $h->{_source};
            my $inner = $h->{inner_hits}{files}{hits}{hits}[0]{_source};
            $hits{$r}{inner} = $inner;
        }

        #print "MAX = $maxa\n"; exit;
        for ( sort { $a <=> $b } keys %hits ) {
            my $s  = $hits{$_}{source};
            my $in = $hits{$_}{inner};
            my ( $r, $a, $d, $message ) =
              ( $s->{revision}, $s->{author}, $s->{date}, $s->{message} );
            my $sp     = " " x ( $maxa - length($a) + 1 );
            my $action = $in->{action};
            $action =~ s/^(.).+$/$1/;
            print "$r\t$a$sp$d  [$action] ";

            my $parent = $in->{parent};
            $parent =~ s/^\/repos//i;
            if ( not $verbose ) {
                print "$parent\n";
            }
            else {
                my $pl = length($parent);
                if ( $pl > $maxParent ) {
                    my $cut = $pl - $maxParent;
                    $parent =~ s/^.{$cut}//;
                    $parent = "..." . $parent;
                }
                my $sp2 = " " x ( $maxParent + 4 - length($parent) );

                $message =~ s/[\r\n]+/ /g;
                my $ml = length($message);
                if ( $ml > $maxMessage ) {
                    my $cut = $ml - $maxMessage;
                    $message =~ s/.{$cut}$/ .../;
                }
                print "$parent$sp2$message\n";
            }
        }
    }
}

#---------------------------------------------------------------------------------------------

sub svn_look_for_parent {

    my $verbose    = $ENV{ESSVNFILE};
    my @in         = <>;
    my $json       = join "", map { chomp $_; $_ } @in;
    my $obj        = decode_json($json);
    my $out        = encode_json($obj);
    my $maxa       = 10;
    my $maxP       = 20;
    my $maxMessage = 100;
    my %hits;

    if ( exists $obj->{hits}{total}{value} ) {
        print "[" . $obj->{hits}{total}{value} . " hits]\n";
        for my $h ( @{ $obj->{hits}{hits} } ) {
            my $r = $h->{_source}{revision};
            my $a = $h->{_source}{author};
            $maxa = length($a) > $maxa ? length($a) : $maxa;
            $hits{$r}{source} = $h->{_source};
            my $inner = $h->{inner_hits}{files}{hits}{hits}[0]{_source};
            $hits{$r}{inner} = $inner;
            my $p = $inner->{parent};
            $maxP = length($p) > $maxP ? length($p) : $maxP;
        }

        #print "MAX = $maxa\n"; exit;
        for ( sort { $a <=> $b } keys %hits ) {
            my $s  = $hits{$_}{source};
            my $in = $hits{$_}{inner};
            my ( $r, $a, $d, $message ) =
              ( $s->{revision}, $s->{author}, $s->{date}, $s->{message} );
            my $sp     = " " x ( $maxa - length($a) + 1 );
            my $action = $in->{action};
            $action =~ s/^(.).+$/$1/;
            print "$r\t$a$sp$d  [$action] ";
            my $name   = $in->{name};
            my $parent = $in->{parent};
            $parent =~ s/^\/repos//i;

 # Account for removal of 'repos' above by shortening the number of spaces below
            my $spp = " " x ( $maxP - length($parent) - 2 );
            print BOLD, $parent . $spp . $name . "\n", RESET;
            if ($verbose) { print YELLOW, "$message\n", RESET; }
        }
    }

}

#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------
#=============================================================================================

my (
    $help,             $acGetwords,     $bookDates,        $containers,
    $bookId2Acronym,   $esProcessLog,   $esHelp,           $esHelpAc,
    $esHelpPy,         $esHelpSearch,   $getField,         $indexMetadata,
    $svnLookForAuthor, $svnLookForFile, $svnLookForParent, $tempMapping,
    $withAndWithout
);
GetOptions(
    'autoclass_getwords'               => \$acGetwords,
    'book_dates'                       => \$bookDates,
    'book_id_2_acronym'                => \$bookId2Acronym,
    'container_records'                => \$containers,
    'es_help'                          => \$esHelp,
    'es_help_ac'                       => \$esHelpAc,
    'es_help_py'                       => \$esHelpPy,
    'es_help_search'                   => \$esHelpSearch,
    'es_process_log'                   => \$esProcessLog,
    'get_field'                        => \$getField,
    'help'                             => \$help,
    'index_metadata'                   => \$indexMetadata,
    'records_with_and_without_content' => \$withAndWithout,
    'svn_look_for_author'              => \$svnLookForAuthor,
    'svn_look_for_file'                => \$svnLookForFile,
    'svn_look_for_parent'              => \$svnLookForParent,
    'template_mapping'                 => \$tempMapping
);

if ($help) {
    usage();
    exit;
}

if ($acGetwords) {
    autoclassification_getwords();
}
elsif ($bookDates) {
    book_dates();
}
elsif ($bookId2Acronym) {
    book_ids_2_acronyms();
}
elsif ($containers) {
    container_records();
}
elsif ($esHelp) {
    es_help();
}
elsif ($esHelpAc) {
    es_help_autoclass();
}
elsif ($esHelpPy) {
    es_help_py();
}
elsif ($esHelpSearch) {
    es_help_search();
}
elsif ($esProcessLog) {
    es_process_log();
}
elsif ($getField) {
    get_field();
}
elsif ($indexMetadata) {
    index_metadata();
}
elsif ($withAndWithout) {
    records_with_and_without();
}
elsif ($svnLookForAuthor) {
    svn_look_for_author();
}
elsif ($svnLookForFile) {
    svn_look_for_file();
}
elsif ($svnLookForParent) {
    svn_look_for_parent();
}
elsif ($tempMapping) {
    index_template();
}

