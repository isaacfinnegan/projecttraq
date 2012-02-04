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
my ($TASKS) = 1;

&startLog();
my ($LOGGING) = 5;

my ( %olddataref,$userid, $rightnow, $recordType, $DEBUG, @groups, $compgroup, $cc, $g, $field, $group, $word, @compgroups, %record, $keywords, $connection, %results, $newRecordId );

my ($q) = new CGI;
$DEBUG  = $q->param('debug');
$TASKS  = 1;
$userid = &getUserId($q);
$recordType = "task";
$rightnow   = &makeMysqlTimestamp( time() );

foreach $field ( keys( %{ $c{tasktraq}{label} } ) )
{
	unless($field eq 'cc' || $field eq 'keywords')
	{
		$record{$field}=&escapeQuotes($q->param($field));
	}
}
$record{note}='New Record';
$record{type}='task';
$olddataref{type}='task';
if($q->param('cc')=~/,/)
{
	@{$record{'cc'} } = split(',',$q->param('cc'));
}
else
{
	@{ $record{'cc'} }       = $q->param('cc');
}
@{ $record{'keywords'} } = $q->param('keywords');
$record{'submit'} = $q->param('submit');

if ( $q->param('maketemplate') )
{
	&makeTemplate( $userid, $record{'projectid'}, $q );
}
else
{

	# Check for required fields
	no strict 'refs';
	my ($field);
	foreach $field ( split( ',', $c{tasktraq}{requiredforcreate} ) )
	{
		unless ( $record{$field} )
		{
			&log( "ERR: Required field $field not present", 5 );
			&doError( "$c{tasktraq}{label}{$field} must be set for this record", "", $q, "CreateTask" );
		}
	}
}
my (@compgroups) = &getComponentGroups( $record{'componentid'} );
unless( &isCreateAuthorized( $userid, \@compgroups ) )
{
	&log( "creation authorization failed user:$userid, comp:$record{'componentid'}", 2 );
	print "Creation not authorized\n" if $DEBUG;
}
### Creating record
my ($sql) = "insert into traq_records set ";
$sql .= "creation_ts=now() ";
foreach $field ( keys( %{ $c{tasktraq}{label} } ) )
{
	unless( 
			grep(/^$field$/ , split(',',$c{general}{externalfields}))
			||
			grep(/^$field$/ , split(',',$c{general}{virtualfields}))
			)
	{
		$record{$field}=&saveField($field,\%olddataref,\%record,$userid);
		$sql .= ",$field=\"$record{$field}\"\n";
	}
}

print "\n<br><b>$sql<br>\n" if $DEBUG;
$newRecordId = &doSql( $sql, '', '1' );
$record{record_id}=$newRecordId;

# If posted with attachment add attachment for record
# Check for attachment and add
if($q->param('FILE') || $q->param('description')=~/\/{1,2}depot/ )
{
	&process_file_upload($q,$newRecordId,$userid);
}

my($sql) = "insert into traq_activity set 
		   record_id=$record{record_id},
		   who=$userid,date=now(),
		   fieldname=\"record_id\",
		   oldvalue=\"New Record\",
		   newvalue=\"$newRecordId\",
		   tablename=\"traq_records\"";
&doSql($sql);

my ($group);
# Create security ACL's for new record
foreach $group (@compgroups)
{
	my ($sql) = "insert into acl_traq_records set groupid=$group,record_id=$newRecordId";
	print "acl: ", $sql, "<BR>" if $DEBUG;
	my ($ret) = &doSql($sql);
}

&saveField('keywords',\%olddataref,\%record,$userid);
&saveField('cc',\%olddataref,\%record,$userid);
my ($sql) = "insert into traq_longdescs set record_id=$newRecordId,who=$userid,date=now(),thetext=\"$record{long_desc}\"";
my ($ret) = &doSql($sql);

# If record was created as a child of an existing record, create dependacy.
if ( $q->param('parent') )
{
	my ($parents) = $q->param('parent');
	$parents =~ s/[BbtT]//g;
	$parents =~ s/\s/,/g;
	my (@parents) = split( /,/, $parents );
	my ($parent);
	foreach $parent (@parents)
	{

		unless ( &isEditAuthorized( $userid, $parent ) )
		{
			&doError( "AccessDenied", "", $q, "AddParent" );
		}
		&addChild( $parent, $record{'record_id'} );
	}
}
# If record was created as a parent of an existing record, create dependacy.
if ( $q->param('child') )
{
	my ($children) = $q->param('child');
	$children =~ s/[BbtT]//g;
	$children =~ s/\s/,/g;
	my (@children) = split( /,/, $children );
	my ($child);
	foreach $child (@children)
	{

		unless ( &isEditAuthorized( $userid, $child ) )
		{
			&doError( "AccessDenied", "", $q, "AddChild" );
		}
		&addChild( $record{'record_id'}, $child );
	}
}

# Prepping hash for email notification
my (%emailsetting);
%{ $emailsetting{record} } = %record;
$emailsetting{record}{recordtype}    = $recordType;
$emailsetting{record}{note}          = $record{'long_desc'};
$emailsetting{record}{record_id}     = $newRecordId;
$emailsetting{record}{change_type}   = 'created';
$emailsetting{record}{change_userid} = $userid;
$emailsetting{record}{reporter}      = $userid;
$emailsetting{change_userid}         = $userid;
$emailsetting{change_type}           = 'created';
%{ $emailsetting{changes} } = (
	note       => '1',
	status     => '1',
	resolution => '1',
	keywords   => '1',
	Other      => '1',
	cc         => '1',
);
&emailConfirmation( \%emailsetting );
&outputConfirmation( $newRecordId, $q );
&stopLog();
exit 0;

##############################################################
sub makeTemplate()
{
	my ( $userid, $project_id, $cgi ) = @_;
	if ( $cgi->param('maketemplate') )
	{
		unless ( $cgi->param('templatename') )
		{
			&doError( "NoTemplatename", " ", $cgi, "CreateTemplate" );
		}
		$project_id = $cgi->param('projectid');
		my ($templatename) = $cgi->param('templatename');
		&saveTemplate( $userid, $cgi, $templatename, $project_id, "task" );
		&outputConfirmation( $newRecordId, $cgi );
	}

}
##############################################################
sub outputConfirmation()
{
	my ( $newRecordId, $q ) = @_;
	my ($id);
	my ($popup) = $q->param('popup');
	unless ( $q->param('maketemplate') )
	{
		$id = uc( substr( &getRecordType($newRecordId), 0, 1 ) ) . $newRecordId;
	}
	if ( $q->param('attach') =~ /\w/ )
	{
		print $q->redirect("../attach.cgi?mode=view&id=$newRecordId");
	}
	elsif ( $q->param('maketemplate') )
	{
		print $q->redirect("../actioncomplete.cgi?action=MakeTemplate&type=task");
	}
	else
	{
		print $q->redirect("../actioncomplete.cgi?popup=$popup&id=$id&action=NewTask&result=Success&type=task");
	}
	exit 0;
}
##############################################################
sub populateAcls
{
	my ( $recid, $compgroups ) = @_;
	my (@compgroups) = @$compgroups;
	my ($group);
	foreach $group (@compgroups)
	{
		my ($sql) = "insert into acl_traq_records set groupid=$group,record_id=$recid";
		print "acl: ", $sql, "<BR>" if $DEBUG;
		my ($ret) = &doSql($sql);
	}
}
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
