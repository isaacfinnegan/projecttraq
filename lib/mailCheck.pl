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

# This script is to be used in a cron or scheduled task to check the designated
# projecttraq email account and populate record comments with replies from users
# to notification emails

# Read through the first part of this script to setup the variables for 
# your email server setup

# POP3 email server
my($POPSERVER)="mail.smokeyroom.com";

# POP3 account username
my($USERNAME)='tester';

# POP3 account password
my($PASSWORD)='test';

# Path to projectraq lib directory
use lib "./lib";

# Set to 1 if you wish to see progress info
my($DEBUG)=1;

# You do not need to change anything past this line
###################################################
use TraqConfig;
use mailResponder;
use Mail::POP3Client;
use Email::MIME;
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;

my($subject,$from,$body,$line,$recid);

my ($pop) = new Mail::POP3Client(
    USER     => $USERNAME,
    PASSWORD => $PASSWORD,
    HOST     => $POPSERVER
);

print "Connected to POP Server\n" if $DEBUG;

my($msgcount)=$pop->Count();

print "$msgcount messages on Server\n" if $DEBUG;

for ( my ($i) = 1 ; $i <= $msgcount ; $i++ )
{
	$recid='';
    foreach ( $pop->Head($i) )
    {
        if (/^(From):\s+/i)
        {
            $from = $_;
            # Get the actual address from the header
            $from=~/From:.+?(\S+\@\S+).*/i;
            $from=$1;
            # Trim < and > from outside email address if any
            $from=~s/[<|>]//g;
        }
        if (/^(Subject):\s+/i)
        {
            $subject = $_;
			$subject=~/[Task|Bug]:\ ([0-9]+)/;
			# Get the record ID from the Subject
			$recid=$1 || '';
			$recid='' unless($recid=~/[0-9]+/);
        }
        
    }
# 	print "$subject\n";
# 	print "$from\n";
# 	print "$recid\n";
# 	print "\n";
# 	exit if $i > 10;

	if($recid)
	{
		#$body=$pop->Body($i) || '';
		my $fullmessage = Email::MIME->new($pop->Retrieve($i));
		my Email::MIME @messageparts = $fullmessage->parts;
		my $bodyfound = 0;
		foreach my $msgpart (@messageparts)
		{
			if (lc($msgpart->content_type) == "text/plain")
			{
				$bodyfound = 1;
				$body = $msgpart->body;
			}
			break if ($bodyfound == 1);
		}
		print "Saving comment for record $recid\n" if $DEBUG;
	
		&saveComment($from,$recid,$body);
		undef($fullmessage);
		undef(@messageparts);
		#Delete message from mail server
	}
	$pop->Delete($i);
}

# Close pop connection
$pop->Close;

print "Disconnected from POP Server\n" if $DEBUG;


exit;