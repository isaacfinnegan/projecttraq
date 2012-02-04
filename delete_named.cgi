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

 my(%res, $connection, $q,$LOGGING,$DEBUG,$userid);
  $LOGGING = 5;
 $DEBUG=1;
$q = new CGI;
	$DEBUG = $q->param('debug');
 $userid = &getUserId($q);

 my($qname) = $q->param('qname');
 my($sql) = "delete from traq_namedqueries where userid=\"$userid\" and name=\"$qname\"";
 &doSql($sql);
 &log("deleted named query: $qname", 3);
 #print $q->header;
 print $q->redirect("./actioncomplete.cgi?id=&action=deleteQuery-$qname&result=Success");
 	
 &stopLog();
