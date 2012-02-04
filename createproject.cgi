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
my($LOGGING) = 5;


my($userid,$bugs,$tasks,$MAX_PROJECT_NAME_LENGTH,$html, $template, %results, $projectID, $connection, $q);
$MAX_PROJECT_NAME_LENGTH = 32 - length("-owners");
$q = new CGI;
$userid = &getUserId($q);
unless( &isAdministrator($userid, $q) ){
	&doError("You must be a system admin to access this page");
	exit;
}
my($mode) = $q->param('mode') || "form";
if($mode eq "form") {

	$html = "<LINK REL=stylesheet HREF='./traq.css' TYPE='text/css'>
		<h2>$c{general}{label}{projectid} Creation</h2>
		<form action='createproject.cgi' method=post>
		<input type=hidden name=mode value='create'>
		<table border=0>
		<tr>
		<td><b>$c{general}{label}{projectid} Name:</b></td><td><input type=text size=20 name=projectname></td>
		</tr>
		<tr>
		<td><b>Description:</b></td><td><textarea cols=30 rows=3 name=projectdescription></textarea></td>
		</tr>
		<tr>
		<td colspan=2>$c{general}{label}{projectid}: <input type=radio name=proj_type value=project checked> Service: <input type=radio name=proj_type value=service></td>
		</tr>
		<tr><td>Type<select multiple size=3 name=rec_types><option>task<option>bug</select></td></tr>
		<tr>
		<td colspan=2><center>
		<input type=submit value='Create $c{general}{label}{projectid}' onClick='this.value=\'Please wait...\''></center></form>
		</td></tr></table>";
} elsif($mode eq "create") {
    my($projectname) = $q->param('projectname');
	if (length($projectname) > $MAX_PROJECT_NAME_LENGTH) {
		&doError("$c{general}{label}{projectid} Name is too long.  Maximum project name length is $MAX_PROJECT_NAME_LENGTH characters.");
		exit;
	} else {
		my($projectdescription) = $q->param('projectdescription');
		my($proj_type) = $q->param('proj_type');
		my(@rec_types)=$q->param('rec_types');
		my($rec_types) = join(" ", @rec_types);
    	unless($projectname) { &doError("You must enter a projectname to create a project"); }
    	my(%res) = &doSql("select project from traq_project where project=\"$projectname\"");
    	if($res{project}[0]) { &doError("That project name is already in use."); }
    	my($newpid) = &createProject($projectname, $projectdescription,$userid, $bugs, $tasks, $proj_type, $rec_types);
    	&createProjectGroups($projectname, $newpid);  
#    	$html = "$c{general}{label}{projectid} created $newpid";
#    	$html = "<br><a href=\"editproject.cgi?&mode=selectproject&projectid=$newpid\">Project Administration</a>";
		print $q->redirect("editproject.cgi?&mode=selectproject&projectid=$newpid");

	}
}

 
print $q->header;
print $html;

exit;
 
sub createProject() {
    my($name, $desc, $userid, $bugs, $tasks, $type, $rec_types) = @_;
    &doSql("insert into traq_project (project, description, owner, type, rec_types, default_dev, default_qa) 
	    values (\"$name\", \"$desc\", $userid, \"$type\", \"$rec_types\", $userid, $userid)");
    my(%res) = &doSql("select projectid from traq_project where project=\"$name\"");
    return $res{projectid}[0];
}

sub createProjectGroups() {
    my($pname, $pid) = @_;
    my($ownergroup) = $pname . "-owners";
    &doSql("insert into groups (groupname, description) values
	    (\"$pname\", \"$pname Group\")");
    &doSql("insert into groups (groupname, description) values
	    (\"$ownergroup\", \"$pname Group Owner\")");
    my(%res) = &doSql("select groupid from groups where groupname=\"$pname\"");
    my($groupid) = $res{groupid}[0];
    %res = &doSql("select groupid from groups where groupname=\"$ownergroup\"");
    my($ownergroupid) = $res{groupid}[0];
    &doSql("insert into acl_traq_projects (groupid, projectid) values 
	    ($groupid, $pid)");	   
    &doSql("insert into acl_traq_projects (groupid, projectid) values 
	    ($ownergroupid, $pid)"); 
    &doSql("insert into user_groups (groupid, userid) values 
	    ($groupid, $userid)");
    &doSql("insert into user_groups (groupid, userid) values 
	    ($ownergroupid, $userid)");
	    
}
