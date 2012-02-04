#!/usr/bin/perl
###############################################################
#    Copyright (C) 2001-2007 Isaac Finnegan and Sean Tompkins
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###############################################################

use lib "./lib";
use TraqConfig;
use dbFunctions;
use URI::Escape;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});


 &startLog();
 my($LOGGING) = 5;

 my(%results, $connection, $q,$userid);
 #$connection = &dbConnect();
 $q = new CGI;
 my($mode) = $q->param('mode') || "list";
 $userid = &getUserId($q);
 
 
if($mode eq "list") {
 print $q->header;

 %results = &getNamedQueries($userid);
  my(@returnFields) = &getReturnFields($q);
  my($field);
  foreach $field (@returnFields) {
       my($key) = "check" . "_" . $field;
       $results{"$key"}[0]="checked";
  }
 
$results{'user'}[0] = &getNameFromId($userid);


my($line)=0;
if(@results{name})
{
	for(my $i=0; $i < scalar(@{$results{'name'}}); $i++) {
		$results{QUERYNAME}[$i]=$results{'name'}[$i];
		$results{QUERYURL}[$i]=$results{url}[$i];
		$results{QUERYNAME_ESC}[$i]=uri_escape($results{'name'}[$i]);
	}
}
my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"savedqueries.tmpl",$userid);

$results{HEADER}[0]=  &getHeader($userid, "traq");
$results{PISSROOT}[0]=$c{url}{base};
$results{FOOTER}[0]=  &getFooter($userid, "traq");
my($html) = Process(\%results, $templatefile);
print $html;

 
}
elsif($mode eq "viewsql") {
	print $q->header;
	my($qname) = $q->param('qname');
	$results{'SQL'}[0] = &getNamedQuery($userid, $qname);
	$results{'QNAME'}[0] = $qname;
 	$results{'user'}[0] = &getNameFromId($userid);
 	$results{'PISSROOT'}[0] = $c{'url'}{'base'};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"viewsql.tmpl",$userid);
 	$results{PISSROOT}[0]=$c{url}{base};
	$results{HEADER}[0]=  &getHeader($userid, "traq");
	$results{FOOTER}[0]=  &getFooter($userid, "traq");
	my($html) = Process(\%results, $templatefile);
	print $html;
}
 &stopLog();
