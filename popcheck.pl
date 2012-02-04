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
use Email::MIME;
use Net::POP3;
use Net::IMAP::Simple;
use TraqConfig;
use dbFunctions;
use supportingFunctions;
use Getopt::Std;
use MIME::Lite;
 
use strict;
use vars qw(%c);
local(*c) = \%TraqConfig::c;
my $DEBUG=1;

#######################################################################333
my %opt;
getopts('AHh:u:p:P:C:S:U:D:T:R:L:i:W:K:', \%opt);
usage() if $opt{H};


#populate default values 
my $pophost = $opt{h} || 'deuce.smokeyroom.com';
my $poplogin = $opt{u} || 'pt';
my $poppasswd = $opt{p} || 'm0bilize';
my $project = $opt{P} || '21';
my $component = $opt{C} || '156';
my $severity = $opt{s} || '3';
my $priority = $opt{U} || '2';
my $type = $opt{T} || 'task';
my $default_desc = $opt{D};
my $whiteboard= $opt{W} || '';
my @keywords= split(',',$opt{K});

#my $pop3 = Net::POP3->new("$pophost") ;
#$pop3->login("$poplogin", "$poppasswd") ;
#my $msgs = $pop3->list;
my $msg;
my $server = new Net::IMAP::Simple("$pophost");
$server->login("$poplogin", "$poppasswd");
my $msgs = $server->select("INBOX");
print "logged in $pophost $poplogin $poppasswd\n" if $DEBUG;
my $msg_body;

#######################################################################333
#step through each message in box
#foreach $msg (keys %$msgs) {
foreach $msg (1..$msgs) {
	print "Looping messages\n" if $DEBUG;
	my $msgcont = $server->get($msg);
	my $cont = join('', @$msgcont);
	my $mime = Email::MIME->new($cont);
	print "To: ", $mime->header('To'), "\n" if $DEBUG;
	print "From: ", $mime->header('From'), "\n" if $DEBUG;
	print "Subject: ", $mime->header('Subject'), "\n" if $DEBUG;
	#print "Content Type: ", $mime->content_type, "\n" if $DEBUG;
	#if it's a reply don't do anything yet
	if(&isReply($mime)) {
		print "Is reply\n";
	}
	elsif(&isAckOrRecovery($mime)) {
		print "Is ack or recovery\n";
		$server->delete($msg);	
	}
	# if it's not, create a new record
	else {
		print "New task\n";
		my $newtaskid = &createTask($mime);
		&sendEmailAck($newtaskid, $mime) unless $opt{A};
		$server->delete($msg);	
	}
}
$server->quit;
exit;

#######################################################################333
sub sendEmailAck {
	my ($id, $mime) = @_;
	my $from = $mime->header('From');
	my $text = "Your projecttraq task: $id has been created" .
	  "\nSummary: " .  $mime->header('Subject') .
	  "\nDescription: $msg_body" . 
		"\n\nhttp://pt.coremobility.com/projecttraq/redir.cgi?id=$id";
	my $subject = "New PT task created";
	my $source = 'noreply@pt.coremobility.com';
	my $to = $from;
	$to =~ /<*(\w+\@\w+\.\w+)>*/;
	$to = $1;
	my $msg = MIME::Lite->new (
		From => $source,
		To => $to,
		Subject => $subject,
		Type =>'multipart/mixed' ) or die "Error creating multipart container: $!\n";
	$msg->attach (
  		Type => 'TEXT',
  		Data => $text
	) or die "Error adding the text message part: $!\n";
	 MIME::Lite->send('smtp', 'localhost', Timeout=>60);
	$msg->send;
	print STDERR "Sent email to $to for new task $id\n" if $DEBUG;
}
#######################################################################333
sub isAckOrRecovery {
	my $mime = shift;
	my $sub = $mime->header('Subject');
	#reply if task or bug is in subject
	if ($sub =~ /RECOVERY/ || $sub =~ /ACKNOWLEDGEMENT/) {
		return 1;
	}
	else {
		return 0;
	}
}
#######################################################################333
sub isReply {
	my $mime = shift;
	my $sub = $mime->header('Subject');
	#reply if task or bug is in subject
	if ($sub =~ /Task: \d+/ || $sub =~ /Bug: \d+/) {
		return 1;
	}
	else {
		return 0;
	}
}
#######################################################################333
sub createTask {
		my $mime = shift;
		my @parts = $mime->parts;
		my $part;
		my $i;
		my %record;
		my $filename;
		my $attach_encoded;
		my $attach_type;
		foreach $part (@parts) {
			print "Part", $i++, "\n" if $DEBUG;
			print "Type:", $part->content_type, "\n" if $DEBUG;
			if($part->content_type =~ /text\/html/) {
				print "Setting long_desc\n" if $DEBUG;
				print $part->body if $DEBUG;
				if($opt{i}) {
				$record{long_desc} .= $mime->header('From'), "\n";
				$record{long_desc} .=  $part->body;
				}
				else {
				$record{long_desc} .= $mime->header('From'), "\n";
				$record{long_desc} .= $opt{L} || $part->body;
				}
			}
			
			#grab wma attachment 
			elsif($part->content_type =~ /application\/octet-stream; name=(.+)/) {
				print "Setting attachment\n" if $DEBUG;
				$filename =$1;
				$attach_encoded=$part->body_raw;
				$attach_type=$part->content_type;
				#print $attach_encoded if $DEBUG;
			}
			else {
				$record{long_desc} .= $mime->header('From'), "\n";
				$record{long_desc} .= $part->body;
			}

		}
		$msg_body = $record{long_desc};
		#set all hash parms for create command
		my $reporter = $opt{R} || &getUserIDFromEmail($mime->header('From')) || '0';
		$record{reporter} = $reporter;
		if($opt{i}) {
			$record{short_desc} =  $mime->header('Subject');
		}
		else {
			$record{short_desc} = $default_desc || 'Vnote Feedback';
		}
		$record{type} = $type;
		$record{feedback_email} = $mime->header('From');
		$record{feedback_email} =~ s/'/\\`/g;
		$record{feedback_email} =~ s/"/\\"/g;
		$record{priority} = $priority;
		$record{priority} = $priority;
		@{$record{keywords}}=@keywords;
		$record{severity} = $severity;
		$record{status_whiteboard} = $whiteboard;
		$record{projectid} = $project;
		$record{componentid} = $component;
		$record{status} = 1;
		$record{long_desc} =~ s/'/`/g;
		$record{long_desc} =~ s/"/`/g;
		print "Filename: $filename\n" if $DEBUG;
		#print values(%record) if $DEBUG;
		my $userid = '0';
		print "oo\n" if $DEBUG;
		#create record
		my $newRecordId=&db_CreateRecord(\%record,$userid);
		print "New recordid $newRecordId\n" if $DEBUG;
		#add attachment
		&addAttachment($newRecordId, $filename, $attach_encoded, $attach_type);
		return $newRecordId;
}
#######################################################################333

sub addAttachment {
	my $record = shift;
	my $filename = shift;
	my $encoded = shift; 
	my $type = shift;
	my $sql = "insert into traq_attachments set record_id=\"$record\",creation_ts=now(),";
	$sql .= "description=\"\",filename=\"$filename\",thedata=\'$encoded\',submitter_id=\"0\"";
	$sql .= ",mimetype=\"$type\"";
	&doSql($sql);
	$sql = "insert into traq_activity set 
			   record_id=$record,
			   who=0,date=now(),
			   fieldname=\"create\",
			   oldvalue=\"\",
			   newvalue=\"filename: $filename\",
			   tablename=\"traq_attachments\"";
	&doSql($sql);
}


sub usage {
        print "\nusage: popcheck.pl 
        -h pop host
        -u pop user
        -p pop passwd
        -P ProjectID
        -C ComponentID
        -S Severity
        -U Urgency
        -T Type task or bug
        -R reporter
        -d default short desc
        -L Longe desc\n";      
        exit;
}
sub getUserIDFromEmail {
	my $email = shift;
	$email =~ /<*(\w+\@\w+\.\w+)>*/;
	$email = $1;
	my $sql = "select userid from logins where email = '$email'";
	my %res = doSql($sql);
	if($res{userid}[0]) {
			return  $res{userid}[0];
		}
		else { 
			return 0; 
			}
	} 
