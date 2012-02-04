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
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});


 &startLog();

 my($html, $template, %results, $projectID, $connection, $q,$userid,$LOGGING);
  $LOGGING = 5;
$q = new CGI;
 $userid = &getUserId($q);
 unless( &isAdministrator($userid, $q) ){
    &doError("You must be a system admin to access this page");
    exit;
 }
 my($mode) = $q->param('mode') || "form";
 if($mode eq "form") {
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"creategroup.tmpl",$userid);
	$results{PISSROOT}[0] = $c{url}{base};
	$results{FOOTER}[0] = &getFooter($userid, 'traq');
	$results{HEADER}[0] = &getHeader($userid, 'traq');
	$html = Process(\%results, $templatefile);

}
 elsif($mode eq "create") {
    my($groupname) = $q->param('groupname');
    my($description) = $q->param('description');
    doSql("insert into groups (groupname, description) values 
    	(\"$groupname\", \"$description\")");
    my($og) = $groupname . "-owners";
    doSql("insert into groups (groupname, description) values 
    	(\"$og\", \"$description\")");
    my(%res) = doSql("select groupid from groups where groupname=\"$og\"");
    my($newid) = $res{groupid}[0];
    doSql("insert into user_groups (groupid, userid) values ($newid, $userid)");
    %res = doSql("select groupid from groups where groupname=\"$groupname\"");
    my($newid) = $res{groupid}[0];
    doSql("insert into user_groups (groupid, userid) values ($newid, $userid)");
    $html = "group created";
 }
 
 print $q->header;
 print $html;

 exit;
    
