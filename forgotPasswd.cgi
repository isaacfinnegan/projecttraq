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

	my($username) = $q->param('username');
	
	if ($username){
		if(&validateUsername($username)) {
			print $q->header;
			print "Incorrect Username [$username]";
			exit;
		}
		my $passwdkey="234567892345678923456\$.,;:-()+abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ";
		my $passwdlength = 8;
		my $password ="";
		while ($passwdlength) 
		{ 
			$password.=substr($passwdkey,rand(length($passwdkey)),1);
                	$passwdlength--;
		}
		my $res = $password;
		$password = crypt($password, 'TE');
		&doSql("update logins set password=\"$password\" where username=\"$username\"");	
		my(%res) = &doSql("select email from logins where username=\"$username\"");
		if(!$res{'email'}[0]) {
			print $q->header;
			print "No email address found for $username. Send email to ProjectTraq\@good.com" ;
			exit;
		}
		my($address)=$res{'email'}[0];
		my($from)='projecttraq@good.com';
		my($subject)= 'Your ProjectTraq Password';
		my($message)= "Your new password = $res";

		&sendMail(	$address,
				$from,
				$subject,
				$message,
				$from
				);
		$html.= "Email sent!<br><a href=\"./login.cgi\">Go to Login</a>";
	}
	else {
		my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"forgotPasswd.tmpl",$userid);
		$html = &Process(\%results,$templatefile);
	}
	print $q->header;
	print $html;
	exit;
