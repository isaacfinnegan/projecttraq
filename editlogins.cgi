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

my(%clear);
%{$c{cache}}=%clear;

 &startLog();

 my($html, $template,%groups, %results, $projectID, $connection, $q,$LOGGING,$userid,$i,$key,%owners);
 $LOGGING = 5;
 $q = new CGI;
 $userid = &getUserId($q);
 my($active) = $q->param('active');

 my($mode) = $q->param('mode') || "list";
 if($mode eq "list") {
        unless( &isAdministrator($userid, $q) ){
           print $q->header;
           &doError("You must be a system admin to access this page");
           exit;
        }
 	%owners=&getEmployeeList("Full", "", "$active","1");
 	$i=0;
	 foreach $key (sort {lc($a) cmp lc($b)}(keys(%owners))) {
 		$results{'USERNAME'}[$i] = $key;
 		$results{'USERID'}[$i] = $owners{$key};
		$i++;
 	}
	$results{$active}[0] = "<b>";
    $results{PISSROOT}[0] = $c{url}{base};
    $results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
    $results{HEADER}[0] = &getHeader($userid, $q->param('type'));
	$results{RETURN}[0] = $c{url}{base};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'editlogins.tmpl',$userid);
	$html = &Process(\%results,$templatefile);
 }
 elsif($mode eq "edit") {
	if($q->param('me')) {
		unless($userid)
		{ 
			&doError("This user is not allowed here.");
		}
		%results = &getUserDetails($userid);
		$results{'nextmode'}[0] = "chpasswd";
		$results{'passwordmode'}[0] = "password";
		$results{PISSROOT}[0] = $c{url}{base};
		$results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
		$results{HEADER}[0] = &getHeader($userid, $q->param('type'));
		$results{RETURN}[0] = $c{url}{base};
		my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'chpasswd.tmpl',$userid);
		$html = &Process(\%results,$templatefile);
	}
	else {
        	unless( &isAdministrator($userid, $q) ){
        	   print $q->header;
        	   &doError("You must be a system admin to access this page");
        	   exit;
        	}
		%results = &getUserDetails($q->param('login'));
  		%groups = &doSql("select * from groups where groupname not like '%-owners' order by groupname");			
		my(@usergroups)=&getGroupsFromEmployeeId($q->param('login'));
		my($grp,%grphash);
		foreach $grp (@usergroups)
		{
			$grphash{$grp}=1;
		}
		for(my($i)=0;$i<scalar(@{$groups{groupid}});$i++)
		{
			my($grpid)=$groups{groupid}[$i];
			if($grphash{$grpid})
			{
				$groups{selectedgroup}[$i]='selected';
			}
			else
			{
				$groups{selectedgroup}[$i]='';
			}
		}
		%results=&mergeHashes(%results,%groups);
		$results{'nextmode'}[0] = "saveedit";
		$results{'passwordmode'}[0] = "text";
		$results{PISSROOT}[0] = $c{url}{base};
		$results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
		$results{HEADER}[0] = &getHeader($userid, $q->param('type'));
		$results{RETURN}[0] = $c{url}{base};
		my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'editLogin.tmpl',$userid);
		$html = &Process(\%results,$templatefile);
	}
 }
 elsif($mode eq "chpasswd") {
	my($password) = $q->param('password');
	my(%pass) = doSql("select password from logins where userid=$userid");
	$password = crypt($password, $pass{password}[0]);
	unless($password eq $pass{password}[0]) {
		&doError("You have entered the incorrect password.");
		exit;
	}
  $password=$q->param('newpass');
  unless ($password)
  {
        &doError("Password cannot be blank!");
        exit;
  }
	$password = crypt($password, getSalt());
	&doSql("update logins set password=\"$password\" where userid=\"$userid\"");	
	%results = &getUserDetails($userid);
	$results{PISSROOT}[0] = $c{url}{base};
	$results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
	$results{HEADER}[0] = &getHeader($userid, $q->param('type'));
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'confirmchpasswd.tmpl',$userid);
	$html = &Process(\%results,$templatefile);
 }
 elsif($mode eq "new") {
 	unless( &isAdministrator($userid, $q) ){
	   print $q->header;
 	   &doError("You must be a system admin to access this page");
 	   exit;
 	}

	$results{'nextmode'}[0] = "savenew";
	$results{'passwordmode'}[0] = "password";
	$results{'returnfields'}[0] = $c{useraccount}{returnfields};
	$results{'recordeditprivs'}[0] = $c{useraccount}{editprivs};
	$results{'bugtraqprefs'}[0] = $c{useraccount}{prefs};
	%groups = &doSql("select * from groups where groupname not like '%-owners' order by groupname");			
	%results=&mergeHashes(%results,%groups);
	my(%newid)=&doSql("select userid from logins order by userid desc limit 1");
	$results{'userid'}[0]=$newid{userid}[0] + 1;
	$results{'yes'}[0]='checked';
	$results{PISSROOT}[0] = $c{url}{base};
	$results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
	$results{HEADER}[0] = &getHeader($userid, $q->param('type'));
	$results{RETURN}[0] = $c{url}{base};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'editLogin.tmpl',$userid);
	$html = &Process(\%results,$templatefile);
 }
 elsif($mode eq "saveedit") {
        unless( &isAdministrator($userid, $q) ){
           print $q->header;
           &doError("You must be a system admin to access this page");
           exit;
        }
	my($id) = $q->param('userid');
	my($username) = $q->param('username');
	my($first_name) = $q->param('first_name');
	my($last_name) = $q->param('last_name');
	my($email) = $q->param('email');
	my($password) = $q->param('password');
	my($bugtraqprefs) = $q->param('bugtraqprefs');
	my($returnfields) = $q->param('returnfields');
	my($active) = $q->param('active');
	my($editprivs) = $q->param('recordeditprivs');
	my(@groups)=$q->param('groups');
	%groups = &doSql("select * from groups where groupname not like '%-owners' order by groupname");			
	my($tmp)=join(',', @{$groups{groupid}});
	&doSql("delete from user_groups where userid=$id and groupid in ($tmp)");
	my($grp);
	foreach $grp (@groups)
	{
		&doSql("insert into user_groups set userid=$id, groupid=$grp");
	}
	my(%pass) = doSql("select password from logins where userid=$id");
	unless($password eq $pass{password}[0]) {
		$password = crypt($password, getSalt());
	}
	&doSql("update logins set username=\"$username\", first_name=\"$first_name\", last_name=\"$last_name\", recordeditprivs=\"$editprivs\", email=\"$email\", password=\"$password\", bugtraqprefs=\"$bugtraqprefs\", returnfields=\"$returnfields\", active=\"$active\" where userid=\"$id\"");
	#print $q->redirect("actioncomplete.cgi?action=EditUser&result=Success");
	$html.= "Edit user successful";
	$html.= "<br><a href=\"$c{url}{base}/editlogins.cgi\">Return</a>";
	if($c{cache}{usecache})
	{
	   	my($cache)=new Cache::FileCache({'namespace' => "user-$c{session}{key}" });
        $cache->clear();
	}

 }
 elsif($mode eq "savenew") {
        unless( &isAdministrator($userid, $q) ){
           print $q->header;
           &doError("You must be a system admin to access this page");
           exit;
        }
	my($newid) = $q->param('userid');
	my($username) = $q->param('username');
	my($first_name) = $q->param('first_name');
	my($last_name) = $q->param('last_name');
	my($email) = $q->param('email');
	my($password) = $q->param('password');
	my($bugtraqprefs) = $q->param('bugtraqprefs');
	my($returnfields) = $q->param('returnfields');
	my($active) = $q->param('active');
	my($editprivs) = $q->param('recordeditprivs');
	my(@groups)=$q->param('groups');
	if($password =~ /^TE/) { #Aleady encrypted by user
	}
	else {
		$password = crypt($password, 'TE');
	}
	unless($username && $newid && $first_name && $last_name && $active && $password) {
		&doError("Please enter a first name, last name, id, active and password", "", $q, "Please%20fill%20out%20all%20fields.");
	}
	unless(&validateId($newid)) {
		print $q->header;
		print &getHeader($userid, "traq");
		print "Userid in use";
		exit;
	}
	unless(&validateUsername($username)) {
		print $q->header;
		print &getHeader($userid, "traq");
		print "Username in use";
		exit;
	}
	my($newuser)=&doSql("insert into logins (username, userid, first_name, last_name, email, password, bugtraqprefs, returnfields, active, recordeditprivs,order1) values (\"$username\", $newid, \"$first_name\", \"$last_name\", \"$email\", \"$password\", \"$bugtraqprefs\", \"$returnfields\", \"$active\", \"$editprivs\",\"status asc\")",'','1');
	foreach (@groups)
	{
		&doSql("insert into user_groups set userid=$newuser, groupid=$_");		
	}
	#print $q->redirect("actioncomplete.cgi?action=adduser&result=Success");
	$html.= "Add user successful<br><a href=\"./editlogins.cgi\">Return</a>";
	if($c{cache}{usecache})
	{
	   	my($cache)=new Cache::FileCache({'namespace' => "user-$c{session}{key}" });
        $cache->clear();
	}


 }
 print $q->header;
 print $html; 
sub getSalt {
	return "TE";
}
