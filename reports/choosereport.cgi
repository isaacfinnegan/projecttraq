#!/usr/bin/perl

use lib "../lib";
use TraqConfig;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});


my($NUMQUERIES,$LOGGING,$q,$userid,$key,$i);
$NUMQUERIES=0;
&startLog();
$LOGGING = 5;
$q = new CGI;
$userid = &getUserId($q);
 
my($mode) = $q->param('mode') || "";
my(%results) = &getNamedQueries($userid, "");

foreach $key (keys(%{$c{general}{label}}))
{
	$results{$key}[0]=$c{general}{label}{$key};
}

my(@groups) = &getGroupsFromEmployeeId($userid);
my(%projects) = &getAuthorizedProjects($mode, \@groups);
for($i=0; $i < scalar(@{$projects{'project'}}); $i++) {
   	 $results{'PROJECTID'}[$i] = $projects{'projectid'}[$i];
   	 $results{'PROJECTNAME'}[$i] = $projects{'project'}[$i];
   	 $results{'PROJECTDESC'}[$i] = $projects{'description'}[$i];
   	 $results{'rec_types'}[$i]=$projects{'rec_types'}[$i];
   	 $results{'PROJECTPRIMARY'}[$i] = &getNameFromId($projects{'default_dev'}[$i]);
   	 $results{'PROJECTPRIMARYEMAIL'}[$i] = &getEmail($projects{'default_dev'}[$i]);
}
$results{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
$results{COMPONENTIDLABEL}[0]=$c{general}{label}{componentid};
$results{'PISSROOT'}[0] = $c{'url'}{'base'};
$results{'USEROPTIONLIST'}[0]=makeUserOptionList(@{$projects{projectid}});

my($javascript) = &makeJs(\@{$results{'PROJECTID'}},'',\@groups);
$results{'JS'}[0] = $javascript;

$results{'QUERYIDREF'}[0]=$q->param('queryid');
&log("DEBUG: queryid $results{'QUERYIDREF'}[0]");
my($templatefile)=&getTemplateFile($c{dir}{reporttemplates},"report.tmpl",$userid);
# setup field list and labels for selects
my(@fieldlist)=keys(%{$c{general}{label}});
my(@ext_fields)=split(',',$c{general}{externalfields});	
foreach my $field (sort { $c{general}{label}{$a} cmp $c{general}{label}{$b}  } (@fieldlist))
{
	unless(grep(/^$field$/, @ext_fields))
	{
		$results{$field}[0]=$c{general}{label}{$field};
		push(@{$results{field}},$field);
		push(@{$results{fieldlabel}},$c{general}{label}{$field});
	}
}
%results=&populateLabels(\%results,'');
 $results{PISSROOT}[0]=$c{url}{base};

$results{HEADER}[0]=  &getHeader($userid, "task");
$results{FOOTER}[0]=  &getFooter($userid, "task");

my($html) = &Process(\%results, $templatefile);
print $q->header;
print $html;

