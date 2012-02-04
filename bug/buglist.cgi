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


use lib "../lib";
use TraqConfig;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});


 &startLog();
 my($html, $connection, $templatefile,$q,$LOGGING,$userid);
 $LOGGING = 5;

 $q = new CGI;
 my($mode) = $q->param('mode') || "list";

 $userid = &getUserId($q);
 my(@groups) = getGroupsFromEmployeeId($userid);
 my(%projects) = getAuthorizedProjects("", \@groups,"bug");

 $projects{webmaster}[0] = $c{email}{webmaster};
	$projects{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
 $projects{PISSROOT}[0]=$c{url}{base};

 print $q->header;
 if($mode eq "list") {
 	$templatefile=&getTemplateFile($c{dir}{bugtemplates},"buglist.tmpl");
 }
 elsif($mode eq "new") {
 	$templatefile=&getTemplateFile($c{dir}{bugtemplates},"newbug.tmpl");
 }
$projects{HEADER}[0]=  &getHeader($userid, "bug");
$projects{FOOTER}[0]=  &getFooter($userid, "bug");
my($html) = Process(\%projects, $templatefile);
print $html;
 


