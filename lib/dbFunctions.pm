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

##############################################################
use lib "./";

##############################################################
# functions contained herein:
# void dbConnect($user, $password, $server, $database)
#	instantiates global $connection variable
# %res doSql($sql)
# 	executes an sql statement, returning a hash of arrays
##############################################################
### dbConnect(user, password, server, database)  
##############################################################
package dbFunctions;

use TraqConfig;

use Exporter;
use strict;
use vars qw(
	$VERSION
	@ISA
	@EXPORT
	@EXPORT_TAGS
	@EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(doSql dbConnect);
our %EXPORT_TAGS= (ALL => [@EXPORT, @EXPORT_OK]);

use vars qw(%c);
*c = \%TraqConfig::c;

if($c{profile})
{
	eval("use Time::HiRes");
	eval("use Time::Stopwatch");
}

my($total);
my($numq)=0;
my($connection) = dbConnect();

# connects to mysql db and inits global $connection variable
# passed user, password, server, and database
sub dbConnect {
	my($connection);
        my($user, $password, $server, $database) = 
		($c{db}{user}, $c{db}{password}, $c{db}{host}, $c{db}{database});
        my($driver)= $c{db}{driver};
        my($dsn) = "DBI:$driver:database=$database;host=$server";
#        $connection = DBI->connect($dsn,$user,$password) or die "$DBI::errstr --- $dsn,$user,$password";
        $connection = DBI->connect($dsn,$user,$password);
	return($connection);
}
##############################################################
### doSql(sql) returns an hash of arrays
##############################################################
sub doSql {
    my(%res,$arrr,$timer);
	if($c{profile})
	{
	    tie $timer, 'Time::Stopwatch';
    }
    my($i) = 0;
    my($sql) = shift;
	my($PRO) = shift;
	my($returnid)= shift;
	my($connection);
	my($con) = $connection || &dbConnect();
	$connection = $con;
	my($rv);
	unless(!$connection) {
		print STDERR "DB Executing: $sql\n" if($c{debug}{sql});
		print STDERR "DBTIMER: $timer Executing sql.\n" if($c{profile});
		my(%selectall_arrayref_as_hash_attr) = ( dbi_fetchall_arrayref_attr=>{}, Slice=>{} );
		$arrr = $connection->selectall_arrayref($sql,\%selectall_arrayref_as_hash_attr);
		$c{cache}{totalqueries}++;
		if($returnid)
		{
			my(%selectall_arrayref_as_hash_attr) = ( dbi_fetchall_arrayref_attr=>{}, Slice=>{} );
			$arrr = $connection->selectall_arrayref('select last_insert_id() ',\%selectall_arrayref_as_hash_attr);
			print STDERR "Record ID: $$arrr[0]{'last_insert_id()'}\n" if($c{logging}{loglevel} eq 7);
			return $$arrr[0]{'last_insert_id()'};
		}
		print STDERR "DBTIMER: $timer - Query executed\n" if($c{profile});
		if($arrr eq undef)
		{
			print STDERR "ERROR: failed execution of sql: ".$sql;
		}
		if(ref $arrr eq 'ARRAY')
		{			
			unless(scalar(@$arrr))
			{
				return %res;
			}
			for(my($i) = 0; $i < scalar(@$arrr); $i++) {
				my($key);	
				foreach $key ( keys(%{$$arrr[$i]}) ) {
	   	  		$res{$key}[$i] = $$arrr[$i]{$key};
		      		}
			}
		}
		print STDERR "DBTIMER: $timer - doSql Call complete\n" if($c{profile});
		if(%res) {
   			 	return(%res);
		}
		else {
			return %res;
		}
	}
	return %res;	
}

return 1;
