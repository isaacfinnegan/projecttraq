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
use MIME::Base64;
use TraqConfig;
use Traqfields;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
my ( $autonote, $connection, %results, %record, $note, %changes, $LOGGING, $userid, $DEBUG, $group, $forcemail, $field );
&startLog();
$LOGGING = 5;
my ($q) = new CGI;
my ($queryid) = $q->param('queryid') || "none";
$userid = &getUserId($q) || '0';
$DEBUG  = $q->param('debug');

### populate %record hash
foreach $field ( keys( %{ $c{bugtraq}{label} } ) )
{
	unless ( $field eq 'cc' || $field eq 'keywords' )
	{
		$record{$field} = &escapeQuotes( $q->param($field) );
	}
}

if($q->param('cc')=~/,/)
{
	@{$record{'cc'} } = split(',',$q->param('cc'));
}
else
{
	@{ $record{'cc'} }       = $q->param('cc');
}
@{ $record{'keywords'} } = $q->param('keywords');
$record{type} = 'bug';
$forcemail = $q->param('emailsubmit') || '';
$record{'submit'} = $q->param('submit');
$note             = &escapeQuotes( $q->param('note') );
$record{'note'}   = $note;
# add changes array to record hash
# is array of arrays  -  ( (table,field,oldval,newval) , (table,field,oldval,newval) )
@{$record{changes}}=();

####

# Exit if user does not have access
unless ( &isEditAuthorized( $userid, $record{'record_id'} ) )
{
	print "Edit of $record{'record_id'} not authorized\n" if $DEBUG;
	&doError( "EditAccessDenied", "", $q, "EditRecord" );
}
my ($key);
my (%olddataref) = &db_GetRecord( $record{'record_id'} );

# check to see that record has not changed
if ( &date2time( $olddataref{'delta_ts'} ) > &date2time( $q->param('delta_ts') ) )
{
	&doError(
		"This record has been edited since you accessed it.  Please click <a href='$c{url}{base}/redir.cgi?id=$record{record_id}&method=edit&queryid=$queryid'>B$record{record_id}</a> to return to record."	);
}

# Check for required fields
foreach $field ( split( ',', $c{bugtraq}{requiredforedit} ) )
{
	unless ( $record{$field} )
	{
		&doError( "$c{bugtraq}{label}{$field} must be set for this record", "", $q, "RecordUpdate" );
	}
}

# Check for resolution-status
if ( $record{status} eq $c{bugtraq}{resolved} && $olddataref{status} ne $record{status} && $record{resolution} eq "" )
{
	&doError("$c{bugtraq}{label}{resolution} is required.");
}

########################
# Dependency handling
if ( $q->param('child') )
{
	if ( $c{bugtraq}{requirecomment} && !$note )
	{
		if ( $c{bugtraq}{requirecomment} eq 'auto' )
		{
			$autonote = "Dependency added\n";
		}
		else
		{
			&doError( "PleaseCommentOnChange", "", $q, "AddChild" );
		}
	}
	my ($children) = $q->param('child');
	$children =~ s/[BbtT]//g;
	$children =~ s/\s/,/g;
	my (@children) = split( /,/, $children );
	my ($child);
	foreach $child (@children)
	{
		if ($child)
		{
			unless ( &isEditAuthorized( $userid, $child ) )
			{
				&doError( "AccessDenied", "", $q, "AddChild" );
			}
			&addChild( $record{'record_id'}, $child );
			@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_dependencies', 'dependson', '', $child);
		}
	}
}
if ( $q->param('parent') )
{
	if ( $c{bugtraq}{requirecomment} && !$note )
	{
		if ( $c{bugtraq}{requirecomment} eq 'auto' )
		{
			$autonote = "Dependency added\n";
		}
		else
		{
			&doError( "PleaseCommentOnChange", "", $q, "AddParent" );
		}
	}
	my ($parents) = $q->param('parent');
	$parents =~ s/[BbtT]//g;
	$parents =~ s/\s/,/g;
	my (@parents) = split( /,/, $parents );
	my ($parent);
	foreach $parent (@parents)
	{
		if($parent)
		{
			unless ( &isEditAuthorized( $userid, $parent ) )
			{
				&doError( "AccessDenied", "", $q, "AddParent" );
			}
			&addChild( $parent, $record{'record_id'} );
			@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_dependencies', 'blocked', '', $parent);
		}
	}
}
if ( $q->param('removechild') )
{
	if ( $c{bugtraq}{requirecomment} && !$note )
	{
		if ( $c{bugtraq}{requirecomment} eq 'auto' )
		{
			$autonote = "Dependency removed\n";
		}
		else
		{
			&doError( "PleaseCommentOnChange", "", $q, "RemoveChild" );
		}
	}
	my (@delchildren) = $q->param('removechild');
	my ($delchild);
	foreach $delchild (@delchildren)
	{
		unless ( &isEditAuthorized( $userid, $delchild ) )
		{
			&doError( "AccessDenied", "", $q, "RemoveChild" );
		}
		&removeChild( $record{'record_id'}, $delchild );
		@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_dependencies', 'dependson', $delchild, '');
	}
}
if ( $q->param('removeparent') )
{
	if ( $c{bugtraq}{requirecomment} && !$note )
	{
		if ( $c{bugtraq}{requirecomment} eq 'auto' )
		{
			$autonote = "Dependency removed\n";
		}
		else
		{
			&doError( "PleaseCommentOnChange", "", $q, "RemoveParent" );
		}
	}
	my (@delparents) =$q->param('removeparent');
	my ($delparent);
	foreach $delparent (@delparents)
	{
		unless ( &isEditAuthorized( $userid, $delparent ) )
		{
			&doError( "AccessDenied", "", $q, "RemoveParent" );
		}
		&removeChild( $delparent, $record{'record_id'} );
		@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_dependencies', 'blocked', $delparent, '');
	}
}

# end dependancy handling
#####################################
my ($ts) = &makeMysqlTimestamp( time() );

my ($sql) = "update traq_records set delta_ts='$ts'";

# Step through fields to create update sql

foreach $field ( keys( %{ $c{bugtraq}{label} } ) )
{

	my ($newfieldvalue) = &saveField( $field, \%olddataref, \%record, $userid );
	unless ( $newfieldvalue eq &escapeQuotes( $olddataref{$field} )
		|| grep( /^$field$/, split( ',', $c{general}{externalfields} ) )
		|| grep( /^$field$/, split( ',', $c{general}{virtualfields} ) ) )
	{
		if ( &canEditField( $userid, $field ) )
		{
			$sql .= ", $field=\"$newfieldvalue\"";

			$changes{$field} = $newfieldvalue;
			@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_records', $field, $olddataref{$field}, $newfieldvalue);
		}
	}
}
$sql .= " where record_id=$record{record_id}";
&doSql($sql);

# Check for attachment and add
if ( $q->param('FILE')   || $q->param('description')=~/\/{1,2}depot/ )
{
	&process_file_upload( $q, $record{record_id}, $userid );
}

# Check for attachment delete and process
if ( $q->param('delete_attach') )
{
	my (@rm_attachlist) = $q->param('delete_attach');
	my ($attid);
	foreach $attid (@rm_attachlist)
	{

		$sql = "select filename from traq_attachments where attach_id=\"$attid\"";
		my(%fname)=&doSql($sql);
		$sql = "delete from traq_attachments where attach_id=\"$attid\"";
		&doSql($sql);
		$sql = "insert into traq_activity set 
				   record_id=$record{record_id},
				   who=$userid,date=$ts,
				   fieldname=\"delete\",
				   oldvalue=\"$fname{filename}[0]\",
				   newvalue=\"filename: \",
				   tablename=\"traq_attachments\"";
		&doSql($sql);
	}

}

# Check for comment and populate note with comment if c{bugtraq}{requirecomment} eq 'auto'
my (@changedfields) = keys(%changes);
if (   $c{bugtraq}{requirecomment} eq 'auto'
	&& !$note
	&& scalar(@changedfields) )
{
	for ( my ($i) = 0 ; $i < scalar(@changedfields) ; $i++ )
	{
		$changedfields[$i] = $c{bugtraq}{label}{ $changedfields[$i] };
	}
	$note = $autonote . "Changing " . join( ',', @changedfields ) . "\n";
}

# Comment
if ($note)
{
	if ( &canEditField( $userid, "addnote" ) )
	{
		&addRecordNote( $record{'record_id'}, $note, $userid );
		$changes{'note'}++;
	}
}
foreach $key ( keys(%changes) )
{
	unless (
		   grep( /^$key$/, split( ',', $c{general}{externalfields} ) )
		|| grep( /^$key$/, split( ',', $c{general}{virtualfields} ) )

		# 		||
		# 		!&bogusChangeCheck($olddataref{$key},$changes{$key})
	  )
	{
		$sql = "insert into traq_activity set 
				   record_id=$record{record_id},
				   who=$userid,date='$ts',
				   fieldname=\"$key\",
				   oldvalue=\"$olddataref{$key}\",
				   newvalue=\"$changes{$key}\",
				   tablename=\"traq_records\"";
		&doSql($sql);
	}
}

my (%emailsetting);

unless ( $q->param('suppress') )
{
	my ($area) = $olddataref{type} . "traq";

	# Send email notification
	%{ $emailsetting{record} } = %record;
	$emailsetting{change_type}    = 'edited';
	$emailsetting{record}{note}   = $note;
	$emailsetting{originalrecord} = \%olddataref;
	$emailsetting{change_userid}  = $userid;
	%{ $emailsetting{changes} } = %changes;
	$emailsetting{force} = $forcemail;
	$emailsetting{record}{recordtype} = 'bug';
	&emailConfirmation( \%emailsetting );
}
&outputConfirmation( $userid, \%record, $q );

&stopLog();
exit 0;

##############################################################
sub addChild
{
	my ( $parent, $child ) = @_;
	&log("adding relationship: parent:$parent, chid:$child") if $c{debug};
	$parent =~ s/[BbtT](\d+)/$1/;
	$child  =~ s/[BbtT](\d+)/$1/;
	if ( ( $record{record_id} eq $q->param('child') ) || ( $record{record_id} eq $q->param('parent') ) || ( $child eq $parent ) )
	{
		&doError("You cannot make a record a dependency of itself.");
	}
	else
	{
		my ($sql) = "insert into traq_dependencies set blocked=$parent,dependson=$child";
		&doSql($sql);
	}
}
##############################################################
sub removeChild
{
	my ( $parent, $child ) = @_;
	my ($sql) = "delete from traq_dependencies where blocked=$parent and dependson=$child";
	&doSql($sql);
}
##############################################################
sub outputConfirmation
{
	my ( $userid, $recordref, $q ) = @_;
	my (%record)  = %$recordref;
	my ($queryid) = $q->param('queryid') || "none";
	my (%prefs)   = &getMailPrefs($userid);
	my ( $prev, $next, $index, $numresults ) = &GetPrevNextResults( $record{'record_id'}, $userid );
	my (@comp) = grep( /comp_/, @{ $prefs{'prefs'} } );
	my ($pref) = $comp[0];
	if ( $pref eq "comp_confirm" )
	{
		my ($id) = uc( substr( &getRecordType( $record{'record_id'} ), 0, 1 ) ) . $record{'record_id'};
		print $q->redirect("../actioncomplete.cgi?action=Edit&id=$id&result=Success&type=bug&queryid=$queryid");
	}
	elsif ( $pref eq "comp_gotonext" )
	{
		if ($next)
		{
			print $q->redirect("./enterBugForm.cgi?type=edit&id=$next&queryid=$queryid");
		}
		else
		{
			print $q->redirect("./enterBugForm.cgi?type=edit&id=$record{'record_id'}&queryid=$queryid");
		}

	}
	elsif ( $pref eq "comp_redisplay" )
	{
		print $q->redirect("./enterBugForm.cgi?type=edit&id=$record{'record_id'}&queryid=$queryid");
	}
	elsif ( $pref eq "comp_return" )
	{
		if($queryid ne 'none')
		{
			print $q->redirect("../do_query.cgi?queryid=$queryid");
		}
		else
		{
			print $q->redirect("../do_query.cgi?record_id=$record{record_id}&return_bugs=1&return_tasks=1");
		}
	}
	else
	{
		my ($id) = uc( substr( &getRecordType( $record{'record_id'} ), 0, 1 ) ) . $record{'record_id'};
		print $q->redirect("../actioncomplete.cgi?action=Edit&id=$id&result=Success&type=bug&queryid=$queryid");
	}
}

