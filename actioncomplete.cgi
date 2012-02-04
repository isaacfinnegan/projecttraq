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
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;

&startLog();
my ($LOGGING) = 5;

my (
     $templatefile, $connection, $q,  %results, $newRecordId,
     $userid,       $id,         @id, $DEBUG
);
$q      = new CGI;
$DEBUG  = $q->param('debug');
$userid = &getUserId($q);

my ($popup) = $q->param('popup');

$results{'QUERYID'}[0] = $q->param('queryid');
unless($results{'QUERYID'}[0])
{
	$results{QUERYREL}[0]='<!--';
	$results{QUERYREL2}[0]='-->';
}
$results{'ACTION'}[0]  = $q->param('action');
@{ $results{'RESULT'} } = split( /,/, $q->param('result') );
my ($type) = $q->param('type') || 'traq';
my (@ids) = split( /,/, $q->param('id') );
my ($i) = 0;
foreach $id (@ids)
{
    $id =~ /(\w)(\d+)/;
    $results{'ID'}[$i]     = $2;
    $results{'IDTYPE'}[$i] = $1;
    $i++;
}
$id[0] =~ /\w(\d+)/;
my ($num) = $1;

my ( $prev, $next, $index, $numresults ) =
  &GetPrevNextResults( $results{'ID'}[0], $userid );
$results{'INDEX'}[0]      = $index;
$results{'NUMRESULTS'}[0] = $numresults;
${ $results{'PREV'} }[0] = $prev;
${ $results{'NEXT'} }[0] = $next;
$results{AREA}[0] = $type;
$results{FORM}[0] = 'enter' . ucfirst($type) . 'Form.cgi';

$results{'USER'}[0]     = &getNameFromId($userid);
$results{'PISSROOT'}[0] = $c{'url'}{'base'};
&populateHeaderFooter( \%results );
print $q->header;
my ($html);
if ($popup)
{
    $templatefile =
      &getTemplateFile( $c{dir}{generaltemplates}, 'actionpopup.tmpl',
                        $userid );
}
else
{
    $templatefile =
      &getTemplateFile( $c{dir}{generaltemplates}, 'action.tmpl', $userid );
}
$results{HEADER}[0]=&getHeader($userid,$type);
$results{FOOTER}[0]=&getFooter($userid,$type);
$html = Process( \%results, $templatefile );
print $html;

