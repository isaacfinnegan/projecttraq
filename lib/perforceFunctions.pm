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


#############################################################r
use lib "./";
##############################################################
package perforceFunctions;

use Exporter ();
use strict;
use vars qw(
	$VERSION
	@ISA
	@EXPORT
	@EXPORT_TAGS
	@EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(
	&doJobSpec

	);
	
our %EXPORT_TAGS = (ALL => [@EXPORT, @EXPORT_OK]);

use DataProc qw(&Process);

use TraqConfig;
use CGI;
use dbFunctions;
use vars qw(%c);
*c = \%TraqConfig::c;

my($userid,$DEBUG);

if($c{logging}{usesyslog})
{
	eval 'use Sys::Syslog qw(:DEFAULT setlogsock)';
}

sub setJobSpec {
	my($sql)="select * from traq_menus"; 
	my($jobspec)="Fields:\n";
	$jobspec.="		101 $c{general}{label}{record_id} word 12 required\n";
	$jobspec.="		106 $c{general}{label}{status}\n";
	$jobspec.="		117 $c{general}{label}{status_whiteboard} text 250 optional\n";
	$jobspec.="		107 $c{general}{label}{assigned_to} word 24 optional\n";
	$jobspec.="		108 $c{general}{label}{delta_ts} date 20 optional\n";
	$jobspec.="		109 $c{general}{label}{resolution} word 24 optional\n";
	$jobspec.="		110	$c{general}{label}{component} word 50 optional\n";
	$jobspec.="		111 $c{general}{label}{version} word 50 optional\n";
	$jobspec.="		112 $c{general}{label}{bug_platform} word 50 optional\n";
	$jobspec.="		113 $c{general}{label}{bug_op_sys} word 50 optional\n";
	$jobspec.="		114 $c{general}{label}{priority} word 24 optional\n";
	$jobspec.="		115 $c{general}{label}{severity} word 24 optional\n";
	$jobspec.="		116 $c{general}{label}{target_milestone} word 24 optional\n";
	$jobspec.="		105 $c{general}{label}{thetext} text 0 optional\n";
	
	
	
}



END {}
1;
