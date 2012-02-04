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

use lib "./";

package mailResponder;

use Exporter ();
use strict;
use vars qw(
  $VERSION
  @ISA
  @EXPORT
  @EXPORT_TAGS
  @EXPORT_OK);
@ISA    = qw(Exporter);
@EXPORT = qw(
  &saveComment

);
our %EXPORT_TAGS = ( ALL => [ @EXPORT, @EXPORT_OK ] );

use DataProc qw(&Process);

use TraqConfig;
use supportingFunctions;
use dbFunctions;
use vars qw(%c);
*c = \%TraqConfig::c;

my ( $userid, $DEBUG );

if ( $c{logging}{usesyslog} )
{
    eval 'use Sys::Syslog qw(:DEFAULT setlogsock)';
}

# Gets message Subject and body and comments appropriate record

sub saveComment
{
    my ( $from, $recid, $body ) = @_;
    my ( $note, $userid );

    my (%res) =
      &doSql(
"select $c{db}{logintablekey} from $c{db}{logintable} where email=\"$from\""
      );
    if (%res)
    {
        $userid = $res{userid}[0];
    }
    elsif ( $c{externalaccess}{allowvisitor} )
    {
        $userid = 0;
    }
    else
    {
        return 0;
    }

    #TODO add parsing body for comment from user
    $note = "emailreply: " . &escapeQuotes($body);

    # Create note and return
    addRecordNote( $recid, $note, $userid );
    #TODO add email notification generation for note added
   
    return 1;
}

END{}
1;
