##############################################################################

# DataProc.pm
#
# Written by:  Jon Rahoi
# Date: dec 2000
# Company: Bodukai, Inc. 
#

##############################################################################
#
#  Process()
#
#  Usage: $html = Process( \%hashTable, $templateFileName )
#
#  takes a template file and an associative array of values
#  from the DB and combines them according to the Tag syntax
#  ($hashTable{'NAME'} goes in place of [[NAME]])
#
##############################################################################
package DataProc;
use Exporter ();
use strict;
use vars qw(
	$VERSION
	@ISA
	@EXPORT
	@EXPORT_TAGS
	@EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(&Process);
our %EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);

sub Process{
my($t1);
   my($values, $path) = @_;
   open(INFILE, $path) || die("can't open file $path\n");
   undef($/);
   my($template) = <INFILE>;
   $template = &ProcessLoops($values, $template);
   $template =~ s/\[\[(\w*)\]\]/$$values{$1}[0]/g;
   $template =~ s/\n\s+/\n/g;
   $template;
}

##############################################################################
#
#  ProcessLoops()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $template = &ProcessLoops($values, $template);
#
#  takes a template file and an associative array of values
#  from the DB and combines them according to the Tag syntax
#  ($$values{'NAME'} goes in place of [[NAME]])
# 
#  NOTE: WILL ONLY WORK FOR ONE LOOP PER TEMPLATE AS IS
#
##############################################################################

sub ProcessLoops{
  my($values, $html) = @_;
  my $tloop;
  my $outp;
  # find all loop structures
  
   
  while ($html =~ /\[\[BEGIN(.+)\]\](.*)\[\[END\1\]\]/sg){
    $tloop = $2;
    my $lnum = $1;
    my $tempLoop = &ProcessLoop($values, $tloop);
    $tloop =~ s/(\W)/\\$1/g;  # make the pattern safe by backslashing all non-alphas
    
    $html =~ s/\[\[BEGIN$lnum\]\]$tloop\[\[END$lnum\]\]/$tempLoop/sg;

   }
  $html;
}


##############################################################################
#
#  ProcessLoop()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $tempLoop = &ProcessLoop($values, $tempLoop);
#
#  takes a loop structure and an associative array of arrays (rows from DB)
#  and combines them into multiple rows.
#  result returned is pasted back into the original template.
#
##############################################################################
sub ProcessLoop{
  my($hashTable, $loop) = @_;
  my $maxRows = 0;
  my $target = "";
  my $loopSave = $loop;
  
  my @finds = $loop =~ /\[\[(\w*)\]\]/g;
  
  my $find; 
  foreach $find (@finds) {
    my $totalRows = $#{$$hashTable{$find}} + 1;
    if ($totalRows > $maxRows){
      $maxRows = $totalRows;
    }
  }
  my $s; 
  for ($s=0;$s<$maxRows;$s++){
   $loop = $loopSave;
   foreach $find (@finds) {
     $loop =~ s/\[\[$find\]\]/$$hashTable{$find}[$s]/g;
   }
   #$target .= $loop . "\n";
   $target .= $loop;
  }
  $target;
}

##############################################################################
#
#  ReadyForPattern()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $outp = ReadyForPattern($tloop);
#
#  takes a loop structure and makes it ready to be inside of a pattern.
#  basically backslashing the special characters...
#
##############################################################################

sub ReadyForPattern{
  my($pat) = @_;
  $pat =~ s/\[\[/\\\[\\\[/sg;
  $pat =~ s/\]\]/\\\]\\\]/sg;
  $pat =~ s/\]\]/\\\]\\\]/sg;
  $pat =~ s/\:/\\:/sg;
  $pat =~ s/\/\//\\\/\\\//sg;
  $pat =~ s/\?/\\?/sg;
  
  $pat;
}

#-----------------------------------------------------------

1;



