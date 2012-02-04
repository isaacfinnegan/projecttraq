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
use URI::Escape;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;

# Init variables and timers
&startLog();
my ($queryid);
my ($LOGGING)    = 5;
my ($PRO)        = 0;
my ($DEBUG)      = 0;
my ($NUMQUERIES) = 0;
my ($q)          = new CGI;

my ($type)       = $q->param('type') || "bug";
my ($typeplural) = $type . "s";

my ( %results, $html, $ii,%res,$tmp,$userid,$y,$db);

my ($user) = &getUserId($q);
$userid = $user;
my (@usergroups) = &getGroupsFromEmployeeId($userid);

### Get values needed for bulk editor
my(%projects) = GetUserProjects(\%results, $db, @usergroups);
$results{'USER_OPTIONLIST'}[0] = &makeUserOptionList(@{$projects{projectid}});
my (@menuhashbugs)  = &getMenuHash("bug");
my (@menuhashtasks) = &getMenuHash("task");



$results{'RESOLUTION_OPTIONLIST'}[0] = "<option value=\"\">Bug $c{bugtraq}{label}{resolution}</option>\n";
$tmp=&getMenuOptionList( 'resolution', 0, 'bug' );
$tmp=~s/value=\"/value=\"bug__0__/g;
$results{'RESOLUTION_OPTIONLIST'}[0] .= $tmp;
$results{'RESOLUTION_OPTIONLIST'}[0] .= "<option value=\"\"></option><option value=\"\">Task Resolution</option>\n";
$tmp=&getMenuOptionList( 'resolution', 0, 'task' );
$tmp=~s/value=\"/value=\"task__0__/g;
$results{'RESOLUTION_OPTIONLIST'}[0] .= $tmp;

$results{'PRIORITY_OPTIONLIST'}[0] .= $tmp;
$results{'PRIORITY_OPTIONLIST'}[0] = "<option value=\"\">Bug $c{bugtraq}{label}{priority}</option>\n";
$tmp=&getMenuOptionList( 'priority', 0, 'bug' );
$tmp=~s/value=\"/value=\"bug__0__/g;
$results{'PRIORITY_OPTIONLIST'}[0] .= $tmp;
$results{'PRIORITY_OPTIONLIST'}[0] .= "<option value=\"\"></option><option value=\"\">Task Priority</option>\n";
$tmp=&getMenuOptionList( 'priority', 0, 'task' );
$tmp=~s/value=\"/value=\"task__0__/g;
$results{'PRIORITY_OPTIONLIST'}[0] .= $tmp;

$results{"SEVERITY_OPTIONLIST"}[0] = "<option value=\"\">Bug $c{bugtraq}{label}{severity}</option>\n";
$tmp=&getMenuOptionList( "severity", 0, "bug" );
$tmp=~s/value=\"/value=\"bug__0__/g;
$results{"SEVERITY_OPTIONLIST"}[0] .=$tmp; 
$results{"SEVERITY_OPTIONLIST"}[0] .= "<option></option><option value=\"\">Task $c{tasktraq}{label}{severity}</option>\n";
$tmp=&getMenuOptionList( "severity", 0, "task" );
$tmp=~s/value=\"/value=\"task__0__/g;
$results{"SEVERITY_OPTIONLIST"}[0] .= $tmp;

# take existing results hash and escape single quotes since we are dumping all of this in a javascript quoted string
foreach (keys(%results))
{
	if($results{$_}[0])
	{
		$results{$_}[0]=~s/'/\\'/g;
	}
}

# add javascript output for dynamic project/componentisd
my($javascript) = &makeJs(\@{$projects{'projectid'}},'bug',\@usergroups);
$results{'JS'}[0] = $javascript;                                                                         
my(%tmp);
$tmp{type}='';
$tmp{projectid}='';
$results{'PROJECTID_OPTIONLIST'}[0]=&Traqfields::getFieldOptionList('projectid',\%tmp,$userid);
# First build a status menu of bug status values.
my ( @arr1, @arr2 );
my ($stat);
$y = 0;
my ($i);

# Populate status menu
my (@statusmenu);
foreach $stat ( keys( %{ $menuhashbugs[0]{'status'} } ) )
{
	$statusmenu[$stat][0] = 'bug__0__' . $stat;
	$statusmenu[$stat][1] = $menuhashbugs[0]{status}{$stat};
}
push( @arr1, '' );
push( @arr2, 'Bug Status:' );
for ( $i = 0 ; $i < scalar(@statusmenu) ; $i++ )
{
	if ( $statusmenu[$i] )
	{
		push( @arr1, $statusmenu[$i][0] );
		push( @arr2, $statusmenu[$i][1] );
	}
}

# Add status menus for Tasks
my (@statusmenu);
foreach $stat ( keys( %{ $menuhashtasks[0]{'status'} } ) )
{
	$statusmenu[$stat][0] = 'task__0__' . $stat;
	$statusmenu[$stat][1] = $menuhashtasks[0]{status}{$stat};
}
push( @arr1, '' );
push( @arr2, '' );
push( @arr1, '' );
push( @arr2, 'Task Status:' );
for ( $i = 0 ; $i < scalar(@statusmenu) ; $i++ )
{
	if ( $statusmenu[$i] )
	{
		push( @arr1, $statusmenu[$i][0] );
		push( @arr2, $statusmenu[$i][1] );
	}
}
$results{'STATUS_OPTIONLIST'}[0] = makeOptionList( \@arr1, \@arr2 );

#####
# Populate milestone menu
my (%milestones) = &doSql("select distinct m.milestone, m.milestoneid, m.projectid, p.project from traq_milestones m,traq_project p where m.projectid=p.projectid and m.projectid in (" . join(',',@{$projects{projectid}}) . ") order by p.project, m.milestone");
if (%milestones)
{
	my ( @arr1, @arr2 );
	for ( $i = 0 ; $i < scalar( @{ $milestones{'milestone'} } ) ; $i++ )
	{
		push( @arr1, ( "traq__" . ${ $milestones{'projectid'} }[$i] . "__" . ${ $milestones{'milestoneid'} }[$i] ));
		push( @arr2, "${ $milestones{'project'} }[$i] - ${ $milestones{'milestone'} }[$i]" );
	}
	$results{'MILESTONE_OPTIONLIST'}[0] = makeOptionList( \@arr1, \@arr2 );
}
### Done with data for bulk editor
%results = &populateLabels( \%results, '' );

foreach $ii (keys(%results))
{
	if($ii=~/OPTIONLIST/)
	{
		$results{$ii}[0]=~ s/\n//g;
	}
}
my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"bulkeditor.tmpl",$userid);
$html = Process( \%results, $templatefile );
print $q->header;
print $html;
#&log($html);
&stopLog();
exit;

sub getMenuHash()
{
	my ($type) = shift;
	my (%res)  = &doSql( "select * from traq_menus where rec_type like \"%$type%\" order by value" );
	my (@return);
	for ( my ($i) = 0 ; $i < scalar( @{ $res{'display_value'} } ) ; $i++ )
	{
		$return[ $res{'projectid'}[$i] ]{ $res{'menuname'}[$i] }{ $res{'value'}[$i] } = $res{'display_value'}[$i];
	}
	return @return;
}

