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

my($field,%html,$html, $connection, $q,$userid,$i,$item,$key,%menunames,$mode,%parent);
$q = new CGI;
$userid = &getUserId($q);
my($projectid)=$q->param('projectid');
my($action) = $q->param('action');
my($id) = $q->param('id');
my($menuname) = &escapeQuotes($q->param('menuname'));
my($display_value) = &escapeQuotes($q->param('display_value'));
my($rec_type)=$q->param('bug') . ' ' . $q->param('task');
my($value) = $q->param('value');
my($parent)= $q->param('parent');
my($menu)=$q->param('menu')||$menuname;

if($c{general}{menudependency})
{
    if($c{general}{menudependency}{$menu})
    {
        %parent=&doSql("select value,display_value from traq_menus where project=$projectid and menuname=\"$c{general}{menudependency}{$menu}\" order by value");
        $html{ADDPARENT_OPTIONLIST}[0]=&makeOptionList(\@{$parent{value}},\@{$parent{display_value}},'');
    }
}

$html{PROJECTIDLABEL}[0]="ProjectTraq System";
$html{PID}[0]=$projectid;
$html{MENUNAME_ALT}[0]=$menu;

no strict 'refs';
if($projectid)
{
	$html{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};
	$html{PROJECTID_DISP}[0]=&getFieldDisplayValue('projectid',{projectid=>$projectid},$userid);
}
$html{MENU}[0]=$c{general}{label}{$menu};

unless(&isProjectAdmin($userid,$projectid))
{
	&doError("You are not authorized for this function");
}
if($action) 
{
	if($action eq "Delete") 
	{
		&doSql("delete from traq_menus where id=$id");
	}
	elsif($action eq "Add") 
	{
		&doSql("insert into traq_menus set menuname=\"$menuname\",display_value=\"$display_value\",value=\"$value\", project=$projectid, rec_type=\"$rec_type\", parent=\"$parent\"");
	}
	elsif($action eq "Update")
	{
		&doSql("update traq_menus set  menuname=\"$menuname\",display_value=\"$display_value\",value=\"$value\", project=$projectid, rec_type=\"$rec_type\", parent=\"$parent\" where id=$id");
	}
	elsif($action eq 'ClearDefaults')
	{
&log("DEBUG: action: $action");
		&doSql("update traq_menus set def=0 where project=$projectid and menuname=\"$menu\"");
	}
	elsif($action eq 'Default')
	{
		if($id)
		{
			&doSql("update traq_menus set def=1 where id=$id");
		}
	}
	if($c{cache}{usecache})
	{
	   	my($cache)=new Cache::FileCache({'namespace' => "menu-$c{session}{key}" });
        $cache->clear();
	}
	print $q->redirect("./menus_edit.cgi?projectid=$projectid&menu=$menu");
	exit;    
 }


%menunames=&doSql("select * from traq_menus where project=$projectid and menuname=\"$menu\" order by parent,value");

for($i=0;$i<scalar(@{$menunames{id}});$i++)
{
	$html{PROJECTID_VAL}[$i]=$projectid;
	$html{ID}[$i]=$menunames{id}[$i];
	$html{DISPLAY_VALUE}[$i]=$menunames{display_value}[$i];
	$html{MENUNAME}[$i]=$menunames{menuname}[$i];
	$html{VALUE}[$i]=$menunames{value}[$i];
	if($menunames{def}[$i])
	{
		$html{DEFAULT}[$i]='default';
	}
	else
	{
		$html{DEFAULT}[$i]='';
	}
	if(grep(/bug/,($menunames{rec_type}[$i])))
	{
		$html{BUGSELECTED}[$i]='checked';
	}
	else
	{
		$html{BUGSELECTED}[$i]='';
	}
	if(grep(/task/,($menunames{rec_type}[$i])))
	{
		$html{TASKSELECTED}[$i]='checked';
	}
	else
	{
		$html{TASKSELECTED}[$i]='';
	}
    if($c{general}{menudependency})
    {
        if($c{general}{menudependency}{$menu})
        {
            $html{PARENT_OPTIONLIST}[$i]=&makeOptionList(\@{$parent{value}},\@{$parent{display_value}},$menunames{parent}[$i]);
        }
    }
}
my($templatefile);
&log("DEBUG: $menu: $c{general}{menudependency}{$menu}");
if($c{general}{menudependency})
{
    if($c{general}{menudependency}{$menu})
    {
        $templatefile="$c{dir}{generaltemplates}/menus_edit_dep.tmpl"
    }
    else
    {
        $templatefile="$c{dir}{generaltemplates}/menus_edit.tmpl"
    }
}
$html{PISSROOT}[0] = $c{url}{base};
$html{FOOTER}[0] = &getFooter($userid, 'traq');
$html{HEADER}[0] = &getHeader($userid, 'traq');
$html=&Process(\%html,$templatefile);
print $q->header;
print $html;
