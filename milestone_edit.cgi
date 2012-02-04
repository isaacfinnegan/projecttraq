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
use Traqfields;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});

my($headersent) = 0;
my(%clear);
%{$c{cache}}=%clear;

&startLog();
my($LOGGING) = 5;

my($field,%html,$html, $connection, $q,$userid,$i,$item,$key,%milestones,$mode);
$q = new CGI;
$userid = &getUserId($q);
my($projectid)=$q->param('projectid');
no strict 'refs';
$html{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
#added by bsharma
$html{PID}[0]=$projectid;
$html{TARGET_MILESTONELABEL}[0]=$c{general}{label}{target_milestone};
$html{PROJECTID_DISP}[0]=&getFieldDisplayValue('projectid',{projectid=>$projectid},$userid);
#added by bsharma
if($projectid)
{
	$html{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
	$html{PROJECTID_DISP}[0]=&getFieldDisplayValue('projectid',{projectid=>$projectid},$userid);
}

unless(&isProjectAdmin($userid,$projectid))
{
	&doError("You are not authorized for this function");
}
my($action) = $q->param('action');

if($action) 
{
	if($action eq "Delete") 
	{
		my($mile)=$q->param('milestoneid');
		&doSql("delete from traq_milestones where milestoneid=$mile");
	}
	elsif($action eq "Add") 
	{
		my($milestone) = $q->param('milestone');
		my($projectid)=$q->param('projectid');
		my($desc) = $q->param('description');
		my($mile_date)=$q->param('mile_date');
		my($mile_url) = $q->param('mile_url');
		my(%res) = &doSql("select milestoneid from traq_milestones order by milestoneid desc limit 1");
		my($newid) = $res{milestoneid}[0] + 1 ;
		warn ("Before insert $projectid");
		&doSql("insert into traq_milestones set milestone=\"$milestone\",description=\"$desc\", projectid=$projectid,milestoneid=$newid, mile_url=\"$mile_url\",mile_date=\"$mile_date\"");
	}
	elsif($action eq "Update")
	{
		my($mile) = $q->param('milestoneid');
		my($milestone) = $q->param('milestone');
		my($mile_url)=$q->param('mile_url');
		my($mile_date) = $q->param('mile_date');
		my($desc) = $q->param('description');
		&doSql("update traq_milestones set milestone=\"$milestone\",description=\"$desc\", projectid=$projectid, mile_url=\"$mile_url\",mile_date=\"$mile_date\" where milestoneid=$mile");
	}
	elsif($action eq 'Default')
	{
		&doSql("update traq_milestones set sortkey=0 where projectid=$projectid");
		my($mile) = $q->param('milestoneid');
		if($mile)
		{
			&doSql("update traq_milestones set sortkey=1 where milestoneid=$mile");
		}
	}
	if($c{cache}{usecache})
	{
	   	my($cache)=new Cache::FileCache({'namespace' => "milestone-$c{session}{key}" });
        $cache->clear();
	}
	print $q->redirect("./milestone_edit.cgi?projectid=$projectid");
	exit;    
 }


%milestones=&getMilestones($projectid);

for($i=0;$i<scalar(@{$milestones{milestoneid}});$i++)
{
	$html{PROJECTID_VAL}[$i]=$projectid;
	$html{PISSROOT}[$i]=$c{url}{base};
	$html{MILESTONEID}[$i]=$milestones{milestoneid}[$i];
	$html{MILESTONE}[$i]=$milestones{milestone}[$i];
	$html{MILE_DATE}[$i]=$milestones{mile_date}[$i];
	$html{MILE_URL}[$i]=$milestones{mile_url}[$i];
	$html{DESCRIPTION}[$i]=$milestones{description}[$i];
	if($milestones{sortkey}[$i])
	{
		$html{DEFAULT}[$i]='default';
	}
	else
	{
		$html{DEFAULT}[$i]='';
	}
}
my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"milestone_edit.tmpl",$userid);
$html{PISSROOT}[0] = $c{url}{base};
$html{FOOTER}[0] = &getFooter($userid, 'traq');
$html{HEADER}[0] = &getHeader($userid, 'traq');
$html=&Process(\%html,$templatefile);
print $q->header;
print $html;
