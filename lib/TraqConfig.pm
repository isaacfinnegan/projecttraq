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

package TraqConfig;
use strict;
use Exporter;
use vars qw(
	%c
	@EXPORT
	);
@EXPORT = qw(&outsideLogin);
use	Date::Calc;
use DataProc qw(&Process);
use Hack;

if( $ENV{MOD_PERL} ) {
    eval 'use Apache::DBI';
} else {
    eval 'use DBI';;
}
die $@ if $@;
open(CFG, '/usr/local/etc/traq.cfg') ||
open(CFG, '/etc/traq.cfg') ||
open(CFG, '/home/y/etc/traq.cfg') ||
open(CFG, "$ENV{HOME}" . '/traq.cfg') ||
die "Cannot open configuration file $!\n";
my(@conf) = <CFG>;
eval "@conf";
print STDERR "Config error: $@\n" if $@;
if($c{ldap}{ldapauth})
{
	eval 'use Net::LDAP';
	eval 'use Net::LDAP::Entry';
	eval 'use Net::LDAP::Message';
	die $@ if $@;
}
&fixupLabels();
return 1;

################################################################################
#
#	fixupLabels()
#
#	Purpose:
#
#		To support the older "...label" hashes,
#		by bridging from them to the newer "label" sub-hashes.
#
################################################################################
sub fixupLabels() {
	
	#	Fix up the "general" sub-hash
	$c{general}{recordlabel}		= $c{general}{label}{record_id};
	$c{general}{summarylabel}		= $c{general}{label}{short_desc};
	$c{general}{versionlabel}		= $c{general}{label}{version};
	$c{general}{assignedlabel}		= $c{general}{label}{assigned_to};
	$c{general}{techlabel}			= $c{general}{label}{tech_contact};
	$c{general}{qalabel}			= $c{general}{label}{qa_contact};
	$c{general}{reporterlabel}		= $c{general}{label}{reporter};
	$c{general}{componentidlabel}	= $c{general}{label}{componentid};
	$c{general}{statuslabel}		= $c{general}{label}{status};
	$c{general}{projectidlabel}		= $c{general}{label}{projectid};
	$c{general}{whiteboardlabel}	= $c{general}{label}{status_whiteboard};
	$c{general}{oslabel}			= $c{general}{label}{bug_op_sys};
	$c{general}{cclabel}			= $c{general}{label}{cc};
	$c{general}{prioritylabel}		= $c{general}{label}{priority};
	$c{general}{creationlabel}		= $c{general}{label}{creation_ts};
	$c{general}{changelabel}		= $c{general}{label}{delta_ts};
	$c{general}{platformlabel}		= $c{general}{label}{bug_platform};
	$c{general}{severitylabel}		= $c{general}{label}{severity};
	$c{general}{resolutionlabel}	= $c{general}{label}{resolution};
	$c{general}{reprolabel}			= $c{general}{label}{reproducibility};
	$c{general}{targetlabel}		= $c{general}{label}{target_date};
	$c{general}{milestonelabel}		= $c{general}{label}{target_milestone};
	$c{general}{targetlabel}		= $c{general}{label}{target_date};
	$c{general}{keywordslabel}		= $c{general}{label}{keywords};
	$c{general}{longdesclabel}		= $c{general}{label}{long_desc};

	#	Fix up the "tasktraq" sub-hash
	$c{tasktraq}{recordlabel}		= $c{tasktraq}{label}{record_id};
	$c{tasktraq}{summarylabel}		= $c{tasktraq}{label}{short_desc};
	$c{tasktraq}{versionlabel}		= $c{tasktraq}{label}{version};
	$c{tasktraq}{assignedlabel}		= $c{tasktraq}{label}{assigned_to};
	$c{tasktraq}{techlabel}			= $c{tasktraq}{label}{tech_contact};
	$c{tasktraq}{qalabel}			= $c{tasktraq}{label}{qa_contact};
	$c{tasktraq}{reporterlabel}		= $c{tasktraq}{label}{reporter};
	$c{tasktraq}{componentidlabel}	= $c{tasktraq}{label}{componentid};
	$c{tasktraq}{statuslabel}		= $c{tasktraq}{label}{status};
	$c{tasktraq}{projectidlabel}	= $c{tasktraq}{label}{projectid};
	$c{tasktraq}{whiteboardlabel}	= $c{tasktraq}{label}{status_whiteboard};
	$c{tasktraq}{prioritylabel}		= $c{tasktraq}{label}{priority};
	$c{tasktraq}{creationlabel}		= $c{tasktraq}{label}{creation_ts};
	$c{tasktraq}{changelabel}		= $c{tasktraq}{label}{delta_ts};
	$c{tasktraq}{platformlabel}		= $c{tasktraq}{label}{bug_platform};
	$c{tasktraq}{severitylabel}		= $c{tasktraq}{label}{severity};
	$c{tasktraq}{resolutionlabel}	= $c{tasktraq}{label}{resolution};
	$c{tasktraq}{reprolabel}		= $c{tasktraq}{label}{reproducibility};
	$c{tasktraq}{oslabel}			= $c{tasktraq}{label}{bug_op_sys};
	$c{tasktraq}{cclabel}			= $c{tasktraq}{label}{cc};
	$c{tasktraq}{keywordslabel}		= $c{tasktraq}{label}{keywords};
	$c{tasktraq}{longdesclabel}		= $c{tasktraq}{label}{long_desc};
	$c{tasktraq}{notelabel}			= $c{tasktraq}{label}{note};
	$c{tasktraq}{targetlabel}		= $c{tasktraq}{label}{target_date};
	$c{tasktraq}{units_reqlabel}	= $c{tasktraq}{label}{units_req};
	$c{tasktraq}{milestonelabel}	= $c{tasktraq}{label}{target_milestone};
	$c{tasktraq}{changelistlabel}	= $c{tasktraq}{label}{changelist};

	#	Fix up the "bugtraq" sub-hash
	$c{bugtraq}{recordlabel}		= $c{bugtraq}{label}{record_id};
	$c{bugtraq}{summarylabel}		= $c{bugtraq}{label}{short_desc};
	$c{bugtraq}{versionlabel}		= $c{bugtraq}{label}{version};
	$c{bugtraq}{assignedlabel}		= $c{bugtraq}{label}{assigned_to};
	$c{bugtraq}{techlabel}			= $c{bugtraq}{label}{tech_contact};
	$c{bugtraq}{qalabel}			= $c{bugtraq}{label}{qa_contact};
	$c{bugtraq}{reporterlabel}		= $c{bugtraq}{label}{reporter};
	$c{bugtraq}{componentidlabel}	= $c{bugtraq}{label}{componentid};
	$c{bugtraq}{statuslabel}		= $c{bugtraq}{label}{status};
	$c{bugtraq}{projectidlabel}		= $c{bugtraq}{label}{projectid};
	$c{bugtraq}{whiteboardlabel}	= $c{bugtraq}{label}{status_whiteboard};
	$c{bugtraq}{prioritylabel}		= $c{bugtraq}{label}{priority};
	$c{bugtraq}{creationlabel}		= $c{bugtraq}{label}{creation_ts};
	$c{bugtraq}{changelabel}		= $c{bugtraq}{label}{delta_ts};
	$c{bugtraq}{platformlabel}		= $c{bugtraq}{label}{bug_platform};
	$c{bugtraq}{severitylabel}		= $c{bugtraq}{label}{severity};
	$c{bugtraq}{resolutionlabel}	= $c{bugtraq}{label}{resolution};
	$c{bugtraq}{reprolabel}			= $c{bugtraq}{label}{reproducibility};
	$c{bugtraq}{oslabel}			= $c{bugtraq}{label}{bug_op_sys};
	$c{bugtraq}{cclabel}			= $c{bugtraq}{label}{cc};
	$c{bugtraq}{keywordslabel}		= $c{bugtraq}{label}{keywords};
	$c{bugtraq}{longdesclabel}		= $c{bugtraq}{label}{long_desc};
	$c{bugtraq}{notelabel}			= $c{bugtraq}{label}{note};
	$c{bugtraq}{urllabel}			= $c{bugtraq}{label}{url};
	$c{bugtraq}{milestonelabel}		= $c{bugtraq}{label}{target_milestone};
	$c{bugtraq}{changelistlabel}	= $c{bugtraq}{label}{changelist};
}
