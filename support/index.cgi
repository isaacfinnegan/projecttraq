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
 my($LOGGING) = 5;

 my($html, $connection, $q);
 $q = new CGI;
 my($mode) = $q->param('mode') || "index";

 my($userid) = &getUserId($q);
 my(@groups) = getGroupsFromEmployeeId($userid);
 my(%tmp)=&doSql('select groupid from groups where groupname="corp_support"');
my($support)=$tmp{groupid}[0];
push(@groups,$support);
@groups=@{$tmp{groupid}};
my(%projects) = getAuthorizedProjects("project", \@groups,'task');
 my(%services) = getServices(@groups);
 my(%res) = mergeHashes(%projects, %services);
 $res{PISSROOT}[0]=$c{url}{base};
 $res{PROJECTIDLABEL}[0]=$c{tasktraq}{label}{projectid};
 $res{webmaster}[0] = $c{email}{webmaster};

 print $q->header;
 if($mode eq "index") {
    my($templatefile)=&getTemplateFile("$c{dir}{general}support/templates","index.tmpl",$userid);
 	my($html) = Process(\%res, $templatefile);
 	print &getHeader($userid, "task");
 	print $html, &getFooter($userid, "task");
 }
 exit;
 


