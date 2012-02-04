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
# Add keyword
if($q->param('add'))
{
	my($keyword)=$q->param('keyword');
	my($description)=$q->param('description');
	
	#check for existing keyword with that name
#		$keyword = lc($keyword);
	%res=&doSql("select name from traq_keywords where name=\"$keyword\"");
	if(scalar(keys(%res)))
	{
		&doError("Keyword already exists");
	}
	$sql="insert into traq_keywords set name=\"$keyword\", description=\"$description\"";
	&doSql($sql);
		
	print $q->redirect("$c{url}{base}/editsystem.cgi?mode=Keywords");
}
# Delete keyword
if($q->param('delete'))
{
	my($del)=$q->param('delete');
	
	&doSql("delete from traq_keywords where keywordid=$del");
	&doSql("delete from traq_keywordref where keywordid=$del");
	print $q->redirect("$c{url}{base}/editsystem.cgi?mode=Keywords");
}

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
}

$html{KEYWORDSLABEL}[0]=$c{general}{label}{keywords};
my(@sysmenus)=split(',',$c{general}{systemmenu});
$i=0;
foreach $menu (@sysmenus)
{
	&log("MENU: $menu - $c{general}{label}{$menu}",5);
	$html{MENU}[$i]=$menu;
	$html{MENULABEL}[$i]=$c{general}{label}{$menu};
	$i++;
}

print $q->header;
$html{PISSROOT}[0] = $c{url}{base};
$html{FOOTER}[0] = &getFooter($userid, 'traq');
$html{HEADER}[0] = &getHeader($userid, 'traq');
my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'sys_admin.tmpl',$userid);
print &Process(\%html,$templatefile);
