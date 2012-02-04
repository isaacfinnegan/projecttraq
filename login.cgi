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

 &startLog();
 my($LOGGING) = 5;

 my($connection, $q,$userid,$error,$usercookie,$passcookie);
 $q = new CGI;
 my($id) = $q->param('id') || '';
 my($req)= $q->param('req') || '';
 my($mode) = $q->param('mode') || "form";
 my(%html,$ldap,$passreturn,$encpassword,$salt,%res,$mesg,$userreturn);
 $html{ID}[0]=$id;
 my(@req)=split('req=',$ENV{REQUEST_URI});
 $html{REQ}[0]=$req[1];
if($mode eq "form") {
	print $q->header;
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'login.tmpl');
	print Process(\%html,$templatefile);
		
 }
 elsif($mode eq "processlogin") {
	my($password) = $q->param('password');
	my($username) = $q->param('username');
	$username = lc($username);
	unless( $password && $username ) {
		print $q->redirect("login.cgi");
		exit;
	}
	%res = &doSql("select password,$c{db}{logintablekey},$c{db}{logintablename} from $c{db}{logintable} where $c{db}{logintablename}=\"$username\" and active!=\"No\"");
	$userreturn=$res{$c{db}{logintablename}}[0];
	if($c{ldap}{ldapauth} && $username ne 'admin')
	{
		&log("USER: trying ldap auth");
				
		$ldap = Net::LDAP->new( $c{ldap}{server} ) or die "$@"; 
		if($c{ldap}{authbind})
		{
			$mesg=$ldap->bind($c{ldap}{authbind}, password=> $c{ldap}{authpass});
			$mesg->code &&	&doError("initial bind" . $mesg->error);
		}
		else
		{
			$mesg=$ldap->bind;
			$mesg->code &&	&doError("anonymous bind" . $mesg->error);
			
		}
		$mesg=$ldap->search(base=> $c{ldap}{basedn}, filter=>"($c{ldap}{userattr}=$username)");
		$mesg->code &&	&doError($mesg->error);
		my(@entries)=$mesg->entries;
		my($binddn)=$entries[0]->dn();
		&log("AUTH: LDAP user $username found: $binddn",7);
		$mesg = $ldap->bind( $binddn, password => $password );
		if($mesg->code)
		{
			&log("AUTH: LDAP login failed for $username",1);
		}
		else
		{
			&log("AUTH: LDAP login success for $username",7);
			$passreturn = $password;
		}
		&log("USER: LDAP login.  mesg code: " . $mesg->code . " mesg error: " . $mesg->error); 
		$encpassword=$password;
		if(($username ne $userreturn && $passreturn eq $encpassword) && $c{ldap}{autocreate})
		{
			&log("USER: user authenticated but no account exists.  attempting to provision user",4);
			my($newusersql)="insert into logins set 
					username='$username',
					email='".$entries[0]->get_value('mail')."',
					first_name='". $entries[0]->get_value('givenName') . "',
					last_name='". $entries[0]->get_value('sn') . "',
					bugtraqprefs='$c{useraccount}{prefs}',
					active='Yes',
					returnfields='$c{useraccount}{returnfields}',
					recordeditprivs='$c{useraccount}{editprivs}',
					order1='priority asc',
					order2='status asc',
					order3='record_id'";
			&doSql($newusersql);
			%res = &doSql("select password,$c{db}{logintablekey},$c{db}{logintablename} from $c{db}{logintable} where $c{db}{logintablename}=\"$username\" and active!=\"No\"");			$userreturn=$res{$c{db}{logintablekey}}[0];
			my($useridlkup)=$res{$c{db}{logintablekey}}[0];
			foreach(split(',',$c{ldap}{autogroup}))
			{
				&doSql("insert into user_groups set userid=$useridlkup,groupid=$_");
			}
			
		}
	}
	else
	{
		$salt = substr($res{password}[0], 0, 2);
		$encpassword = crypt($password, $salt);
		$passreturn=$res{password}[0];
		$userreturn=$res{$c{db}{logintablename}}[0];
	}
	if(($username eq $userreturn && $passreturn eq $encpassword) || ($username eq 'visitor' && $c{externalaccess}{allowvisitor}) ) 
	{
		if(1)
		{
			my(%session);
			$session{username}=$username;
			my($session_data) = makeSessionCookie(\%session);
			my($session_cookie) = $q->cookie(-name=>'pt_session',
									-value=>"$session_data", 
	#								-expires=>"+$c{session}{timeout}",
									-path=>'/',
					);
			print $q->header(-cookie=>[$session_cookie]);
			&log("DEBUG: user session created - expire: +$c{session}{timeout}",5);
		}
		else
		{
			$usercookie = $q->cookie(-name=>'cname',
									-value=>"$username", 
									-expires=>"+$c{cookie}{timeout}h",
					-path=>'/',
					);
			$passcookie = $q->cookie(-name=>'cpwd',
									-value=>"$encpassword", 
									-expires=>"+$c{cookie}{timeout}h",
					-path=>'/',
					);
	
			&log("USER: user verified with $encpassword", 5);
			print $q->header(-cookie=>[$usercookie,$passcookie]); 
		}	


		if($req)
		{
			print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"1;URL=$req\">\n";
		}
		else
		{
			print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"1;URL=$c{url}{home}\">\n";
		}
		print "Thank you! ( you will be redirected to the main page momentarily)";
		exit;
	}
	else {
		print $q->header;
		print "Login failed";
		print "<br><a href=\"login.cgi\">Retry</a>";
		exit;
	}
	
 }

 exit;
