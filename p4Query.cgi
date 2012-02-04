#!/usr/bin/perl
# Author: Sean Tompkins
# 11/16/05
# This script takes a list of perforce change numbers and depot path and returns a list of
# projecttraq bugs associated with them. 

use strict;
use CGI;
use lib "/www/perl/projecttraq/lib";
use dbFunctions;
use supportingFunctions;
use TraqConfig;
use DataProc qw(&Process);
use vars qw(%c);
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});




my $q = new CGI;
my $mode = $q->param('mode') || "start";
my $DEBUG= $q->param('debug');
if($mode eq "start") {
	print $q->header;
	my %html;
	my($templatefile)=&getTemplateFile('','p4Query.tmpl');
	my $html = &Process(\%html, $templatefile);
	print $html;
}
else{		
	print $q->header if $DEBUG;
	print "<pre>" if $DEBUG;
	
	my $URL="http://pt.coremobility.com/projecttraq/do_query.cgi?type=bug&queryname=&return_bugs=1&submit=Please+wait...&status_class=&short_desc=&short_desc_type=substring&long_desc=&long_desc_type=substring&status_whiteboard=&status_whiteboard_type=substring&keywords_type=any&attach_have=&role_andor=or&start_creation_ts=&end_creation_ts=&start_delta_ts=&end_delta_ts=&bug_id_type=include&chfield_from=&chfield_to=&changeto=&changedin=&changeby=&bool_field1=none&bool_operator1=none&bool_value1=&bool_type1=or&bool_field2=none&bool_operator2=none&bool_value2=&bool_type2=or&bool_field3=none&bool_operator3=none&bool_value3=&bool_type3=or";
	
	my $CHANGE_RANGE=$q->param('range') || $ARGV[0];
	my $PATH= $q->param('path') || $ARGV[1] || "//depot/...";
	
	my $P4CMD="/usr/local/bin/p4 -u admin -p perforce.coremobility.com:1777 -c foo -H perforce.coremobility.com  -P den1ed";
	my(@RANGE)=split(/,/, $CHANGE_RANGE);
	
	open(P4, "$P4CMD changes $PATH\@$RANGE[0],$RANGE[1] |") || die "Cannot open perforce $!\n";
	local $/;
	
	my $CHANGES= <P4>;
	my @CHANGENUMBERS;
	my @CHANGES = split(/\n/, $CHANGES);
	foreach (@CHANGES	) { 
		/Change (\d+) on/;
		print if $DEBUG;
		print "\n" if $DEBUG;
		push(@CHANGENUMBERS, $1) if $1;
		last unless /\d+/;
	}
	my $f;
	foreach $f (@CHANGENUMBERS) {
		print "CHANGE $f\n" if $DEBUG;
	}
	print "Change Array: @CHANGENUMBERS\n" if $DEBUG;
	
	my $sql = "select distinct record_id,changelist from traq_records
		where changelist is not null 
		and changelist != ' '";
	
	my %res = &doSql($sql);
	
	my @BUGS;
	
	for(my $i =0; $i<scalar(@{$res{record_id}}); $i++) {
		my $change;
		print "looking at bug: $res{record_id}[$i]\n" if $DEBUG;
		print "\t $res{changelist}[$i]\n" if $DEBUG;
		foreach $change (@CHANGENUMBERS) {
				if(grep(/^$change$/, $res{changelist}[$i])) {
						print "Found match: change: $change bug: $res{record_id}[$i]\n" if $DEBUG;
						push(@BUGS, $res{record_id}[$i]);
					}
				}
			}
			
	my $BUGS = join(",", @BUGS);
	$URL .="&record_id=$BUGS";
	
	print "$URL\n" if $DEBUG;;
	print "$CHANGE_RANGE\n" if $DEBUG;;
	print "$P4CMD changes $PATH\@$RANGE[0],$RANGE[1]\n" if $DEBUG;;
	print $q->redirect($URL) unless $DEBUG;
}

exit;
