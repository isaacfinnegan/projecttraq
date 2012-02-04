#!/usr/bin/perl
use strict;
use CGI::Carp qw(fatalsToBrowser set_message);
use Mail::Sendmail;
#use TraqConfig;
#use vars qw(%c);
#*c = \%TraqConfig::c;

BEGIN {
	sub sendMail
	{
        	my($from) = 'errors@projecttraq';
        	my ($contenttype) = 'text/plain';
        	my (%mail) = (
        	        To             => $Error::email,
        	        From           => "$from",
        	        Subject        => $ENV{SCRIPT_NAME},
        	        Message        => $_[0],
        	        'content-type' => $contenttype
        	);
        print "<html><body><center><table style='background-color:white;'><tr><td>";
		print "An Error has been encountered. The administrator has been notified.";
		print "</td></tr><tr><td>";
		print "<div style='color:white;'>$_[0]</div>";
		print "</td></tr></table></center></body></html>";
	    sendmail(%mail);
	}
	set_message(\&sendMail);
}

sub import {
  $Error::email = $_[1] || 'errors@yourdomain.com';
}

1;
