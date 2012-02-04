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
use Traqfields;
use DataProc qw(&Process);
use LWP::Simple;
use MIME::Lite;
use Net::SMTP;
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
my ($headersent) = 0;
my (%clear);
%{ $c{cache} } = %clear;

&startLog();
my ($LOGGING)   = 5;
my $DEBUG       = 1;
my ($processid) = $ARGV[0];

#  0    1    2     3     4    5     6     7     8
#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
my (@time) = localtime(time);
$time[4]++;

my $sql = "select * from schedule where ";
if($processid)
{
	$sql.=" schedule_id=$processid";
}
else
{
	$sql.=" active=\'yes\'";
}
my %res = &doSql($sql);

for ( my $i = 0 ; $i < scalar( @{ $res{userid} } ) ; $i++ )
{
	if ( isTime( $i, %res ) || $res{schedule_id}[$i] eq $processid)
	{
		print "Working on schedule $res{schedule_id}[$i]\n" if $DEBUG;
		print "$res{url}[$i]\n"                             if $DEBUG;
		my (@urls) = split( /\n/, $res{url}[$i] );
		my $url;
		my $msg_body;
		my $email=&createMsg($res{alt_email}[$i],$res{userid}[$i],$res{comment}[$i]);
		unless($email)
		{
			die "Couldn't create message object\n";
		}
		foreach $url (@urls)
		{
			$url=~s/\r//g;
			if ( $url =~ /$c{tasktraq}{server}/ )
			{
				print "Tasktraq url, appending auth info\n" if $DEBUG;
				$url .= ";oruser=$c{tasktraq}{oruser};orpasswd=$c{tasktraq}{orpasswd};oruserid=$res{userid}[$i];isschedule=1";
				print "New url: $url\n" if $DEBUG;
			}
			my $content = get $url;
			
			$msg_body.="<br>";
			$msg_body.=$content;
			print "Getting $url\n" if $DEBUG;

		}
		
			$email->attach(
				Type        => 'text/html',
				Data        => "$msg_body",
			  );
		&sendMsg($email,$res{alt_email}[$i],$res{userid}[$i]);
	}
	print "\n\n" if $DEBUG;
}

sub isTime
{
	my $i   = shift;
	my %res = @_;
	print "Checking $res{schedule_id}[$i]\n \t$res{url}[$i]\n"  if $DEBUG;
	print "Now: $time[1] $time[2] $time[3] $time[6] $time[4]\n" if $DEBUG;
	print "Skd: $res{min}[$i] $res{hour}[$i] $res{day}[$i] $res{dayofweek}[$i] $res{month}[$i]\n"
	  if $DEBUG;
	if (   ( $res{min}[$i] eq "$time[1]" || $res{min}[$i] eq "*" )
		&& ( $res{hour}[$i]      eq "$time[2]" || $res{hour}[$i]      eq "*" )
		&& ( $res{day}[$i]       eq "$time[3]" || $res{day}[$i]       eq "*" )
		&& ( $res{dayofweek}[$i] eq "$time[6]" || $res{dayofweek}[$i] eq "*" )
		&& ( $res{month}[$i]     eq "$time[4]" || $res{month}[$i]     eq "*" ) )
	{
		print "it's time!\n" if $DEBUG;
		return 1;
	}
	else
	{
		return 0;
	}
}

sub createMsg
{
	my($alt_email,$userid,$comment) = @_;
	my $to_email  = $alt_email || getEmail($userid);
	my $msg = MIME::Lite->new(
		From    => "pt_noreply\@coremobility.com",
		To      => "$to_email",
		Subject => "$comment",
		Type    => 'multipart/mixed'
	  )
	  || die "Error Creating container $!\n";
	return $msg;
}
sub sendMsg
{
	my($msg,$alt_email,$userid) = @_;
	my $to_email  = $alt_email || getEmail($userid);

	MIME::Lite->send( 'smtp', 'exchange.coremobility.com', Timeout => 60 );
	$msg->send;
	print "Email sent to $to_email\n" if $DEBUG;

#	unlink $tfile;
}

