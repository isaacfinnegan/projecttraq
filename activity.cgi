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
 my($connection, $q,$DEBUG,$LOGGING,$userid);
 $LOGGING = 5;
 $DEBUG=1;

 $q = new CGI;
 $DEBUG = $q->param('debug');
 $userid = &getUserId($q);
 my($id) = $q->param('id');
 my($type)= $q->param('type');
 
 my($sql) = "select * from traq_activity where record_id=$id and fieldname != \"delta_ts\" order by date";
 my(%res) = &doSql($sql);
 &log("Activity sql: $sql", 5);
 $res{TYPE}[0]=$type;
for(my($i) = 0 ; $i < scalar(@{$res{'who'}}); $i++) {
	$res{'who'}[$i] = &getNameFromId($res{'who'}[$i]);
	$res{change}[$i]="Changed";
	$res{from}[$i]='from';
	$res{to}[$i]='to';

	if($res{'fieldname'}[$i] eq "assigned_to" || $res{'fieldname'}[$i] eq "tech_contact" || $res{'fieldname'}[$i] eq "qa_contact" || $res{'fieldname'}[$i] eq "who"){
		$res{'oldvalue'}[$i] = &getNameFromId($res{'oldvalue'}[$i]);
		$res{'newvalue'}[$i] = &getNameFromId($res{'newvalue'}[$i]);
		
	}
	if($res{'fieldname'}[$i] eq "status" || $res{'fieldname'}[$i] eq "resolution" || $res{'fieldname'}[$i] eq "severity") {
		$res{'oldvalue'}[$i] = &getMenuDisplayValue("0", $res{'fieldname'}[$i], $res{'oldvalue'}[$i],$type);
		&log("old: $res{'oldvalue'}[$i]", 5);
		$res{'newvalue'}[$i] = &getMenuDisplayValue("0", $res{'fieldname'}[$i], $res{'newvalue'}[$i],$type);		
		&log("new: $res{'newvalue'}[$i]", 5);
	}
    if( $res{fieldname}[$i] eq "target_milestone" ) {
            $res{newvalue}[$i] = &getMilestoneDisplayValue(0, $res{newvalue}[$i]);
            $res{oldvalue}[$i] = &getMilestoneDisplayValue(0, $res{oldvalue}[$i]);
    }
    if($res{fieldname}[$i] eq 'New Record')
    {
		$res{change}[$i]="Record Created";
    	$res{newvalue}[$i]='';
    	$res{oldvalue}[$i]='';
		$res{from}[$i]='';
		$res{to}[$i]='';
		$res{fieldname}[$i]='';
	}
    elsif($res{fieldname}[$i] eq 'text')
    {
		$res{change}[$i]=$c{ $type."traq" }{label}{note} . " added";
    	$res{newvalue}[$i]='';
    	$res{oldvalue}[$i]='';
		$res{from}[$i]='';
		$res{to}[$i]='';
		$res{fieldname}[$i]='';
	}
    else
    {
		unless($res{newvalue}[$i])
		{
			$res{newvalue}[$i]='<font color=gray>null</font>';
		}	
		unless($res{oldvalue}[$i])
		{
			$res{oldvalue}[$i]='<font color=gray>null</font>';
		}
	    $res{fieldname}[$i]=$c{ $type."traq" }{label}{ $res{fieldname}[$i] } || $res{fieldname}[$i];
	}
}
 
 $res{'RECORDID'}[0] = $id;
 $res{'PISSROOT'}[0] = $c{'url'}{'base'};
 my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'activity.tmpl',$userid);
 my($html) = &Process(\%res, $templatefile);
 print $q->header;
 #print  &getHeader($userid, $type);
 print $html;
 #print &getFooter($userid, $type);

