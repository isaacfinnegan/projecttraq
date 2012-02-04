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
 my($LOGGING) = 5;

 my($html,$userid, $template, %results, $projectID, $connection, $q);
 $q = new CGI;
 $userid = &getUserId($q);
 my(%groups);
 my($mode) = $q->param('mode') || "list";
 if($mode eq "list") {
 	#&isAdministrator($userid, $q);
 	if(isAdministrator($userid))
 	{
  		%groups = &doSql("select * from groups where groupname not like '%-owners' order by groupname");			
 	}
 	else
 	{
 		%groups = &doSql("select grp.* from groups grp, user_groups usr
			    where usr.userid=$userid and usr.groupid=grp.groupid and grp.groupname not like '%-owners'
			    order by grp.groupname");
 	}
	$groups{PISSROOT}[0] = $c{'url'}{'base'};
	$groups{FOOTER}[0] = &getFooter($userid, $q->param('type'));
	$groups{HEADER}[0] = &getHeader($userid, $q->param('type'));
	$groups{RETURN}[0] = $c{'url'}{'base'};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"grouplist.tmpl",$userid);
	$html = &Process(\%groups,$templatefile);
 }
 elsif($mode eq "getgroup") {
	my($group)=$q->param('group');
	unless(&isGroupAdmin($userid, $group, $q)) {
	    print $q->header;
	    &doError("You must be an administrator of that group in order to edit");
	    exit;
	}
	my($grpsql) = " select ";
	if($c{useraccount}{sortname} eq 'first_name')
	{
		$grpsql.="concat(logins.first_name, ' ', logins.last_name) as fullname,";
	}
	else
	{
		$grpsql.="concat(logins.last_name, ', ', logins.first_name) as fullname,";
	}
	$grpsql.="logins.userid from user_groups, logins where groupid=$group and logins.userid=user_groups.userid order by logins.$c{useraccount}{sortname}";
	my(%groupinfo)= &doSql($grpsql);
	my(%employeelist) = &GetEmployeeList("full");
	my(%results) = &mergeHashes(%groupinfo, %employeelist);
	$results{group}[0] = $group;
	my(%groupname) = &doSql("select groupname from groups where groupid=$group");
	my(%admingroup) = &doSql("select groupid from groups where groupname=\"$groupname{groupname}[0]-owners\"");
	my(%admingroupinfo) = &doSql(" select logins.first_name,logins.last_name,
			    logins.userid from user_groups, logins where
			    groupid=$admingroup{groupid}[0] and logins.userid=user_groups.userid order by logins.$c{useraccount}{sortname}");
	if(keys(%admingroupinfo))
	{
		for(my($i)=0;$i< @{$admingroupinfo{'userid'}};$i++)
		{
			$results{adminuserid}[$i]=$admingroupinfo{userid}[$i];	
			if($c{useraccount}{sortname} eq 'first_name')
			{
				$results{adminfullname}[$i]=$admingroupinfo{first_name}[$i] . ' ' . $admingroupinfo{last_name}[$i]
			}
			else
			{
				$results{adminfullname}[$i]=$admingroupinfo{last_name}[$i] . ', ' . $admingroupinfo{first_name}[$i]
			}
		}
	}
	$results{PISSROOT}[0] = $c{'url'}{'base'};
	$results{GROUPNAME}[0] = $groupname{groupname}[0];
	$results{FOOTER}[0] = &getFooter($userid, $q->param('type'));
	$results{HEADER}[0] = &getHeader($userid, $q->param('type'));
	$results{RETURN}[0] = $c{url}{base};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"groupdetails.tmpl",$userid);
	$html = &Process(\%results,$templatefile);
	
 }
 elsif($mode eq "processedit") {
	my($group)=$q->param('group');
	unless(&isGroupAdmin($userid, $group, $q)) {
	    &doError("You must be an administrator of that group in order to edit");
	    exit;
	}

	my(%groupname) = &doSql("select groupname from groups where groupid=$group");
	my(%admingroup) = &doSql("select groupid from groups where groupname=\"$groupname{groupname}[0]-owners\"");

	unless(&isGroupAdmin($userid, $group, $q)) {
	    &doError("You must be an administrator of that group in order to edit");
	    exit;
	}
	if($q->param('add')) {
	    my(@empstoadd) = $q->param('employeelist');
	    my($emp);
	    foreach $emp (@empstoadd) {
			&doSql("delete from user_groups where userid=$emp and groupid=$group");
			&doSql("insert into user_groups (userid, groupid) values ($emp, $group)");
	    }
	    print $q->redirect("editgroups.cgi?mode=getgroup&group=$group");
	    exit;	
	    
	}
	elsif($q->param('remove')) {
	    my(@empstoremove) = $q->param('ingroup');
	    my($emp);
	    foreach $emp (@empstoremove) {
			&doSql("delete from user_groups where userid=$emp and groupid=$group");
	    }
	    print $q->redirect("editgroups.cgi?mode=getgroup&group=$group");
	    exit;
	}
	if($q->param('addadmin')) {
	    my(@empstoadd) = $q->param('employeelist');
	    unless(@empstoadd)
	    {
	    	(@empstoadd) = $q->param('ingroup');
	    }
	    my($emp);
	    foreach $emp (@empstoadd) {
			&doSql("delete from user_groups where userid=$emp and groupid=$admingroup{groupid}[0]");
			&doSql("insert into user_groups (userid, groupid) values ($emp, $admingroup{groupid}[0])");
	    }
	    print $q->redirect("editgroups.cgi?mode=getgroup&group=$group");
	    exit;	
	    
	}
	elsif($q->param('removeadmin')) {
	    my(@empstoremove) = $q->param('admingroup');
	    my($emp);
	    foreach $emp (@empstoremove) {
			&doSql("delete from user_groups where userid=$emp and groupid=$admingroup{groupid}[0]");
	    }
	    print $q->redirect("editgroups.cgi?mode=getgroup&group=$group");
	    exit;
	}

	else {
	    print $q->redirect("editgroups.cgi?mode=getgroup&group=$group");
	    exit;
	}
 }
 
 print $q->header;
 print $html; 
 exit;
