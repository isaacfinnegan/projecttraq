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

 my($q,$usercookie,$passcookie,$session);
 $q = new CGI;
# my($userid) = getUserId($q);

       	$usercookie = $q->cookie(-name=>'cname',
                                -value=>"", 
                                -expires=>'+8h',
								-path=>'/',
                                );
         $passcookie = $q->cookie(-name=>'cpwd',
                                -value=>"",
                                -expires=>'+8h',
								-path=>'/',
                                );
         $session = $q->cookie(-name=>'pt_session',
                                -value=>"",
                                -expires=>'+8h',
								-path=>'/',
								);
	print $q->header(-cookie=>[$usercookie,$passcookie,$session]); 
	print "You have been logged out. <br>";
	print "Please follow <a href=\"./\">this</a> link to log back in to ProjectTraq.";
	exit;

