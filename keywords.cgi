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

 my($headersent) = 0;
 my(%clear);
%{$c{cache}}=%clear;

 &startLog();
 my($LOGGING) = 5;

 my(%html, %res,$i, $menu,$connection, $q, $sql,$userid);
 $q = new CGI;
 $userid = &getUserId($q);

#############################
# KEYWORDS
#############################
	#display keyword list
	%res=&doSql("select * from traq_keywords");
	if(%res)
	{
	for(my($i)=0; $i < scalar(@{$res{'keywordid'}}); $i++)
	{
		$html{KEYWORDID}[$i]=$res{keywordid}[$i];
		$html{KEYWORD}[$i]=$res{name}[$i];
		$html{DESC}[$i]=$res{description}[$i];
	}

	print $q->header;
    print &getHeader($userid, 'traq');
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"keywords.tmpl",$userid);
	print Process(\%html, $templatefile);
    print &getFooter($userid, 'traq');
}



