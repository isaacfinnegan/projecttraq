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
use MIME::Base64;
use TraqConfig;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
&startLog();
my ($LOGGING) = 5;
my ($DEBUG)   = 1;

my ( %res, $projectID, $connection, $q, $userid, $fname, $val );
$q      = new CGI;
$DEBUG  = $q->param('debug');
#$userid = &getUserId($q);
$userid=0;
my ($id) = $q->param('id');
#unless ( &isEditAuthorized( $userid, $id ) )
#{
#	&doError("Cannot access this record");
#}
my ($queryid) = $q->param('queryid');
$res{QUERYID}[0] = $queryid;
my ($mode) = $q->param('mode');
my ($type) = &getRecordType($id);

$res{'ID'}[0] = $id;
if ( $mode eq "view" )
{
	%res = &getAttachments($id);
	my ($ii) = 0;
	$res{'ID'}[0] = $id;
	foreach $val ( @{ $res{'attach_id'} } )
	{
		$res{'RECORDID'}[$ii] = $id;
		my ($sub) = &getNameFromId( $res{'submitter_id'}[$ii] );
		$res{'submitter_id'}[$ii] = $sub;
		$ii++;
	}

	$res{COUNT}[0] = $ii;
	$res{'RTYPE'}[0]    = uc( substr( &getRecordType($id), 0, 1 ) );
	$res{'PISSROOT'}[0] = $c{'url'}{'base'};

	&populateHeaderFooter( \%res );
	print $q->header;
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'attach.tmpl');
	my ($html) = Process( \%res, $templatefile,$userid);

	# 	print &getHeader($userid, "task");
	print $html;

	#	print &getFooter($userid, "task");
}
elsif ( $mode eq "upload" )
{
	my ($note) = $q->param('note');

	#  	unless($note)
	#  	{
	#  		print $q->header;
	#  		print "<br><center>A comment is required.<br>\n";
	#  		print "<a href=\"attach.cgi?mode=view&id=$id\">Retry</a></center>";
	#  		exit;
	#  	}
	$note = "<Attachment added>\n$note";
	&addRecordNote( $id, $note, $userid );
	my ($file)        = $q->param('FILE');
	my ($description) = $q->param('description') || "None";
	my ($mime)        = $q->param('type');
	$file =~ /.+[\/\\](.+)$/;
	if ($1)
	{
		$fname = $1;
	}
	else
	{
		$fname = 'null';
	}
	undef $/;
	my ($contents) = <$file>;
	my ($enc)      = encode_base64($contents);
	my ($now)      = &makeMysqlTimestamp( time() );
	my ($sql)      = "insert into traq_attachments set record_id=\"$id\",creation_ts=\"$now\",";
	$sql .= "description=\"$description\",filename=\"$fname\",thedata=\'$enc\',submitter_id=\"$userid\"";
	$sql .= ",mimetype=\"$mime\"";
	&doSql($sql);
	&makeActivityEntry( $userid, $id, "traq_attachments", "create", " ", $fname );
	#############
	# NEED TO ADD EMAIL NOTIFICATION FOR THIS
	#############
	print $q->redirect("attach.cgi?mode=view&id=$id");

}
elsif ( $mode eq "download" )
{
	#unless ( &isEditAuthorized( $userid, $id ) )
	#{
	#	&doError("Cannot access this record");
	#}
	my ($attid) = $q->param('attid');
	my ($sql)   = "select mimetype,thedata,filename from traq_attachments where record_id=\"$id\"";
	$sql .= " and attach_id=\"$attid\"";
	my (%res) = &doSql($sql);
	$res{filename}[0]=~s/\s/_/g;
# 	print $q->header( -type => "$res{'mimetype'}[0]" );
	print "Content-Type: $res{'mimetype'}[0]\n";
	print "Content-Disposition: attachment\; filename=$res{filename}[0]\n";
	print "\n";
	print decode_base64( $res{'thedata'}[0] );
	exit;
}
elsif ( $mode eq "delete" )
{
	unless ( &isEditAuthorized( $userid, $id ) )
	{
		&doError("Cannot access this record");
	}
	my ($attid) = $q->param('attid');
	my ($sql)   = "delete from traq_attachments where record_id=\"$id\" and ";
	$sql .= "attach_id=\"$attid\"";
	my ($fname) = &getAttachmentName( $id, $attid );
	&doSql($sql);
	&makeActivityEntry( $userid, $id, "traq_attachments", "delete", $fname );
	print $q->redirect("attach.cgi?mode=view&id=$id");
}

############################################################################

sub getAttachmentName()
{
	my ( $recid, $attid ) = @_;
	my ($sql)  = "select filename from traq_attachments where record_id=\"$recid\" and attach_id=\"$attid\"";
	my (%r)    = &doSql($sql);
	my ($name) = ${ $r{'filename'} }[0];
	return $name;
}
############################################################################

