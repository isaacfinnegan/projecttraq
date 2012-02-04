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

 &startLog();
 my($LOGGING) = 5;
 my($DEBUG)=1;

 my($projectID, $connection, $q, $resultstring, $idstring,$userid);
 #$connection = &dbConnect();
 $q = new CGI;
	$DEBUG = $q->param('debug');
 $userid = &getUserId($q);
 
 my(@ids) = $q->param('ids') || split(',',$q->param('idlist'));
 my($action) = $q->param('action');
 my($note) = $q->param('note');
 my($queryid)=$q->param('queryid');
 print $q->header if $DEBUG;
 my($id);
#####################################################################
if($action eq "Close") {
 	foreach $id (@ids) {
 		if(&accessAuthorized($id, $userid)) {
		        $idstring .= uc(substr(&getRecordType($id),0,1)) . "$id,";
 			&closeRecord($id,'',$userid);
			if($note) {
				&addNote($id, $note,$userid);
			}
 		}
 		else {
 			$resultstring .= "accessunauth,";
 			$idstring .= "$id,";
 		}
 	}
}
elsif($action eq "AddNote") {
 	foreach $id (@ids) {
 		if(&accessAuthorized($id, $userid)) {
 			&addNote($id, $note,$userid);
 		}
 		else {
 			$resultstring .= "accessunauth,";
 			$idstring .= "$id,";
 		}
 	}
}
elsif($action eq "Reopen") {
	foreach $id (@ids) {
		$idstring .= "$id,";
 		if(&accessAuthorized($id, $userid)) {
 			my(%rec) = &getRecord($id, "raw");
			my($type) = $rec{'type'}[0];
			$type .= "traq";
			unless($rec{'status'}[0] < $c{$type}{closethreshold} ) { #already open?
 				&updateRecord($id, "traq_records", "status", $rec{'status'}[0], 3, $userid);
 				&updateRecord($id, "traq_records", "resolution", $rec{'resolution'}[0], "", $userid);
 				my($now) = &makeMysqlTimestamp(time());
				&updateRecord($id, "traq_records", "delta_ts", $rec{'delta_ts'}[0], $now, $userid);
				$resultstring .= "UpdateSuccess,";
				if($note) {
					&addNote($id, $note,$userid);
				}
			}
 		}
 	}
 	
}
elsif($action eq "ViewAll") {
	my($records,%res,$html);
	print $q->header;
	foreach $id (@ids) {
		if(&accessAuthorized($id,$userid)) {
			my(%rec) = &getRecord($id);
			%rec=populateLabels(\%rec,$rec{TYPE}[0]);
			my($area)=$rec{TYPE}[0] . 'traq';
			my($templatefile)='view' . $rec{TYPE}[0] . 'Template.tmpl';
			$templatefile=&getTemplateFile($c{dir}{$area.'templates'}, $templatefile,$userid);
			$html .= &Process(\%rec, $templatefile);
			$html .= "\n<hr>\n";
		}
	}

	print &getHeader($userid, 'traq');
	print $html;
	print &getFooter($userid, 'traq');
	exit;
}
elsif($action eq "Edit") {
	my($ids) = join(",", @ids);
	&saveResults($userid, $ids);
	my($firstId) = $ids[0];
	print $q->redirect("./redir.cgi?type=edit&id=$firstId&queryid=$queryid");
	&stopLog();
	exit;
}
elsif($action eq "Change") {
	unless($note)
	{
		print $q->header;
		&doError("You must enter a comment to make bulk changes");
		exit;
	}
	my($field,$rec,%record,%changes,$key,%olddataref);
	foreach $field (keys(%{$c{general}{label}}))
	{
		unless($field eq 'cc' || $field eq 'keywords')
		{
			if($q->param($field))
			{
				$record{$field}=&escapeQuotes($q->param($field));
			}
		}
	}
	@{ $record{'cc'} } = $q->param('cc');
	@{ $record{'keywords'} } = $q->param('keywords');
    my(@editedids);
	# Step through records and process changes
	foreach $rec (@ids) {
		if(&isEditAuthorized( $userid, $rec )) 
		{
			$record{record_id}=$rec;
			my(%olddataref)=&db_GetRecord($rec);
			my($area)=$olddataref{type} . 'traq';
            #if($record{status})
    		#{  
    		#  $record{resolution}=$olddataref{resolution};
			#}
			#else
			#{
    	#	  $record{resolution}='';
    	#	  $record{status}='';
			#}
			my($sql)="update traq_records set delta_ts=now()";
			# Step through fields to create update sql
			foreach $field (keys(%{$c{$area}{label}}))
			{
                unless( 
                        !$record{$field}
                        ||
                        grep(/^$field$/ , split(',',$c{general}{externalfields}))
                        ||
                        grep(/^$field$/ , split(',',$c{general}{virtualfields}))
                        )
                {
					# Check for record type=change type 
					# (this only applies to some of the bulk editor change options)
					my(@tmp)=split('__',$record{$field});
					@{$record{changes}}=();
					if(scalar(@tmp)>1 && ($tmp[0] eq 'bug' || $tmp[0] eq 'task' || $tmp[0] eq 'traq')) 
					{
						if(
							( $tmp[0] ne $olddataref{type} && $tmp[0] ne 'traq' ) 
							|| ($tmp[1] ne '0' && $tmp[1] ne $olddataref{projectid})
							)
						{
							next;
						}
						else
						{
							$record{$field}=$tmp[2];
						}
					}
					if(&canEditField($userid,$field))
					{
    					my($newfieldvalue)=&saveField($field,\%olddataref,\%record,$userid);
						$sql.=", $field=\"$newfieldvalue\"";
						$changes{$field}=$newfieldvalue;
						@{$record{changes}[$#{$record{changes}}+1]}= ( 'traq_records', $field, $olddataref{$field}, $newfieldvalue);
					}
				}
			}
			$sql.=" where record_id=$rec";
			&log("SQL: $sql") if $c{debug}{sql};
			&doSql($sql);
			&addRecordNote( $rec, $note, $userid );
            push(@editedids,$rec);
			my ($ts) = &makeMysqlTimestamp( time() );
			&updateRecord( $rec, "traq_records", "delta_ts", $olddataref{'delta_ts'}, $ts, $userid );
			delete ($changes{record_id});
			foreach $key (keys(%changes))
			{
                unless(
                    grep(/^$key$/ , split(',',$c{general}{externalfields}))
                    ||
                    grep(/^$key$/ , split(',',$c{general}{virtualfields}))
                    )
                {

					$sql = "insert into traq_activity set 
							   record_id=$rec,
							   who=$userid,date=now(),
							   fieldname=\"$key\",
							   oldvalue=\"$olddataref{$key}\",
							   newvalue=\"$changes{$key}\",
							   tablename=\"traq_records\"";
					&doSql($sql);
				}
			}
			# Do standard email notifications unless user suppressed
			unless($q->param('suppress'))
			{
				my(%emailrecord);
				# Construct record hash for notification
				my($area)=$olddataref{type} . "traq";
				foreach $key (keys %{$c{$area}{label}})
				{
					unless($changes{$key})
					{
						$emailrecord{$key}=$olddataref{$key};
					}
					else
					{
						$emailrecord{$key}=$changes{$key};
					}
				}
				@{$emailrecord{changes}}=@{$record{changes}};
				# Send email notification
				my (%emailsetting);
				%{ $emailsetting{record} } = %emailrecord;
				$emailsetting{change_type}    = 'edited';
				$emailsetting{record}{note}   = $note;
				$emailsetting{originalrecord} = \%olddataref;
				$emailsetting{change_userid}  = $userid;
				%{ $emailsetting{changes} } = %changes;
				$emailsetting{record}{recordtype} = $olddataref{type};
				&emailConfirmation( \%emailsetting );
			}
		}
	}
	$resultstring='Bulk Change Successful';
}
elsif($action eq "report")
{
	my(%html);
	$html{NOTE}[0]=$note;
	$html{RECORDS}[0]=join(',',@ids);
	$html{VIEWSTATE}[0]=$q->param('viewstate');
	$html{'USEROPTIONLIST'}[0]=&makeUserOptionList();

	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"queryreport.tmpl",$userid);
	my($html) = &Process(\%html, $templatefile);

	print $q->header;
	print &getHeader($userid, "traq");
	print $html;
	print getFooter($userid);
	exit;
}
elsif($action eq 'makereport')
{
	my($ids)=$q->param('records');
	my($viewstate)=$q->param('viewstate');
	print $q->redirect("do_query.cgi?record_id=$ids&$viewstate");

}

my(%prefs) = &getMailPrefs($userid);
my(@comp) = grep(/comp_/, @{$prefs{'prefs'}});
my($pref) = $comp[0];
if($pref eq "comp_confirm") {
	print $q->redirect("actioncomplete.cgi?action=quick&result=$resultstring&id=$idstring&queryid=$queryid");
}
elsif($pref eq "comp_return") {
	print $q->redirect("do_query.cgi?queryid=$queryid");
}
else {
	print $q->redirect("actioncomplete.cgi?action=quick&result=$resultstring&id=$idstring");
}

&stopLog();
#--------------------------------------------------------------------
#####################################################################
sub assignRecord() {
	my($recordid, $who) = @_;
 	my(%rec) = &getRecord($recordid, "raw");
	&updateRecord($recordid, "traq_records", "assigned_to", $rec{'assigned_to'}[0], $who, $userid);
	$resultstring .= "assigned,";
}
	
sub changeRecordStatus() {
	my($recordid, $status) = @_;
	my($error)=&closeRecord($recordid, $status);
	return $error;
}
sub closeRecord() {
 	my($id, $status,$userid)= @_;
 	my(%rec) = &getRecord($id, "raw");
	my($type) = $rec{'type'}[0];
	$type .= "traq";
	my($oldStatus) = $rec{'status'}[0];
 	my($blocked);
 	my(@status)=split '', $status;
 	my(@type)=split '',$type;
 	unless($status[0] eq $type[0])
 	{
 		$blocked++;
 		$resultstring .= "Invalid Status";
 	} 	
	shift(@status);
	$status=join '', @status;
	my(%res) = &getChildren($id);
	my(@children);
	if(%res)
	{
		@children = @{$res{'record_id'}};
	#$idstring .= uc(substr(&getRecordType($id),0,1)) . "$id,";
		if($status > 3) {
			for(my($i)=0; $i< scalar(@{$res{'record_id'}}); $i++)  {
				if($res{'status'}[$i] < $c{$type}{closethreshold}) {			
					$blocked++;
					$resultstring .= "Blocked-$res{'record_id'}[$i]_";
				}
			}
		}
	}
	unless($blocked) {
		&updateRecord($id, "traq_records", "status", $rec{'status'}[0], $status, $userid);
		my($now) = &makeMysqlTimestamp(time());
		&updateRecord($id, "traq_records", "delta_ts", $rec{'delta_ts'}[0], $now, $userid);
		$resultstring .= "UpdateSuccess,";
	}
	if($blocked) { $resultstring .= ","; }	
	return $blocked;
}
#####################################################################
sub addNote {
	my($id, $note,$userid) = @_;
	&addRecordNote($id, $note,$userid);
	$resultstring .= "AddNote,";
	$idstring .= uc(substr(&getRecordType($id),0,1)) . "$id,";
}
