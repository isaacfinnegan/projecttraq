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

use CatchErrors qw($c{email}{webmaster});

startLog();
my($LOGGING) = 5;

my($html,$val,$grp,$userid,$sql,%result, $connection,$i, $q,%res,%proj,$list);
$q = new CGI;
my($mode) = $q->param('mode') || "index";

print STDERR "Got Cookies: " . $q->raw_cookie() . "\n";

$userid = &getUserId($q);
my(@groups) = getGroupsFromEmployeeId($userid);
push(@groups,'0');
my($grouplist)=join(',',@groups);
print STDERR "DEBUGGG::    $grouplist\n";
my(%projects);
if(scalar(@groups))
{
	%projects=getProjectPageProjects(@groups);
}
$projects{'USERNAME'}[0]=getNameFromId($userid);
$projects{USERID}[0]=$userid;
$projects{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
my($usersql)="select openassigned, openreported from (
 SELECT
	count(distinct rec.record_id) as openassigned
FROM
	acl_traq_records acl
	, traq_records rec 
WHERE
	(assigned_to IN ($userid)) 
	AND
	((rec.status<$c{bugtraq}{resolved}
	AND
	rec.TYPE='bug') 
	OR
	(rec.status<$c{tasktraq}{resolved} 
	AND
	rec.TYPE='task')) 
	AND
	acl.record_id=rec.record_id 
	AND
	acl.groupid IN ( $grouplist) 
) x,
(
SELECT
	count(DISTINCT rec.record_id) as openreported
FROM
	acl_traq_records acl
	, traq_records rec 
WHERE
	(reporter IN ($userid)) 
	AND
	((rec.status<$c{bugtraq}{resolved}
	AND
	rec.TYPE='bug') 
	OR
	(rec.status<$c{tasktraq}{resolved}
	AND
	rec.TYPE='task')) 
	AND
	acl.record_id=rec.record_id 
	AND
	acl.groupid IN ( $grouplist) 
) y";
my(%res)=&doSql($usersql);
print STDERR "PISSROOT: $c{url}{base}\n";


$projects{OPENASSIGNED}[0]=$res{openassigned}[0];
$projects{OPENREPORTED}[0]=$res{openreported}[0];
my(%res)=&doSql("select * from groups,user_groups where groups.groupid=user_groups.groupid and groups.groupname like \"%-owners\" and user_groups.userid=$userid");
unless($res{groupname}[0])
{
        $projects{'ADMIN'}[0]="<!--";
        $projects{'ADMINX'}[0]="-->";
	$projects{'SYSTEM'}[0]="";
	$projects{'SYSTEMX'}[0]="";
}
else
{
        $projects{'ADMIN'}[0]="";
        $projects{'ADMINX'}[0]="";
	$projects{'SYSTEM'}[0]="<!--";
	$projects{'SYSTEMX'}[0]="-->";
}
if(&isAdministrator($userid))
{
        $projects{'SYSTEM'}[0]="";
        $projects{'SYSTEMX'}[0]="";
        $projects{'ADMIN'}[0]="";
        $projects{'ADMINX'}[0]="";
}

print $q->header;
if($mode eq "index") 
{
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"index.tmpl",$userid);
 	$projects{HEADER}[0]=  &getHeader($userid, "traq");
	$projects{FOOTER}[0]=  &getFooter($userid, "traq");
	$projects{PISSROOT}[0]=$c{url}{base};
	$html = Process(\%projects, $templatefile);
	print $html; 
}

sub getProjectPageProjects {
  my (@groups) = @_;
  my $sql_string = "select distinct prj.* from traq_project prj, acl_traq_projects xrf";
  $sql_string .= " where prj.projectid = xrf.projectid";
  $sql_string .= " and (prj.archive is null or prj.archive=0)";
  $sql_string .= " and url like 'htt%'";
  $sql_string .= "  and xrf.groupid in (0";
  foreach $grp (@groups){
	$sql_string .= ",$grp"; 
  }
  #$sql_string =~ s/\,\Z//;  # always one more comma than we need
  $sql_string .= ") order by project";
  my(%res) = &doSql($sql_string);
  return %res;
}




