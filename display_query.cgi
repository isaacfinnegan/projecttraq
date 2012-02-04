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

 	
my($LOGGING,$TASKS,$connection,$q,$DEBUG,$userid,$db,@groups,$item);
&startLog();
$LOGGING = 5;
$TASKS=1;
$DEBUG = 0;
$connection;
$q = new CGI;  

my %results;
my $html;
my $sql_statement;
my %paramhash;
my %hash;
my $loop_count = 0;
my $user;
my $cat=$q->param('cat');
$c{cache}{currenttype}=$cat;
$user = &getUserId($q);
$userid = $user;
print $q->header;

#-------------------------------------------------

my(@usersgroups)=getGroupsFromEmployeeId($userid);
&log( "DEBUG: got user groups @groups") if $DEBUG;
my(@groups)=@usersgroups;
my(%projects) = GetUserProjects(\%results, $db, @groups);

my($iii) = 0;
for(my($i) =0; $i < scalar(@{$projects{'project'}}); $i++) {
	$results{'PROJECT'}[$i] = $projects{'project'}[$i];
	$results{'PROJECTID'}[$i] = $projects{'projectid'}[$i];
}
my(%tmp);
foreach $item (keys(%{$c{general}{label}}))
{
	$tmp{$item}='';
}
# assemble field list for boolean field query
my($label);
unless($cat)
{
    $cat='bug';
}
my($labelarea)=$cat . "traq";
my($area)=$cat.'traq';
my(%fieldlist)=%{$c{$area}{label}};
my($dd,$ff);
my($projectlist)=join(',',@{$projects{'projectid'}});
$tmp{type}=$cat;
%results = &populateLabels( \%results, $cat );
unless($q->param('returnfields'))
{
	$results{RETURNFIELDS}[0]=join(',',&getSavedReturnFields($userid));
}
else
{
	$results{RETURNFIELDS}[0]=$q->param('returnfields');
}
# define some arrays needed for menu displays
my(@type_val)=('substring','casesubstring','allwords','anywords','regexp','notregexp');
my(@type_disp)=('case-insensitive substring','case-sensitive substring','all words','any words','regular expression','not (regular expression)');
my(@bool_val)=('bug_depends','bug_blocked','traq_attachments.description','traq_attachments.mimetype','traq_attachemnts.ispatch','delta_ts','(to_days(now()) - to_days(rec.delta_ts))','lng.thetext');
my(@bool_disp)=("$c{$area}{label}{record_id} This Depends On","Other $c{$area}{label}{record_id} Depending On This",'Attachment Description','Attachment mime type','Attachment is patch',"$c{$area}{label}{delta_ts}",'Days since record changed',"$c{$area}{label}{long_desc}");
my(@boolop_val)=('equals','notequals','casesubstring','substring','notsubstring','regexp','notregexp','lessthan','greaterthan','anywords','allwords','nowords','changedbefore','changedafter','changedto','changedby');
my(@boolop_disp)=('equal to','not equal to','contains (case-sensitive) substring','contains (case-insensitive) substring','does not contain (case-sensitive) substring','contains regexp','does not contain regexp','less than','greater than','any words','all words','none of the words','changed before','changed after','changed to','changed by');


my(%fieldlist)=%{$c{$area}{label}};
$iii=0;
my(@fields);
foreach $dd (sort { $fieldlist{$a} cmp $fieldlist{$b} } (keys(%fieldlist)))
{
    $results{FIELD}[$iii]=$dd;
    $results{FIELDLABEL}[$iii]=$fieldlist{$dd} || $dd;
    $iii++;
    push(@fields, "'$dd'");
}
push(@fields,("'role'","'attachments'","'boolean'","'changes'"));
$results{FIELDLIST}[0]=join(',', @fields);

my(@params)=$q->param();
foreach $dd (@params)
{
	$results{$dd}[0]=$q->param($dd);
}
my(@fieldarealist)=$q->param('fieldarealist');
$results{FIELDAREALIST}[0]=join(',',@fieldarealist);
my(@menulist);
# build list of fields that are menus
push(@menulist,split(',',$c{general}{systemmenu}));
push(@menulist,split(',',$c{general}{projectmenu}));
push(@menulist,split(',',$c{general}{rolemenu}));
my(@roles)=split(',',$c{general}{rolemenu});
push(@roles,'cc');
push(@menulist,('projectid','componentid','target_milestone'));
# build optionlist for each of these fields
foreach $item (@menulist)
{
	if($q->param($item) || $item eq 'projectid')
	{
		$tmp{$item}=join(',',$q->param($item));
	}
	else
	{
		$tmp{projectid}=$projectlist;
	}
	my($templatevalue)=uc($item) . '_OPTIONLIST';
	$results{$templatevalue}[0]=&Traqfields::getFieldOptionList($item,\%tmp,$userid);
	$results{$templatevalue}[0]=~s/<option\ value=""><\/option>|<option\ value=''>/<option\ value="-null-">-null-<\/option>/;
}

# also process menus for each role group
my($grpsql) = "select groups.groupid,groups.groupname,user_groups.groupid ";
$grpsql.="from groups,user_groups where groups.groupid=user_groups.groupid ";
$grpsql.="and userid=$userid and groups.groupname not like \"%-owners\" order by groupname";
my(%grps) = &doSql($grpsql);
foreach $item (@roles)
{
	my($templatevalue)=uc($item) . 'GROUP_OPTIONLIST';
	$results{$templatevalue}[0]= &makeOptionList(\@{$grps{groupid}},\@{$grps{groupname}},$q->param($item . 'group') );
}

# step through the rest of the fields and draw the optionlists for any query _type params
foreach $item (keys(%fieldlist))
{
	$results{$item.'_type_optionlist'}[0]=&makeOptionList(\@type_val,\@type_disp,$q->param($item.'_type'));
}

# remove external fields and virtual fields from field list for boolean list
foreach $dd (split(',',$c{general}{externalfields}))
{
	delete($fieldlist{$dd});
}
foreach $dd (split(',',$c{general}{virtualfields}))
{
	delete($fieldlist{$dd});
}
$ff=0;
my(@fieldval,@fielddisp);
# build field list (used by boolean, changes, orderby, columns)
foreach $dd (sort { $fieldlist{$a} cmp $fieldlist{$b} } (keys(%fieldlist)))
{
	unshift(@bool_val,$dd);
	unshift(@bool_disp,$fieldlist{$dd});
	push(@fieldval,$dd);
	push(@fielddisp,$fieldlist{$dd});
	
}
# build option lists for boolean field menus
$results{bool_field1_optionlist}[0]=&makeOptionList(\@bool_val,\@bool_disp,$q->param('bool_field1'));
$results{bool_field2_optionlist}[0]=&makeOptionList(\@bool_val,\@bool_disp,$q->param('bool_field2'));
$results{bool_field3_optionlist}[0]=&makeOptionList(\@bool_val,\@bool_disp,$q->param('bool_field3'));
$results{bool_operator1_optionlist}[0]=&makeOptionList(\@boolop_val,\@boolop_disp,$q->param('bool_operator1'));
$results{bool_operator2_optionlist}[0]=&makeOptionList(\@boolop_val,\@boolop_disp,$q->param('bool_operator2'));
$results{bool_operator3_optionlist}[0]=&makeOptionList(\@boolop_val,\@boolop_disp,$q->param('bool_operator3'));

# populate some misc. query options (checkboxes radio buttons, etc...
if($q->param('return_bugs') || ($cat eq 'bug' && !$q->param('return_bugs') && !$q->param('return_tasks') ) )
{
	$results{'return_bugs'}[0]='checked';
}
if($q->param('return_tasks') || ($cat eq 'task'  && !$q->param('return_bugs') && !$q->param('return_tasks') ) )
{
	$results{'return_tasks'}[0]='checked';
}

# Changes query 
$results{CHANGEBY_OPTIONLIST}[0]=&getUserOptionList($projectlist,$q->param('changeby'));
$results{ROLE_CC_OPTIONLIST}[0]=&getUserOptionList($projectlist,$q->param('cc'));
my(@attach)=('','Yes','No');
$results{'attach_have_optionlist'}[0]=&makeOptionList(\@attach,\@attach,$q->param('attach_have'));
$results{CHFIELD_OPTIONLIST}[0]=&makeOptionList(\@fieldval,\@fielddisp,$q->param('chfield'));
my(@andor)=('or','and');
$results{ROLE_ANDOR_OPTIONLIST}[0]=&makeOptionList(\@andor,\@andor,$q->param('role_andor'));

# status class query option
my(@status_class_v)=('open','resolved','closed');
my(@status_class_d)=('Open States','Resolved State','Closed States');
$results{STATUS_CLASS_OPTIONLIST}[0]=&makeOptionList(\@status_class_v,\@status_class_d,$q->param('status_class'));
# order by query option
$results{ORDERBY_OPTIONLIST}[0]=&makeOptionList(\@fieldval,\@fielddisp,$q->param('orderby'));
my(@orderby_dir)=('ASC','DESC');
$results{ORDERBYDIR_OPTIONLIST}[0]=&makeOptionList(\@orderby_dir,\@orderby_dir,$q->param('orderbydir'));
# columns query option
my(@returnfields)=$q->param('returnfields');
$results{COLUMNS_OPTIONLIST}[0]=&makeOptionList(\@fieldval,\@fielddisp,\@returnfields);


push(@andor,'andnot');

$results{BOOL_TYPE1_OPTIONLIST}[0]=&makeOptionList(\@andor,\@andor,$q->param('bool_type1'));
$results{BOOL_TYPE2_OPTIONLIST}[0]=&makeOptionList(\@andor,\@andor,$q->param('bool_type2'));
$results{BOOL_TYPE3_OPTIONLIST}[0]=&makeOptionList(\@andor,\@andor,$q->param('bool_type3'));


my($javascript) = &makeJs(\@{$results{'PROJECTID'}},$cat,\@usersgroups);
$results{'JS'}[0] = $javascript;
   	
my %khsh;
my %keywords= &getKeywords();
my @keywds;
@keywds=$q->param('keywords');

if(@keywds)
{
	foreach (@keywds)
	{
		$khsh{$_}=1;
	}
	for(my $qq=0;$qq<scalar(@{$keywords{keywordid}});$qq++)
	{
		if($khsh{$keywords{keywordid}[$qq]})
		{
			$keywords{CHECKED}[$qq]='checked';
		}
		else
		{
			$keywords{CHECKED}[$qq]='';
		}
	}
}
%results = &mergeResults(%results, %keywords);

foreach $label (keys(%{$c{$labelarea}}))
{
	$results{$label . 'label'}[0]=$c{$labelarea}{$label};
}
#-------------------------------------------------

$results{'PISSROOT'}[0] = $c{'url'}{'base'};
$results{PROJECTIDLABEL}[0]=$c{general}{label}{projectid};

# get the HTML file with replaced order detail values
&log ("DEBUG: starting processing") if $DEBUG;
#	&populateHeaderFooter(\%results, "nodyn");
my($querytemplate)="query_dhtml_" . $cat . ".tmpl";
$querytemplate=&getTemplateFile($c{dir}{generaltemplates},$querytemplate,$userid);
$results{HEADER}[0]= &getHeader($userid, $cat);
$results{FOOTER}[0]= &getFooter($userid, $cat);
$html = Process(\%results, $querytemplate);
&log( "DEBUG: finished processing") if $DEBUG;
print $html;
&stopLog();