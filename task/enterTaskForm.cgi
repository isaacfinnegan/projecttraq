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

use lib "../lib";
use TraqConfig;
use dbFunctions;
use supportingFunctions;
use Traqfields;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});

my($timer);
if($c{profile})
{
	eval("use Time::HiRes");
	eval("use Time::Stopwatch");
    tie $timer, 'Time::Stopwatch';

}

&startLog();

my ( $LOGGING, $TASKS, $PRO, $userid, $DEBUG, $i, $recordid, %milestones, %compmenu, $key, %ccs );
my ( $tfile,$templatefile, $type, $projectid, $reporter, %owners, @groups, $db, $prid, $html, %html, $tt );
my ( %record_data,%res,$field,$fieldval,$fielddisp,$fieldoptionlist);

$PRO = 1;

$LOGGING               = 5;
$TASKS                 = 1;
$c{cache}{currenttype} = 'task';

my ( $projectID, $connection, %results, %recordToEdit );
my ($q) = new CGI;
my ($queryid) = $q->param('queryid') || "none";
$html{QUERYID}[0] = $queryid;
$html{BUGPATH}[0]=$c{url}{bug};
$html{TASKPATH}[0]=$c{url}{task};
$html{NOTE}[0]=$q->param('note');
$html{COMMENTSIZE}[0]=$q->cookie('pt_taskcommentsize') || '150';
$DEBUG               = $q->param('debug');
$userid              = &getUserId($q);
$projectid           = $q->param('projectid');
my($switch)= $q->param('switch');
my (%prefs) = &getMailPrefs($userid);
my ($mymode);
$templatefile=$q->param('templatefile');

if ( grep( /edit/, @{ $prefs{'prefs'} } ) )
{
	$mymode = "edit";
}
else
{
	$mymode = "view";
}
$type = $q->param('type') || "look";
if($q->param('rtype'))
{
	$type='new';
}

if ( $type eq "look" && ( $mymode eq "edit" ) && $type ne 'view' )
{
	$type = "edit";
}
elsif ( $type eq "look" && ( $mymode eq "view" ) )
{
	$type = "view";
}
elsif ( $type eq "look" )
{
	$type = "view";
}
&log("PRO: $timer - init vars") if $c{profile};
@groups = GetUserGroups($userid);
#TODO is this next call redundant to the above?
# Populate groups for template save groups
my (%grouplist) =
&doSql(
"select distinct grp.groupid,grp.groupname from groups grp,user_groups usr where grp.groupname not like \"%-owners\" and grp.groupid=usr.groupid and usr.userid=$userid order by grp.groupname");
&log("PRO: $timer - got groups for user") if $c{profile};
# Get required fields and populate
my (@requiredfields);
if ( $type eq 'new' || $type eq 'template')
{
	@requiredfields = split( ',', $c{tasktraq}{requiredforcreate} );
}
if ( $type eq 'edit' )
{
	@requiredfields = split( ',', $c{tasktraq}{requiredforedit} );
}
for ( my ($i) = 0 ; $i < scalar(@requiredfields) ; $i++ )
{

	# template values for javascript code
	$html{'REQUIREDFIELD'}[$i]      = $requiredfields[$i];
	$html{'REQUIREDFIELDLABEL'}[$i] = $c{tasktraq}{label}{ $requiredfields[$i] };

	#template values for required fields markup
	my ($reqfield) = "REQ" . uc( $requiredfields[$i] );
	$html{$reqfield}[0] = "<span class='required'>*</span>";
}
#Add group-userlist info
&log("PRO: $timer - Build grouplist") if $c{profile};
my(@grouplisting);
for(my($i)=0;$i<scalar(@{$grouplist{groupid}});$i++)
{
	my(%tmpuserlist)=&doSql("select userid from user_groups where groupid=$grouplist{groupid}[$i]");
	$grouplisting[$i]='"' . $grouplist{groupname}[$i] . '":"' . join(',',@{$tmpuserlist{userid}}) . '"';
}
$html{JS_GROUPLIST}[0]=join(',',@grouplisting);
&log("PRO: $timer - done building grouplist") if $c{profile};

# new record or record template
if ( $type eq "new" || $type eq "template" )
{
	print $q->header;
	my ( $template, $prid );
	$record_data{long_desc}=$c{tasktraq}{recordentrytext};
	# Get saved template CGI
	if ( $type eq "template" )
	{
		&log( "getting template", 5 );
		my ($category);
		if ( $q->param('category') )
		{
			$category = $q->param('category');
		}
		else
		{
			$category = $userid;
		}
		( $template, $prid ) = &getTemplate( $category, $q->param('templatename') );
		$projectID = $prid;
		$tt        = $template->param('projectid');
		foreach $field (keys(%{$c{tasktraq}{label}}))
		{
			$record_data{$field}=$template->param($field);
		}
		$record_data{projectid}=$projectID;
		&log( "got template $template for project $prid, $tt", 5 );
	}
	if ( $type eq 'new' )
	{
		$projectID = $q->param('projectid');
		$record_data{projectid}=$q->param('projectid');
	}
	foreach $field (keys(%{$c{tasktraq}{label}}))
	{
		if($q->param($field))
		{
			$record_data{$field}=$q->param($field);
		}
	}
	if($q->param('cc')=~/,/)
	{
		delete($record_data{'cc'});
		@{$record_data{'cc'}} = split(',',$q->param('cc'));
	}
	elsif($q->param('cc'))
	{
		delete($record_data{'cc'});
		@{$record_data{'cc'}}       = $q->param('cc');
	}
	if($q->param('keywords')=~/,/)
	{
		delete($record_data{'keywords'});
		@{$record_data{'keywords'} } = split(',',$q->param('keywords'));
	}
	elsif($q->param('keywords'))
	{
		delete($record_data{'keywords'});
		@{ $record_data{'keywords'} }       = $q->param('keywords');
	}
	
	%html = &mergeHashes( %html, %grouplist );
	$record_data{type}='task';
	$record_data{reporter}=$userid;
	# Only proceed if projectid has been given, otherwise, present an empty form
	if($record_data{projectid})
	{
		my(%comps)=&getComponents($record_data{projectid},'','task');
		%html=&mergeHashes(%html,%comps);
		
		# Step through the field list and process the displays for each field
		foreach $field (keys(%{$c{tasktraq}{label}}))
		{
			$fieldval=uc($field).'_VAL';
			$fielddisp=uc($field).'_DISP';
			$fieldoptionlist=uc($field).'_OPTIONLIST';
			if($record_data{$field})
			{
				$html{$fieldval}[0]=&getFieldValue($field,\%record_data,$userid);
				$html{$fielddisp}[0]=&getFieldDisplayValue($field,\%record_data,$userid);
			}
			$html{$fieldoptionlist}[0]=&getFieldOptionList($field,\%record_data,$userid);
		}
	}
	else
	{
		$html{SHORT_DESC_DISP}[0]="Choose a $c{tasktraq}{label}{projectid}..."; 
		$html{PROJECTID_OPTIONLIST}[0]="<option value=''>Choose a $c{tasktraq}{label}{projectid}...</option>\n" . &getFieldOptionList('projectid',\%record_data,$userid);
	}
	&log("PRO: $timer - finished processing field info") if $c{profile};

	$html{RTYPE}[0]='T';
	$html{PARENT}[0]=$q->param('parent');
	$html{CHILD}[0]=$q->param('child');
	$html{'USERID'}[0] = $userid;
	$html{'REFERER'}[0]  = $ENV{'HTTP_REFERER'};
	$html{'PISSROOT'}[0] = $c{'url'}{'base'};
	&populateHeaderFooter( \%html );
	%html = &populateLabels( \%html, 'task' );
	# Use alternate template file if param is passed
	unless ($templatefile)
	{
		$tfile=&getTemplateFile($c{dir}{tasktemplates},"enterTaskTemplate.tmpl",$userid );
	}
	else
	{
		$tfile=&getTemplateFile($c{dir}{tasktemplates},$templatefile,$userid );
	}
}
elsif ( $type eq "edit" || $type eq "view" )
{

	$recordid = $q->param('id');
	unless ($recordid)
	{
		&doError("No record ID given.");
	}
	unless ( &isValidRecord($recordid) )
	{
		&doError("Invalid Record Id");
	}
	if ( &isEditAuthorized( $userid, $recordid ) == 0 )
	{
		&doError("Viewing/Editing of record $recordid not allowed.");
	}
	&log( "Record $recordid accessed by $userid", 3 );
	%record_data = &db_GetRecord($recordid);
	if($record_data{type} ne 'task')
	{
		my($redirurl)=$c{url}{base} . "/redir.cgi?queryid=$queryid&id=$recordid";
		print $q->redirect($redirurl);
		exit;
	}
	else
	{
		print $q->header;
	}
	# Get attachments info and populate template values
	%res = &getAttachments($recordid);
	my ($ii) = 0;
	my($val);
	$res{'ID'}[0] = $recordid;
	foreach $val ( @{ $res{'attach_id'} } )
	{
		if($res{thedata}[$ii]=~/^\/{1,2}depot/)
		{
			$res{'downloadurl'}[$ii] = "http://web.coremobility.com/p4/p4.php?" . $res{thedata}[$ii];		
		}
		else
		{
			$res{'downloadurl'}[$ii] = "$c{'url'}{'base'}/attach.cgi?mode=download&id=$recordid&attid=$res{attach_id}[$ii]&queryid=$queryid";
		}
		$res{'RECORDID'}[$ii] = $recordid;
		$res{'PISSROOT'}[$ii] =$c{'url'}{'base'};
		my ($sub) = &getNameFromId( $res{'submitter_id'}[$ii] );
		$res{'submitter_id'}[$ii] = $sub;
		$ii++;
	}
	$res{COUNT}[0] = $ii;
	
	%html=&mergeHashes(%html,%res);
	if($switch)
	{
		$record_data{projectid}=$switch;
		$html{SWITCH}[0]=1;
	}
	my ( $prev, $next, $index, $numresults ) = &GetPrevNextResults( $recordid, $userid );
	$html{'INDEX'}[0]      = $index;
	$html{'NUMRESULTS'}[0] = $numresults;
	if($prev eq '/')
	{
		$prev='';
	}
	$html{'PREV'}[0]       = $prev;
	$html{'NEXT'}[0]       = $next;
	$html{DEPENDENCIES}[0]='plain';
	$html{ATTACHMENTS}[0]='plain';

	# Step through the field list and process the displays for each field
	foreach $field (keys(%{$c{tasktraq}{label}}))
	{
		$fieldval=uc($field).'_VAL';
		$fielddisp=uc($field).'_DISP';
		$fieldoptionlist=uc($field).'_OPTIONLIST';
		$html{$fieldval}[0]=&getFieldValue($field,\%record_data,$userid);
		$html{$fielddisp}[0]=&getFieldDisplayValue($field,\%record_data,$userid);
		$html{$fieldoptionlist}[0]=&getFieldOptionList($field,\%record_data,$userid);
	}
	# highlight for attachments
	my($attach_count)=&getNumAttachments($recordid);
	if($attach_count)
	{
		$html{ATTACHMENTS}[0]='redtab';
		$html{ATTACH_COUNT}[0]=$attach_count;
	}
	#Populate dependancy info
	my(%deps) = &getChildren($recordid,\@groups);
	my($z) =0;
	my($dep);
	foreach $dep (@{$deps{'dependson'}}) {
		$html{CHILDQUERYID}[$z] = $queryid;
		$html{'CHRTYPE'}[$z] = uc(substr(${$deps{'type'}}[$z],0,1));
		$html{'CHILDID'}[$z] = $dep;
		$html{'CHILDIDSTATUS'}[$z] = &getMenuDisplayValue($record_data{'projectid'}, "status", ${$deps{'status'}}[$z],${$deps{'type'}}[$z],''); 
		my($area)=${$deps{'type'}}[$z] . 'traq';
		if(${$deps{'status'}}[$z] >= $c{$area}{closethreshold})
		{
				$html{'CHILDIDSTRIKE'}[$z] = "<STRIKE>";
		}
		$z++;
	}
	if($html{'CHILDID'})
	{
		$html{DEPENDENCIES}[0]='redtab';
	}
	%deps={};
	$z=0;
	%deps = &getParents($recordid,\@groups);
	foreach $dep (@{$deps{'blocked'}}) {
		$html{PARENTQUERYID}[$z] = $queryid;
		$html{'PARTYPE'}[$z] = uc(substr(${$deps{'type'}}[$z],0,1));
		$html{'PARENTID'}[$z] = $dep;
		$html{'PARENTIDSTATUS'}[$z] = &getMenuDisplayValue($record_data{'projectid'}, "status", ${$deps{'status'}}[$z],${$deps{'type'}}[$z],'');
		my($area)=${$deps{'type'}}[$z] . 'traq';
		if(${$deps{'status'}}[$z] >= $c{$area}{closethreshold})
		{
				$html{'PARENTIDSTRIKE'}[$z] = "<STRIKE>";
		}
		$z++;
	}
	if($html{'PARENTID'})
	{
		$html{DEPENDENCIES}[0]='redtab';
	}
	&log("PRO: $timer - finished processing field info") if $c{profile};
	$html{RTYPE}[0]='T';
	$html{'REFERER'}[0]  = $ENV{'HTTP_REFERER'};
	$html{'PISSROOT'}[0] = $c{'url'}{'base'};
	&populateHeaderFooter( \%html );
	%html = &populateLabels( \%html, 'task' );
	if ( $type eq "edit" )
	{
		$tfile=&getTemplateFile($c{dir}{tasktemplates}, "editTaskTemplate.tmpl",$userid,\%record_data);
	}
	else
	{
		$tfile=&getTemplateFile($c{dir}{tasktemplates}, "viewTaskTemplate.tmpl",$userid,\%record_data);
	}
	&log("DEBUG: $templatefile   stuff");
}
unless ($templatefile) { $html{HEADER}[0]=&getHeader( $userid, "task" ); }
unless ($templatefile) { $html{FOOTER}[0]=&getFooter( $userid, "task" ); }
$html=&Process(\%html,$tfile);
&log("PRO: $timer - finished processing template") if $c{profile};
print $html;
&log("PRO: $timer - finished processing request") if $c{profile};
&stopLog();
exit;

##############################################################
