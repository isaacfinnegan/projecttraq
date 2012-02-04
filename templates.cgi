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
 my($DEBUG)=1;

 my(%res, $i,$connection, $q,$userid);
 #$connection = &dbConnect();
 $q = new CGI;
	$DEBUG = $q->param('debug');
 $userid = &getUserId($q);
 my($category)=$q->param('category') || $userid;

 my($mode) = $q->param('mode') || "view";
 my($name) = $q->param('name');
 
 if($mode eq "view") {
 	%res = &getTemplates($category);
 	# Add user and groups
	$res{'USERID'}[0]=$userid;
	my(%grouplist)=&doSql("select distinct grp.groupid,grp.groupname from groups grp,user_groups usr where grp.groupname not like \"%-owners\" and grp.groupid=usr.groupid and usr.userid=$userid order by grp.groupname");	
	if(%grouplist)
	{
		for($i=0;$i<scalar(@{$grouplist{groupid}});$i++)
		{
			my($cat)="g" . $grouplist{groupid}[$i];
			if($cat eq $category)
			{
				$grouplist{'selected'}[$i]="selected";
			}
			else
			{
				$grouplist{'selected'}[$i]="test";
			}
		}
	}
	%res=&mergeHashes(%res,%grouplist);
	if(@res{category})
	{
		for($i=0;$i<scalar(@{$res{category}});$i++)
		{
			$res{PISSROOT}[$i]=$c{url}{base};
			$res{SERVERNAME}[$i]=$ENV{SERVER_NAME};
			$res{PROTO}[$i]=$c{url}{method};
		}
	}
 	&populateHeaderFooter(\%res);
 	print $q->header;
 	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"templates.tmpl",$userid);
 	$res{PISSROOT}[0]=  $c{url}{base};
 	$res{HEADER}[0]=  &getHeader($userid, "traq");
	$res{FOOTER}[0]=  &getFooter($userid, "traq");
 	my($html) = Process(\%res, $templatefile);
 	print $html;

 }
