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


 my($LOGGING,$userid,$label,$field);

 &startLog();
 $LOGGING = 5;

 my(%res, $projectID, $connection, $q);
 my($q) = new CGI;
 my($userid) = &getUserId($q);
 my($selfurl)  = $q->url(-absolute=>1);
 my($confkey) = "general"; 
 my($queryid)= $q->param('queryid');
 my($mode) = $q->param('mode') || "view";
 my($id) = $q->param('id');
 
if($mode eq "view") {
	unless($userid)
	{
		&doError("This user is not allowed here.");
	}
	my(%prefs) = &getMailPrefs($userid);
	my($pref);
	foreach $pref (@{$prefs{'prefs'}}) {
		$res{$pref}[0] = "CHECKED";
	}
	my(@fieldlist)=keys(%{$c{general}{label}});
	my(@ext_fields)=split(',',$c{general}{externalfields});	
	foreach $field (sort { $c{general}{label}{$a} cmp $c{general}{label}{$b}  } (@fieldlist))
	{
		unless(grep(/^$field$/, @ext_fields))
		{
			$res{$field}[0]=$c{general}{label}{$field};
			push(@{$res{field}},$field);
			push(@{$res{fieldlabel}},$c{general}{label}{$field});
		}
	}
	%res=&populateLabels(\%res,'');
	
	# populate field list for query return fields and list of user selected fields
	my(@returnFields)=&getSavedReturnFields($userid);
	my($field);
	my($i)=0;
	$res{RETURNFIELDS}[0]=join(',',@returnFields);
	foreach $field (@returnFields) {
		my($key) = "check" . "_" . $field;
		$res{$key}[0]="selected";
		$res{RETURNVALUE}[$i]=$field;
		$res{RETURNLABEL}[$i]=$c{general}{label}{$field};
		$i++;
	}
	$i=0;
	foreach $field (sort @fieldlist)
	{
		if(!grep(/$field/,@returnFields))
		{
			$res{FIELDVALUE}[$i]=$field;
			$res{FIELDLABEL}[$i]=$c{general}{label}{$field};
			$i++;
		}
	}
	
	# Populate field pull downs for query results record ordering
	my($orderby) = &getSavedOrderBy($userid);	
	if($orderby)
#	if($orderby =~ /\w+\s+\w+,/) 
	{		
		my(@orders) = split(/,/, $orderby);
		for(my($i)=0; $i < scalar(@orders);$i++) 
		{
			my($x) = $i+1;
			my($key) = "order" . $x;
			$orders[$i] =~ /(\w+) (\w+)/;
#			my($field, $dir) = ($1, $2); 
			my($field, $dir) = split(" ", $orders[$i]);
# 			$res{$key}[0] = $orders[$i]; #what is this for?
			$res{$key}[0] = $field;
			if($dir)
			{
				my($key2) = $key . $dir;
				$res{$key2}[0] = "checked";
			}
			my($key3)=$key . 'label';
			my($fieldlabellookup) = $field . 'label';
			$res{$key3}[0] =getFieldLabel($field,$confkey);
		}
	}
	$res{'QUERYID'}[0]=$queryid;
	$res{'TAB'}[0]=$q->param('tab');
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'prefs.tmpl',$userid);
	print $q->header;
	$res{PISSROOT}[0]=$c{url}{base};
 	$res{HEADER}[0]=  &getHeader($userid, "traq");
	$res{FOOTER}[0]=  &getFooter($userid, "traq");
	my($html) = &Process(\%res,$templatefile);
	print $html;
}
elsif($mode eq "save") {
	my(@bprefs) =$q->param('bugprefs');
	my(@mailprefs)= $q->param('mailprefs');
	push(@bprefs,@mailprefs);
	my($modepref) = $q->param('modepref');
	my($comppref) = $q->param('completion');
	my($x);
	# pref setting for email on status, priority,severity, milestone only puts in for status. so add others
	foreach $x ("assigned","tech","qa","reporter")
	{
		my($y)="email_" . $x . "_status";
		if(grep(/$y/,@bprefs))
		{
			push(@bprefs, ("email_". $x ."_priority","email_". $x ."_severity","email_". $x ."_milestone"));
		}
	}
	my($pref) = join(" ", @bprefs, $modepref, $comppref);
	my($sql) = "update $c{db}{logintable} set bugtraqprefs=\"$pref\" where $c{db}{logintablekey}=$userid";
	&doSql($sql);
	my(@returnfields)=$q->param('returnfields');
	if(scalar(@returnfields)==1 && $returnfields[0]=~/,/)
	{
		@returnfields=split(',',$returnfields[0]);
	}
	&saveReturnFields(\@returnfields,$userid);
	my($order1) = $q->param('order1');
	my($dir1) = $q->param('dir1');
	unless($order1){
		$dir1 ="";
	}
	&doSql("update $c{db}{logintable} set order1 = \"$order1 $dir1\" where userid=$userid");
	my($order2) = $q->param('order2');
	my($dir2) = $q->param('dir2');
	unless($order2) {
		$dir2 ="";
	}
	&doSql("update $c{db}{logintable} set order2 = \"$order2 $dir2\" where userid=$userid");
	my($order3) = $q->param('order3');
	my($dir3) = $q->param('dir3');
	unless($order3) {
		$dir3 ="";
	}
	&doSql("update $c{db}{logintable} set order3 = \"$order3 $dir3\" where userid=$userid");
	$res{'ACTION'}[0] = "Save Preferences";
	$res{'RESULT'}[0] = "Success";
	$res{'USER'}[0] = &getNameFromId($userid);
	$res{'PISSROOT'}[0] = $c{'url'}{'base'};
	if($c{cache}{usecache})
	{
	   	my($cache)=new Cache::FileCache({'namespace' => "user-$c{session}{key}" });
        $cache->clear();
	}

	if($queryid)
	{
		print $q->redirect("$c{url}{base}/do_query.cgi?queryid=$queryid");
		exit;
	}
	else
	{
		$res{QUERYID}[0]='none';
	}
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'action.tmpl',$userid);
	print $q->header;
	$res{PISSROOT}[0]=$c{url}{base};
 	$res{HEADER}[0]=  &getHeader($userid, "traq");
	$res{FOOTER}[0]=  &getFooter($userid, "traq");
	my($html) = &Process(\%res,$templatefile);
	print $html;
}
