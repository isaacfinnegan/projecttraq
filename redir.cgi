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

my($userid,%res, $projectID, $connection, $q);

$q = new CGI;
$DEBUG = $q->param('debug');
$userid = &getUserId($q);
my($id) = $q->param('id');
my($queryid) = $q->param('queryid');
my($type);

$id =~ s/(\D)//;
if($id=~/\D/)
{
	&doError("Invalid Record Id");
}
if($id) {
        unless(&isValidRecord($id)) {
		print $q->header;
                &doError("Invalid Record Id");
        }
	$type = &getRecordType($id);
}
elsif($q->param('type') ) {
	$type=$q->param('type');
}
else {
	$type = "bug";
}
my($method) = $q->param('method') || $q->param('type') || "look";
my($templatename) = $q->param('templatename');
my($category)= $q->param('category');
my($templatefile)= $q->param('templatefile');
my($area)=$type.'traq';
my($url)="$c{url}{$type}/$c{$area}{formcgi}?type=$method";
$url.="&templatename=$templatename" if $templatename;
$url.="&id=$id" if $id;
$url.="&category=$category" if $category;
$url.="&queryid=$queryid" if $queryid;
$url.="&templatefile=$templatefile" if $templatefile;

print $q->redirect($url);
exit;
