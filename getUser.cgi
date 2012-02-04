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

my ($sql, $html,$area, $ii,$recordid,$mode,$tmp,$userid,$y,$field,@fieldlist,$delimit,%rec);

my ($userid) = &getUserId($q);

$recordid = $q->param('id');
$recordid=~s/[bBtT](\d+)/$1/;
$mode = $q->param('mode');
unless ($mode)
{
	print $q->header;
	print $html;
	&stopLog();
	exit;
}

my($qry)=$q->param('qry');
if($mode eq 'userlookupbyname')
{
	$sql="select concat(first_name,' ', last_name) as fullname from logins where first_name like '%$qry%' or last_name like '%$qry%' order by first_name";
	%rec=&doSql($sql);
	if(%rec)
	{
		print $q->header;
		for($ii=0;$ii<scalar(@{$rec{fullname}});$ii++)
		{	
			print "$rec{fullname}[$ii]\n";
		}
		&stopLog();
		exit;
	}

}
if($mode eq 'userlookupbyId')
{
	$sql="select concat(first_name,' ', last_name) as fullname from logins where userid =$qry order by first_name";
	%rec=&doSql($sql);
	if(%rec)
	{
		print $q->header;
		for($ii=0;$ii<scalar(@{$rec{fullname}});$ii++)
		{	
			print "$rec{fullname}[$ii]\n";
		}
		&stopLog();
		exit;
	}

}

if($mode eq 'getusersbyproject')
{
	if($qry=~/\D/)
	{
		print "ERROR";
		exit;
	}
	my %userhash=&db_GetUserHashforProject($qry);
	if(%userhash)
	{
		print $q->header;
		my($ii)=0;
		my(@keys)=keys(%userhash);
		@keys=sort {$userhash{$a}{full_name} cmp $userhash{$b}{full_name}} @keys;
		if($q->param('yui'))
		{
			print "Ext.userdata.userlist=[\n";
			foreach my $useridkey (@keys)
			{	
				print "['$useridkey', '$userhash{$useridkey}{full_name}']";
				unless($ii==scalar(@keys)-1)
				{
					print ",\n";
				}
				$ii++;
			}			
			print "];\n";
		}
		else
		{
			foreach my $useridkey (@keys)
			{	
				print "usernamelist[$ii]='$userhash{$useridkey}{full_name}';\n";
				print "useridlist[$ii]='$useridkey';\n";
				$ii++;
			}
		}
		&stopLog();
	}	
	exit;
}


if( &isValidRecord($recordid) && &isEditAuthorized( $userid, $recordid ) && $mode)
{
	if($mode eq 'lastlongdesc')
	{
		$html="<span class=longdesclabel>Last Comment on Record $recordid:</span><br>";
		$html.=&getLongDesc($recordid,'','last');
	}
	if($mode eq 'getfield')
	{
		$field=$q->param('field');
		%rec=&db_GetRecord($recordid);
		$html= &Traqfields::getFieldDisplayValue( $field, \%rec, $userid );
	}
	if($mode eq 'getfields')
	{
		@fieldlist=split(',',$q->param('fieldlist'));
		%rec=&db_GetRecord($recordid);
		$area=$rec{type} . 'traq';
		$delimit=$q->param('delimiter');
		foreach $tmp (@fieldlist)
		{
			if($q->param('class'))
			{
				$html.="<div class=" . $q->param('class') . ">";
			}
			if($q->param('label'))
			{
				$html.="\n$c{$area}{label}{$tmp}: ";
			}
			$html.= &Traqfields::getFieldDisplayValue( $tmp, \%rec, $userid );
			$html.=$delimit;
			if($q->param('class'))
			{
				$html.="</div>";
			}
		}
	}

}

print $q->header;
print $html;
&stopLog();
exit;
