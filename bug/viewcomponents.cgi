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



my($LOGGING,$DEBUG,$userid);
 &startLog();
 $LOGGING = 5;
 $DEBUG=1;

 my(%res, $projectID, $connection, $q);
 #$connection = &dbConnect();
 $q = new CGI;
	$DEBUG = $q->param('debug');
 $userid = &getUserId($q);
 my($projectid) = $q->param('projectid');
#  my($sql) = "select distinct cmp.description,cmp.componentid,cmp.component,cmp.initialowner,cmp.initialqacontact from traq_components cmp, user_groups grp, acl_traq_components acl where cmp.projectid=$projectid and grp.userid=$userid and grp.groupid=acl.groupid and cmp.componentid=acl.componentid and cmp.bugs=1";
# &log("CMP SQL: $sql");
#  %res = &doSql($sql);
%res=getComponents($projectid,'','bug');
 for(my($i)=0; $i < scalar(@{$res{'componentid'}}); $i++) {
	$res{'initialowner'}[$i]= &getNameFromId($res{'initialowner'}[$i]);
	$res{'initialqacontact'}[$i]= &getNameFromId($res{'initialqacontact'}[$i]);
 }
 $res{'PROJECTNAME'}[0]=&getProjectNameFromId($projectid);
 $res{'PISSROOT'}[0] = $c{'url'}{'base'};
 my($templatefile)=&getTemplateFile($c{dir}{bugtemplates},"viewcomponents.tmpl",$userid);
 my($html) = &Process(\%res, $templatefile);
 print $q->header;
 print &getHeader($userid, "bug");
 print $html;
 print &getFooter($userid, "bug");




