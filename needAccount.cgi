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

 my($html, $template,%groups, %results, $projectID, $connection, $q,$LOGGING,$i,$key,%owners);
 
 $LOGGING = 5;

 $q = new CGI;
 my($mode) = $q->param('mode') || "list";


	$results{'nextmode'}[0] = "savenew";
	$results{'passwordmode'}[0] = "password";
	$results{'returnfields'}[0] = $c{useraccount}{returnfields};
	$results{'recordeditprivs'}[0] = $c{useraccount}{editprivs};
	$results{'bugtraqprefs'}[0] = $c{useraccount}{prefs};
	my(%newid)=&doSql("select userid from logins order by userid desc limit 1");
	
	$results{'userid'}[0]=$newid{userid}[0] + 1;
	$results{'yes'}[0]='checked';
	$results{RETURN}[0] = $c{url}{base};

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

	if($newid)
	{
		unless(&validateId($newid)) {
			print $q->header;
			print "Userid in use";
			exit;
		}
		unless(&validateUsername($username)) {
			print $q->header;
			print "Username in use";
			exit;
		}
		unless(&validateEmail($email)) {
      print $q->header;
      print "Email in use";
      exit;
    }
    unless ($username)
    {
      &doError("Username is required.");
      exit
     }
     unless ($first_name)
     {
        &doError("First name is required.");
        exit;
     }
     unless ($last_name)
     {
        &doError("Last name is required.");
        exit;
     }
     unless ($email)
     {
        &doError("Email is required.");
        exit;
     }
     unless ($password)
     {
       &doError("Password is required.");
       exit;
     }
     if($password =~ /^TE/) { #Aleady encrypted by user
		 }
		 else {
				$password = crypt($password, 'TE');
		 }
     $first_name =ucfirst($first_name);
     $last_name =ucfirst($last_name);
     if (!($email =~ /\@/))
     {
            &doError("Invalid email address.");
            exit;
     }
#TODO  need to make this based on a config file
		&doSql("insert into logins (username, userid, first_name, last_name, email, password, bugtraqprefs, returnfields, active, recordeditprivs,order1) values (\"$username\", $newid, \"$first_name\", \"$last_name\", \"$email\", \"$password\", \"$bugtraqprefs\", \"$returnfields\", \"$active\", \"$editprivs\",\"status asc\")");
		
		#add an insert command to add a group
		&doSql("insert into user_groups set userid=$newid, groupid=35");
		&doSql("insert into user_groups set userid=$newid, groupid=15");
		&doSql("insert into user_groups set userid=$newid, groupid=7");
		&doSql("insert into user_groups set userid=$newid, groupid=37");
		&doSql("insert into user_groups set userid=$newid, groupid=47");
		&doSql("insert into user_groups set userid=$newid, groupid=21");
		&doSql("insert into user_groups set userid=$newid, groupid=51");
		&doSql("insert into user_groups set userid=$newid, groupid=31");
		&doSql("insert into user_groups set userid=$newid, groupid=33");
		&doSql("insert into user_groups set userid=$newid, groupid=43");
		&doSql("insert into user_groups set userid=$newid, groupid=45");
		&doSql("insert into user_groups set userid=$newid, groupid=3");
		$html.= "Add user successful<br><a href=\"./login.cgi\">Go to Login</a>";
	}
	else
	{
		my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"needAccount.tmpl");
		$html=&Process(\%results,$templatefile);
	}
	print $q->header;
	print $html; 
exit;
sub getSalt {
	return "TE";
}
