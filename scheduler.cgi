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
use Traqfields;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
my ($headersent) = 0;
my (%clear);
%{ $c{cache} } = %clear;

&startLog();
my ($LOGGING) = 5;
my ($q);
$q = new CGI;
my $DEBUG = $q->param('debug') || 0;
my $userid       = &getUserId($q);
my (@usergroups) = &getGroupsFromUserId($userid);
my ($groupid)    = &getGroupIdFromName('Scheduler');
my $id = $q->param('id');

my ($mode) = $q->param('mode') || "list";
if ( $mode eq 'sendnow' )
{
	my $out= `cd $c{dir}{general}; /usr/bin/perl $c{dir}{general}schedulerd.pl $id`;
	&log("Immediate schedule run: $id - output: $out",7);
	print $q->redirect('./scheduler.cgi');
}
if ( $mode eq 'list' )
{
	my ($sql) = "select * from schedule where userid='$userid'";
	my %res = doSql($sql);
	if ( grep( /^$groupid$/, @usergroups ) )
	{
		$res{scheduleradminstart}[0] = '';
		$res{scheduleradminend}[0]   = '';
	}
	else
	{
		$res{scheduleradminstart}[0] = '<!--';
		$res{scheduleradminend}[0]   = '-->';
	}
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"scheduler.tmpl",$userid);
	$res{PISSROOT}[0] = $c{url}{base};
	$res{FOOTER}[0] = &getFooter($userid, 'traq');
	$res{HEADER}[0] = &getHeader($userid, 'traq');
	my $html = &Process( \%res, $templatefile );
	print $q->header;
	print $html;
}
if ( $mode eq 'delete' )
{
	if ( &isOwner( $userid, $id ) ) { &deleteSchedule($id) }
	print $q->redirect('./scheduler.cgi');
	exit;
}
if ( $mode eq 'activate' )
{
	if ( &isOwner( $userid, $id ) ) { &activateSchedule($id) }
	print $q->redirect('./scheduler.cgi');
	exit;
}
if ( $mode eq 'deactivate' )
{
	if ( &isOwner( $userid, $id ) ) { &deactivateSchedule($id) }
	print $q->redirect('./scheduler.cgi');
	exit;
}
if ( $mode eq "newschedule" )
{
	my $urls       = $q->param('urls');
	my $month      = $q->param('month');
	my $dayofweek  = $q->param('dayofweek');
	my $dayofmonth = $q->param('dayofmonth');
	my $hour       = $q->param('hour');
	my $minute     = $q->param('minute');
	my $comment    = $q->param('comment');
	my $alt_email;

	if ( grep( /^$groupid$/, @usergroups ) )
	{
		$alt_email = $q->param('alt_email');
	}
	unless ($urls) { print $q->header; print "You must enter at least one url"; exit; }
	my $sql = "insert into schedule (alt_email,userid, url, min, hour, day, dayofweek, month, active, comment) 
 			values (\'$alt_email\', \'$userid\', \'$urls\', \'$minute\', \'$hour\', \'$dayofmonth\', \'$dayofweek\', \'$month\', \'yes\', \'$comment\')";
	&doSql($sql);
	if ($DEBUG) { print $q->header; print "$sql saved"; }
	else { print $q->redirect('./scheduler.cgi'); }
}

sub isOwner
{
	my $userid = shift;
	my $id     = shift;
	my %res    = doSql("select userid from schedule where schedule_id=$id");
	if ( $res{userid}[0] == $userid ) { return 1; }
	else { return 0; }
}

sub deleteSchedule
{
	my $id = shift;
	&doSql("delete from schedule where schedule_id=$id");
}

sub activateSchedule
{
	my $id = shift;
	&doSql("update schedule set active=\'yes\' where schedule_id=$id");
}

sub deactivateSchedule
{
	my $id = shift;
	&doSql("update schedule set active=\'no\' where schedule_id=$id");
}


