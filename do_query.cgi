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
use Traqfields;
use dbFunctions;
use supportingFunctions;
use URI::Escape;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;

if($c{query}{gantt})
{
	eval 'use Date::Calc qw(:all)';
	eval 'use Time::Local';
	eval 'use Time::localtime';
	eval 'use GDgantchart';
}
# Init variables and timers
&startLog();
my ($queryid);
my ($LOGGING)    = 5;
my ($PRO)        = 0;
my ($DEBUG)      = 0;
my ($NUMQUERIES) = 0;
my ($q)          = new CGI;

my ($selfurl) = $q->url( -absolute => 1 );
my ($type)       = $q->param('type') || "bug";
my ($typeplural) = $type . "s";
my ($gant)       = $q->param('gant');
my ($gantimage)       = $q->param('gantimage');
my ($xcel) = $q->param('excel') if $c{general}{excel};
my ($csv) = $q->param('csv');

my ($resultstemplate);
my ( $odd, %results, $html,    $breakdown, @farthest, @earliest, $farthest, $earliest, $saved_results, $rslt, $ii,        $NUMQUERIES, $db,  %res,    $reverse );
my ( $map0,    @xvalues, $m,  $highlight,       $d,        $xtitle,   $ytitle,   $dow,      @dow,    $tmp,       $ordersave, @completes, $y,          $grp, $userid, @result_ids );
my ($excelfilename, $workbook,$worksheet,$fh,$format1,$format2,$dateformat,$csvfilename);
my $excelfile='';
my $sql_statement;
my %paramhash;
my %hash;
my $hashref;
my $hiermode;
my $loop_count = 0;
my $template   = "temp_query.html";
if($xcel)
{
    &log("DEBUG: creating excel spreadsheet of query output",7);
    eval 'use Spreadsheet::WriteExcel';
    # Requires perl 5.8 or later
    open $fh, '>', \$excelfile or die "Failed to open filehandle: $!";
    
    $workbook  = Spreadsheet::WriteExcel->new($fh);
    $worksheet = $workbook->add_worksheet();
    $format1 = $workbook->add_format();       
    $format1->set_properties(bold => 1); 
    $format2 = $workbook->add_format();       
    $format2->set_properties(text_wrap => 1); 
    $dateformat=$workbook->add_format(num_format=> 'yyyy/mm/dd');
}
my $csvfh;

	my $csvtmpfile = "$c{dir}{tmp}/$$.csv";

if($csv) 
{	
	open($csvfh, ">$csvtmpfile") || die "Cannot open csv tmp file $csvtmpfile\n";
	
}
my ($user) = &getUserId($q);
$userid = $user;
my (%prefs) = &getMailPrefs($userid);

if($ENV{QUERY_STRING} eq 'hier=&queryid=' || $ENV{QUERY_STRING} eq 'gant=1&queryid=')
{
	&doError("There was no query to perform this operation on");
}

# Which template to use
my ($templatetype) = $q->param("templatetype") || "html";
if ( $templatetype eq "html" )
{
	$resultstemplate = "query_results.tmpl";
}
# non tables query results page
elsif ( $templatetype eq "text" )
{
	$resultstemplate = "query_results_text.tmpl";
}

# also display with non-table if prefs are set
if ( grep( /textresults/, @{ $prefs{'prefs'} } ) )
{
	$resultstemplate = "query_results_text.tmpl";
	$templatetype    = "text";
}
if ($gant)
{
	$resultstemplate = "query_gant.tmpl";
}

# Check to see if we need to draw in hierarchal mode.
my ($hiercheck) = $q->param('hier');
if ( $hiercheck eq '0' || $hiercheck eq '1' )
{
	$hiermode = $hiercheck;
}
elsif ( grep( /hier/, @{ $prefs{'prefs'} } ) )
{
	$hiermode = 1;
}
else
{
	$hiermode = 0;
}
if($xcel)
{
    $hiermode = 0;
}
if($csv)
{
    $hiermode = 0;
}
# Query id is tracked across CGI's.  allows user to work with multiple query results in different browser windows.
# so query is not based on session

$queryid = $q->param('queryid') || &getNewQueryId($userid);
if($q->cookie($queryid . 'hier'))
{
	$hiermode=1;
}
if ( $queryid eq "none" )
{
	&doError("I'm sorry, this record did not have a parent query to return to.<br>Please hit the back button or follow <a href=\"$c{url}{base}\">this</a> link back.\n");

}
if($q->param('reportmode'))
{
    $hiermode=0;
}
my (@usergroups) = &getGroupsFromEmployeeId($userid);

# Get saved query and display order
my ( $dd, $query_name, $orderby );
$query_name = $q->param('qname');
$orderby    = $q->param('orderby');
unless ($orderby)
{
	$orderby = &getSavedOrderBy($user);
}
unless($orderby)
{
	$orderby = 'rec.status';
}
foreach $dd (split(',',$c{general}{rolemenu}) )
{
	if($orderby!~/lkup/)
	{
		$orderby =~ s/$dd|rec.$dd/lkup$dd.$c{useraccount}{sortname}/;
	}
}

# Determine how we're being called
my ( $savedquerysql, $savedsortorder , $url_query_string) = &getQuery( $queryid, $userid );

# get query string for 'edit this query'
if(!$url_query_string)
{
	$url_query_string=$ENV{QUERY_STRING};
}
if($query_name=~/^traq_.*/ && $url_query_string=~/qname/)
{	
	my($tmp)=$query_name;
	$tmp=~s/traq_(.*)/$1/;
	$excelfilename=$tmp;
	$csvfilename=$tmp;
    my(%tmp)=&doSql("select url from traq_namedqueries where userid=$userid and name=\"$tmp\"");
	if(%tmp)
	{
		$url_query_string=$tmp{url}[0];
		$url_query_string=~s/do_query\.cgi\?//;
		$url_query_string=~s/;/&/g;
	}
}
else
{
   	$excelfilename='query';
   	$csvfilename='query';
}
if($query_name=~/^user.*/ && $url_query_string=~/qname/)
{
	$url_query_string='invalid';
}
$url_query_string=~s/type=(bug|task)/cat=$1/;

# is this a saved query?
if ( $query_name ne '' )
{
	$sql_statement = &getCannedQuery( $query_name, $orderby, $q, $userid );
}

# is this a query that's already been run/returned to (using queryid)
elsif ($savedquerysql)
{
	my ($orderbyparam) = $q->param('orderby');
	$savedsortorder = &reverse( $orderbyparam, $userid, $queryid )
	  || $savedsortorder
	  || $orderby;
	foreach $dd (split(',',$c{general}{rolemenu}) )
	{	
		if($savedsortorder!~/lkup/)
		{
			$savedsortorder =~ s/$dd|rec.$dd/lkup$dd.$c{useraccount}{sortname}/;
		}
	}
	$sql_statement = $savedquerysql . " order by " . $savedsortorder;
}
# must have been called from a query entry page.
# so build query from selected query options.
else
{
	$sql_statement = &ConstructQuery($q,$userid,\@usergroups,$orderby);
	&log( "got sql from ConstructQuery: $sql_statement", 4 );
}

$ordersave = $savedsortorder;

# store query in the tracker to be called if the user wants to return to this query
&saveQuery( $userid, $queryid, $sql_statement, $ordersave,$url_query_string);

&log( "query sql: $sql_statement", 3 );

# run the query (this function also greps in the necessary security acl joins)

%results = secureRecordGet( $sql_statement, $userid );

if($q->param('debug'))
{
    $results{DEBUGOUT}[0]=$sql_statement;
}

# Save query if they've specified a query name
# NOTE: sql saved is without security joins, this allows query info to be shared
#	as the security acls will always be joined in by do_query
if ( $q->param('queryname') ne ''  && !$xcel && !$csv )
{
	my ($queryname) = $q->param('queryname');
	$queryname =~ s/\s+/_/g;
	&deleteNamedQuery( $userid, $queryname );
	&saveNamedQuery( $userid, $queryname, $sql_statement, $q, $type );
}

# Get list of record id's
if ( keys(%results) )
{
	if($results{'record_id'})
	{
		@result_ids = @{ $results{'record_id'} };
	}
}

# add query string for 'edit this query'

$results{URL_STRING}[0]=&escapeQuotes($url_query_string);
if($url_query_string eq 'invalid')
{
	$results{URL_STRING}[0]='" onclick="alert(\'This query cannot be editted\');return false;"';
}
# check pref to see if links take user to record in edit mode
my ($defaultmode);
if ( grep( /edit/, @{ $prefs{'prefs'} } ) )
{
	$defaultmode = "edit";                                       
}
else
{
	$defaultmode = "view";
}

# Save query results (these are used to step from record to record without returning to the record list)
#  - i.e. GetPrevNext func
my ($qq) = 0;
foreach $rslt (@result_ids)
{
	$saved_results .= "$rslt,";
	$results{'DEFAULTMODE'}[ $qq++ ] = "look";
}
$saved_results =~ s/\,\Z//;    # always one more comma than we need

if ( $saved_results ne '' )
{
	&saveResults( $userid, $saved_results );
}

###########################################################################3

my ( $qname, $field, $field2, $child, @fields );
my ($i) = 0;

# if use saved query, then set queryname, else use default query
if ( $q->param('query_name') )
{
	$qname = $query_name;
	
}
else
{
	$qname = "traq_defaultquery";
}

# OK, now we start processing the records for display

if ( $results{'record_id'}[0] )
{

	# get users desired fields to be displayed
	if($q->param('returnfields'))
	{
		@fields=$q->param('returnfields');
		if(scalar(@fields)==1)
		{
			@fields=split(',',$q->param('returnfields'));
		}
	}
	else
	{
		@fields = &getReturnFields( $q, $userid );
	}
	$results{'RETURNFIELDS'}[0]=join(',',@fields);
	for ( my ($r) = 0 ; $r <= 10 ; $r++ )
	{
		$results{'RETURN'}[$r] = join( "^", @fields );
		$results{'QNAME'}[$r] = $qname;
	}

	my ($stop);
	$stop = 14;
	for ( my ($i) = 0 ; $i < $stop ; $i++ )
	{
		$results{'QUERYID2'}[$i] = $queryid;
	}
	my ($itercheck)   = 0;
	my (%childdata);
	$i = 0;

	if ($hiermode)
	{
		$results{VIEW}[0]      = 'without';
		$results{HIERBOOL}[0]  = '0';
		$results{HIERSTATE}[0] = '1';
	}
	else
	{
		$results{VIEW}[0]      = 'with';
		$results{HIERBOOL}[0]  = '1';
		$results{HIERSTATE}[0] = '0';
	}
	###########
	# hierarchal mode code

	my (@recordlist);
	my ($key);

	# Put the record hashes into an array of arrays of hashes.  Instead of a hash of arrays
	# we need this for the hierarchal stuff to work.
	&log("INFO: ". scalar( @{ $results{'record_id'} } ));
	for ( my ($ii) = 0 ; $ii < scalar( @{ $results{'record_id'} } ) ; $ii++ )
	{
		my (%temphash);
		foreach $key ( keys(%results) )
		{
			$temphash{$key} = $results{$key}[$ii];
		}
		%{ $recordlist[$ii][0] } = %temphash;
		undef %temphash;
	}
	if ( $hiermode || $gant )
	{
		my (@badchildren);

		# Step throught the results of the query
		for ( my ($ii) = 0 ; $ii < scalar(@recordlist) ; $ii++ )
		{

			# Check for child records and dump record data into %childdata
			if (${ $recordlist[$ii][0] }{children})
			{
				my ($counter) = 1;

				# Get list of all children (recursively done)
				my (@children) = populateChildren( ${ $recordlist[$ii][0] }{record_id} ,\@usergroups);

				for(my($jj)=0;$jj<scalar(@children);$jj++)
				{
					# Add hash of child record to array of arrays matrix
					%{ $recordlist[$ii][$counter] } = %{$children[$jj]};
					$counter++;

					# Add this record_id to list of records that are child records
					push( @badchildren, ${$children[$jj]}{record_id} );
				}

			}
		}

		#Check for and remove any children from the top level ($recordlist[x][0])
		for ( my ($gg) = 0 ; $gg < scalar(@badchildren) ; $gg++ )
		{
			# Make sure QUERYID gets populated extra for each record added to result set			
			for ( my ($hh) = 0 ; $hh < scalar(@recordlist) ; $hh++ )
			{
				if ( $badchildren[$gg] eq ${ $recordlist[$hh][0] }{record_id} )
				{
					splice( @recordlist, $hh, 1 );
				}
			}
		}
	}
    my($column)='A';
	$i = 0;
	my ( $b, $fieldtable, $value, $childspace, @currparent, $match, $test );
	# Add field labels for column headings
	foreach $field (@fields)
	{
		$field =~ s/\b([_\w]+)\b/$1/;
		${ $results{'FIELDNAME'} }[$i]  = "rec." . $field;
		${ $results{'FIELDLABEL'} }[$i] = $c{general}{label}{$field};
        if($xcel)
        {
            my($cell)=$column . '1';
            my($celldata)=$c{general}{label}{$field};
            $celldata=~s/&nbsp;/ /g;
            &log("DEBUG: writing excel cell $cell : $celldata",7);
            $worksheet->write($cell, $celldata,$format1);   
        }
        if($csv) {
        		print $csvfh "$c{general}{label}{$field},";
        	}
        
        $column++;

		$i++;
	}
	        if($csv) {
        		print $csvfh "\n";
        	}
	my ($fieldcount) = $i;
	for ( my ($gg) = 0 ; $gg < scalar(@recordlist) ; $gg++ )
	{
		for ( my ($hh) = 0 ; $hh < scalar( @{ $recordlist[$gg] } ) ; $hh++ )
		{
			$b = 1;

			# Put strikethrough where records are closed and in heir mode
			if ( $hiermode || $gant )
			{
				# Add indents for children
				$childspace = "";
				if ( $hh == 0 )  # no children, so no indent
				{
					$#currparent = -1;
					push( @currparent, ${ $recordlist[$gg][$hh] }{record_id} );
					push( @{ $results{COLLAPSESTATE} },   '' );
					push( @{ $results{LINEAGE} }, '' );
				}
				else
				{
					push( @{ $results{COLLAPSESTATE} },   'none' );
					push( @{ $results{LINEAGE} },   ${ $recordlist[$gg][$hh] }{lineage} );
					my($match)=scalar(split('-',${ $recordlist[$gg][$hh] }{lineage}));
					for ( my ($mm) = 0 ; $mm < $match ; $mm++ )
					{
						$childspace.="<img src=\"images/space.gif\">";
					}
					$childspace .= "<img src=\"images/relat.gif\">";
					
				}
				if(${ $recordlist[$gg][$hh] }{children})
				{
					$childspace="<img id='gif${ $recordlist[$gg][$hh] }{record_id}' src=\"images/plus.gif\" onclick=\"toggle(this,$queryid);\">$childspace";
				}
				else
				{
					$childspace="<img src=\"images/space.gif\">$childspace";				
				}
				push( @{ $results{HIER} }, $childspace );
			}
			
			push( @{ $results{record_ID} }, ${ $recordlist[$gg][$hh] }{record_id} );
			my ($celllabel) = "CELL" . $fieldcount;
			push( @{ $results{$celllabel} }, "<!--" );
			push( @{ $results{CELLEND} }, "-->" );
			# Do conversions for fields
			# 	(this is a hash of arrays, which where the hash is the fieldlist and the arrays are
			#	the values for the records)
		    $column='A';
			foreach $field (@fields)
			{
				$field =~ s/\b([_\w]+)\b/$1/;
				$fieldtable = "FIELD" . "$b";
				${ $recordlist[$gg][$hh] }{$field}=&unEscapeQuotes(${ $recordlist[$gg][$hh] }{$field});
				$value = &getFieldDisplayValue($field,\%{$recordlist[$gg][$hh]},$userid);
				unless ($value)
				{
					$value = "&nbsp;";
				}
				if ( $templatetype eq "text" )
				{
					unless ( $field eq "record_id" )
					{
						$value = &chompPad( $value, $field );
					}
				}
				$b++;
				
				push( @{ $results{"$fieldtable"} }, $value );
				
				if($xcel)
				{
				    my($cell)=$column . ($#{ $results{recordid} } +3);
				    &log("DEBUG: writing excel cell $cell : $value",7);
				    if($field eq 'long_desc')
				    {
                        $value = &getFieldValue($field,\%{$recordlist[$gg][$hh]},$userid);
				    }
				    if($value eq "&nbsp;")
				    {
    				    $worksheet->write($cell, "",$format2);   
				    }
				    elsif(grep(/$field/,split(',',$c{general}{datefields})))
				    {
				        # Incoming date format 2006-01-27 10:50:15  
				        my($datestring)=$value;
				        $datestring=~s/(\d\d\d\d\-\d\d\-\d\d)\s{0,1}/$1T/;
				        $worksheet->write_date_time($cell,$datestring,$dateformat);
				    }
				    else
				    {
    				    $worksheet->write($cell, $value,$format2);   
                    }
				}
				if($csv) {
						if($field eq 'long_desc')
				    {
                        $value = &getFieldValue($field,\%{$recordlist[$gg][$hh]},$userid);
				    }
				    if($value eq "&nbsp;")
				    {
    				    print $csvfh ",";   
				    }
				    #elsif(grep(/$field/,split(',',$c{general}{datefields})))
				    #{
				    #    # Incoming date format 2006-01-27 10:50:15  
				    #    my($datestring)=$value;
				    #    $datestring=~s/(\d\d\d\d\-\d\d\-\d\d)\s{0,1}/$1T/;
				    #    print $csvfh "$value,";
				    #    #$worksheet->write_date_time($cell,$datestring,$dateformat);
				    #}
				    else
				    {
    				    print $csvfh "$value,";   
            }
        }
				$column++;

			}
							if($csv) {
        		print $csvfh "\n";
        	}
			push( @{ $results{recordid} }, ${ $recordlist[$gg][$hh] }{recordid} );

			# Insert row class settings for records
			$highlight = '';
			for(my($z)=0;$z<scalar(@{ $c{query}{highlight} });$z++ )
			{
				if(ref($c{query}{highlight}[$z][0]) eq 'ARRAY')
				{
					if(
						${ $recordlist[$gg][$hh] }{$c{query}{highlight}[$z][0][0]} eq $c{query}{highlight}[$z][0][1] 
						&& 
						${ $recordlist[$gg][$hh] }{$c{query}{highlight}[$z][1][0]} eq $c{query}{highlight}[$z][1][1]
					)
					{
						$highlight .= " $c{query}{highlight}[$z][2]";
					}
				}
				else
				{
					if ( ${ $recordlist[$gg][$hh] }{$c{query}{highlight}[$z][0]} eq $c{query}{highlight}[$z][1] )
					{
						$highlight .= " $c{query}{highlight}[$z][2]";
					}
				}
			}
			# Add strike through class for closed records
			if (
				( ${ $recordlist[$gg][$hh] }{status} > $c{tasktraq}{closethreshold} && ${ $recordlist[$gg][$hh] }{'type'} eq 'task' )
				|| (   ${ $recordlist[$gg][$hh] }{status} > $c{bugtraq}{closethreshold}
					&& ${ $recordlist[$gg][$hh] }{'type'} eq 'bug' )
			  )
			{
				$highlight.=' strike';
			}
			# Setup row class for odd rows
 			if($odd eq ' odd')
 			{
 				$odd='';
 			}
 			else
 			{
 				$odd=' odd';
 			}
 			$highlight.=$odd;
			push( @{ $results{QUERYID} }, $queryid );
 			push( @{ $results{PISSROOTREP} }, $c{'url'}{'base'} );
 			push( @{ $results{ROWCLASS} }, $highlight );
		}
	}
}
if($results{record_ID})
{
    $results{RECLIST}[0]=join(',',@{$results{record_ID}});
}

if($xcel)
{
   
    $excelfilename.='.xls';
    $workbook->close(); 
	print "Content-Type: application/octet-stream\n";
	print "Content-Disposition: attachment\; filename=$excelfilename\n";
	print "\n";
    binmode STDOUT;
    &log("DEBUG: sending excel file  " . length($excelfile),7);
    print $excelfile;
    &stopLog();
    exit;
}
if($csv)
{
   
  
    close($csvfh); 
	print "Content-Type: text/csv\n";
	print "\n";
    binmode STDOUT;
    open(CSV ,"$csvtmpfile");
    my(@cont) = <CSV>;
    close(CSV);
    &log("DEBUG: sending excel file  " . length($excelfile),7);
    print @cont;
    &stopLog();
    exit;
}
if($c{general}{excel})
{
    $results{EXCELON1}[0]="";
    $results{EXCELON2}[0]="";
}
else
{
    $results{EXCELON1}[0]="<!--";
    $results{EXCELON2}[0]="-->";

}

##################################################################
# GANT Chart  - NEEDS WORK
##################################################################
if ($gant)
{
	my ( @xbreaklabels, @xbreaks, @xticks, $loopend,$loopmonth );

	my ( @tasks, @taskstarts, @taskends, @links );

	$farthest = $results{target_date}[0];
	$earliest = '2022-02-02';


	my ( %depmap );
	for ( my ($ii) = 0 ; $ii < scalar( @{ $results{record_id} } ); $ii++ )
	{
		## Fix html special characters since we're looping through everything...
		while ($results{short_desc}[$ii] =~ m/&#(...);/g)
		{
			my $tmpchr = chr($1);
			$results{short_desc}[$ii] =~ s/&#$1;/$tmpchr/;
		}
		my %deps = &getChildren( $results{record_id}[$ii] ,\@usergroups);
		if ( %deps )
		{	
			#&log($results{record_id}[$ii].":".$results{short_desc}[$ii]);
			for( my ($iii) = 0; $iii < scalar( @{ $deps{record_id} } ); $iii++)
			{
				$depmap{$results{record_id}[$ii]}[$iii]=$deps{record_id}[$iii];
			}
		}
	}

	for ( my ($ii) = 0 ; $ii < scalar( @{ $results{record_id} } ) ; $ii++ )
	{
		if( ($results{start_date}[$ii] eq '0000-00-00' || !$results{start_date}[$ii] || $results{start_date}[$ii] eq '') && $results{target_date}[$ii] ne '0000-00-00' && $results{target_date}[$ii] )
		{
			$results{start_date}[$ii]=$results{target_date}[$ii];
		}
		if( ($results{start_date}[$ii] eq '0000-00-00' || !$results{start_date}[$ii] || $results{start_date}[$ii] eq '') && ($results{target_date}[$ii] eq '0000-00-00' || !$results{target_date}[$ii] || $results{target_date}[$ii] eq '') )
		{
			$results{start_date}[$ii]='';
			$results{target_date}[$ii]='';
			unshift( @taskstarts, '' );
			unshift( @taskends,   '' );
		}
		else
		{
			# Calculate date range of all dates.
			if ( date2sec($results{start_date}[$ii]) < date2sec($earliest) )
			{
				$earliest = $results{start_date}[$ii];
			}
			if ( date2sec( $results{target_date}[$ii] ) > date2sec($farthest) )
			{
				$farthest = $results{target_date}[$ii];
			}

			# Populate task completion dates.
			my (@ended) = split '-', $results{target_date}[$ii];
			my ($endY)  = $ended[0];
			my ($endM)  = $ended[1];
			my ($endD)  = $ended[2];
	
			my (@begin) = split '-', $results{start_date}[$ii];
			my ($begY)  = $begin[0];
			my ($begM)  = $begin[1];
			my ($begD)  = $begin[2];
	
			# Populate task start/end dates. (basically creating an array with correctly formatted dates)
			unshift( @taskstarts, sprintf( '%-4.4d%-2.2d%-2.2d', $begY, $begM, $begD ) );
			unshift( @taskends,   sprintf( '%-4.4d%-2.2d%-2.2d', $endY, $endM, $endD ) );
		}

		# Populate tasks and completion.
		unshift( @tasks, ("$results{record_id}[$ii]: $results{short_desc}[$ii]") );
		unshift( @links,     $results{record_id}[$ii] );
		my($area)=$results{type}[$ii] . 'traq';
		if($results{status}[$ii] >= $c{$area}{resolved})
		{
			unshift( @completes, '1' );
		}
		else
		{
			unshift( @completes, $results{resolution}[$ii]/100 );
		}
	}

	# Determine how the gant chart will be broken down (days/weeks/months)
# 	if ( ( date2sec($farthest) - date2sec($earliest) ) < 3024000 )
# 	{
		$breakdown = 'days';
# 	}
	if($earliest eq '2022-02-02')
	{
		&doError("No dates found.");
	}
	@earliest = split '-', $earliest;
	@farthest = split '-', $farthest;
	my ( $starty, $startm, $startd ) = Monday_of_Week( Week_Number( $earliest[0], $earliest[1], $earliest[2] ), $earliest[0] );
	my ( $endy, $endm, $endd ) = Add_Delta_Days( Monday_of_Week( Week_Number( $farthest[0], $farthest[1], $farthest[2] ), $farthest[0] ), 6 );
	my($multiyear) = 0;
	my($monthstart) = $startm;
# 	if ( $breakdown eq 'days' )
# 	{
		my ($initd) = $startd;
		$y = $starty;
		for $y ( $starty ... $endy )
		{
			if($y eq $endy)
			{
				$loopmonth=$endm;
				if($multiyear)
				{
					$monthstart=1;
				}
			}
			else
			{
				$multiyear=1;
				$loopmonth=12;
			}
			for $m ( $monthstart ... $loopmonth )
			{
				if ( $m eq $endm && $y eq $endy)
				{
					$loopend = $endd;
				}
				else
				{
					$loopend = Days_in_Month( $y, $m );
				}
				for $d ( $initd ... $loopend )
				{
					push( @xticks, sprintf( '%-4.4d%-2.2d%-2.2d', $y, $m, $d ) );
					$dow = Day_of_Week_to_Text( Day_of_Week( $y, $m, $d ) );
					@dow = split '', $dow;
					if ( $dow[0] eq 'S' )
					{
						push( @xvalues, lc( $dow[0] ) );
					}
					else
					{
						push( @xvalues, uc( $dow[0] ) );
					}
					if ( Day_of_Week( $y, $m, $d ) eq 1 )
					{
						unless ( sprintf( '%-4.4d%-2.2d%-2.2d', $y, $m, $d ) eq sprintf( '%-4.4d%-2.2d%-2.2d', $starty, $startm, $startd ) )
						{
							push( @xbreaks, sprintf( '%-4.4d%-2.2d%-2.2d', $y, $m, $d ) );
						}
						push( @xbreaklabels, "Week of $m/$d" );
					}
				}
				if ( $initd eq $startd )
				{
					$initd = 1;
				}
			}
		}
		push( @xbreaks, sprintf( '%-4.4d%-2.2d%-2.2d', Add_Delta_Days( $endy, $endm, $endd, 1 ) ) );

		#@xbreaks = ('19990208','19990215','19990222','19990301');
		#@xbreaklabels = ('Week of 2/1','Week of 2/8','Week of 2/15','Week of 2/22');
# 	}

	if ( $startm eq $endm )
	{
		$xtitle = Month_to_Text($startm);
	}
	else
	{
		$xtitle = Month_to_Text($startm) . " $startd, $starty - " . Month_to_Text($endm) . " $endd, $endy";
	}
	$ytitle = "Task List";
	my ($linkpath) = "redir.cgi?queryid=$queryid&id=";
	my ($imagemap) = "gant";
		
	my ( $g0, $map0 ) = &GantChart(
		-xvals         => \@xvalues,                                                                   # x axis labels
		-tasks         => \@tasks,
		-title         => $xtitle,                                                                     # image title
		-titlecolor    => 'black',                                                                     # title font color
		-ytitle        => $ytitle,                                                                     # y-axis title
		-starttime     => sprintf( '%-4.4d%-2.2d%-2.2d', $starty, $startm, $startd ),
		-endtime       => sprintf( '%-4.4d%-2.2d%-2.2d', Add_Delta_Days( $endy, $endm, $endd, 1 ) ),
		-tmgn          => 10,                                                                          # top margin
		-bmgn          => 10,                                                                          # bottom margin
		-rmgn          => 10,                                                                          # right margin
		-lmgn          => 20,                                                                          # left margin
		-border        => 0,                                                                           # image border
		-bordercolor   => 'red',                                                                       # color of border
		-bgcolor       => 'snow', 		                                                               # backround color
		-axiscolor     => 'black',                                                                     #color of the axis bars.
		-headercolor   => 'black',
		-barcolors	   => \@{$results{highlightcolor}}, # color of font for x and y labels
		-xminlegendsiz => 160,
		-xticks        => \@xticks,                                                                    # x axis increments
		-xbreaks       => \@xbreaks,                                                                   # x axis sections
		-xtlegend      => \@xbreaklabels,                                                              # x axis section labels.
		-starttimes    => \@taskstarts,
		-endtimes      => \@taskends,
		-complete      => \@completes,
		-shadow        => 1,
		-linkpath      => $linkpath,
		-links         => \@links,
		-mapname       => $imagemap,
		-depmap        => \%depmap,
	);
	
	my(%debug)=(
		xvals         => \@xvalues,                                                                   # x axis labels
		tasks         => \@tasks,
		title         => $xtitle,                                                                     # image title
		titlecolor    => 'black',                                                                     # title font color
		ytitle        => $ytitle,                                                                     # y-axis title
		starttime     => sprintf( '%-4.4d%-2.2d%-2.2d', $starty, $startm, $startd ),
		endtime       => sprintf( '%-4.4d%-2.2d%-2.2d', Add_Delta_Days( $endy, $endm, $endd, 1 ) ),
		tmgn          => 10,                                                                          # top margin
		bmgn          => 10,                                                                          # bottom margin
		rmgn          => 10,                                                                          # right margin
		lmgn          => 20,                                                                          # left margin
		border        => 0,                                                                           # image border
		bordercolor   => 'red',                                                                       # color of border
		bgcolor       => 'snow', 		                                                               # backround color
		axiscolor     => 'black',                                                                     #color of the axis bars.
		headercolor   => 'black',                                                                     # color of font for x and y labels
		xminlegendsiz => 160,
		xticks        => \@xticks,                                                                    # x axis increments
		xbreaks       => \@xbreaks,                                                                   # x axis sections
		xtlegend      => \@xbreaklabels,                                                              # x axis section labels.
		starttimes    => \@taskstarts,
		endtimes      => \@taskends,
		complete      => \@completes,
		shadow        => 1,
		linkpath      => $linkpath,
		links         => \@links,
		mapname       => $imagemap
	);
	
#  	$results{DEBUG}[0]=&formatDataStructure(\@xticks,0,'gant params');
	if($gantimage)
	{
		print "Content-Type: image/jpeg\n";
		print "\n";
		print $g0->jpeg;
		&stopLog();
		exit;
	}

	$results{IMAGEMAP}[0]  = $map0;
	$results{GANTCHART}[0] = "./do_query.cgi?gant=1&gantimage=1&queryid=$queryid";

}
########################################################################
#  End Gant chart stuff
########################################################################

# Print output

print $q->header;

$results{LEGEND}[0]="";
for($m=0;$m<scalar(@{$c{query}{highlight}});$m++)
{
	$results{LEGEND}[0].="<p class=$c{query}{highlight}[$m][2]>$c{query}{highlight}[$m][3]</p>";
}


$results{FOOTER}[0] = &getFooter( $userid, 'traq' );
$results{'PISSROOT'}[0] = $c{'url'}{'base'};
$results{TITLE}[0] = ucfirst( $q->param('type') ) . " Query Results";
$results{TABLECLASS}[0]=$q->param('tableclass') || 'striped';
$results{HEADERCLASS}[0]=$q->param('headerclass') || 'form_header';


unless ( $results{VIEW}[0] )
{
	$results{VIEW}[0] = 'View';
}
$results{NUMRESULTS}[0]     = 0 + scalar( @{ $results{'record_id'} } );
$results{ASSIGNEDLABEL}[0]  = $c{general}{label}{assigned_to};
$results{STATUSLABEL}[0]    = $c{general}{label}{status};
$results{PRIORITYLABEL}[0]  = $c{general}{label}{priority};
$results{MILESTONELABEL}[0] = $c{general}{label}{target_milestone};
$results{TARGETLABEL}[0]    = $c{general}{label}{target_date};

if($c{query}{gantt})
{
	$results{GANTON1}[0]='';
	$results{GANTON2}[0]='';
}
else
{
	$results{GANTON1}[0]='<!--';
	$results{GANTON2}[0]='-->';
}

%results = &populateLabels( \%results, '' );

$resultstemplate=&getTemplateFile($c{dir}{generaltemplates},$resultstemplate,$userid);
$results{HEADER}[0]=&getHeader( $userid, "traq" ) unless $q->param('reportmode');
$html = Process( \%results, $resultstemplate );
&log("PRO total queries made: $c{cache}{totalqueries}") if $PRO;
$html =~ s/\n//;
if($q->param('tableonly') || $q->param('reportmode'))
{
    $html=~s/.*(<!--REPORT0-->.*<!--ENDREPORT0-->).*(<!--REPORT1-->.*<!--ENDREPORT1-->).*(<!--REPORT2-->.*<!--ENDREPORT2-->).*/$1$2$3/s;
    $html=~s/<!--EDIT-->.*?<!--ENDEDIT-->//sg;
}
print $html;

&stopLog();
exit;

#----------------------------------------------------------------------------------
###################################################################

sub getMenuHash()
{
	my ($type) = shift;
	my (%res)  = &doSql( "select * from traq_menus where rec_type like \"%$type%\" order by value" );
	my (@return);
	for ( my ($i) = 0 ; $i < scalar( @{ $res{'display_value'} } ) ; $i++ )
	{
		$return[ $res{'projectid'}[$i] ]{ $res{'menuname'}[$i] }{ $res{'value'}[$i] } = $res{'display_value'}[$i];
	}
	return @return;
}

sub chompPad()
{
	my ($val)   = shift;
	my ($field) = shift;
	my ($count) = 10;
	if (   $field eq "short_desc"
		|| $field eq "assigned_to"
		|| $field eq "qa_contact"
		|| $field eq "tech_contact"
		|| $field eq "reporter" )
	{
		$count = 20;
	}
	if ( $field eq "priority" )
	{
		$count = 4;
	}
	my (@letters) = split( //, $val );
	if ( @letters > $count )
	{
		@letters = splice( @letters, 0, $count );
		$val = join( "", @letters );
		return $val;
	}
	elsif ( @letters < $count )
	{
		my ($numspaces) = $count - scalar(@letters);
		for ( my ($i) = 1 ; $i <= $numspaces ; $i++ )
		{
			push( @letters, "&nbsp;" );
		}
		$val = join( "", @letters );
		return $val;
	}
	else
	{
		return $val;
	}
}

sub reverse()
{
	my ( $order, $userid, $queryid ) = @_;
	return unless $order;
	my (%res) = &doSql( "select sortorder from traq_queries where queryid=$queryid and userid=$userid" );
	if ( $res{sortorder}[0] =~ /ASC/i )
	{
		return $order . " DESC";
	}
	elsif ( $res{sortorder}[0] =~ /DESC/i )
	{
		return $order . " ASC";
	}
	else
	{
		return $order . " ASC";
	}

}

#############################################################
# Functions used to draw in hierarchal mode.
sub populateChildren
{
	my ($rec,$groupref,$lineage) = @_;
	my (@recordList,@idlist);
	&log("API: populateChildren for $rec",7);
	unless($lineage)
	{
		$lineage=$rec;
	}
	my (%children) = &getChildren($rec,$groupref);
	if($children{record_id})
	{
		for(my($ii)=0;$ii<scalar(@{ $children{'record_id'} });$ii++) # loop through children
		{
			my(%record,$key);
			foreach $key (keys(%children)) # push child hash onto record
			{
				$record{$key}=$children{$key}[$ii];
			}
			$record{lineage}=$lineage; # set lineage of child from query root
			%{$recordList[++$#recordList]}=%record; # add hash of record onto recordList
			if ( $children{'children'}[$ii] ) # if there are child records further down call self
			{
				my(@childrenlist)=&populateChildren($children{'record_id'}[$ii],$groupref,"$lineage-$children{'record_id'}[$ii]");
				my($newlength)=push( @recordList,  @childrenlist);
			}
		}
	}
	return @recordList;
}

sub hasChildren()
{
	my ($rec,$groupref)      = @_;
	my (%children) = &getChildren($rec,$groupref);
	return %children;
}

sub hasParents()
{
	my ($rec,$groupref)     = @_;
	my (%parents) = &getParents($rec,$groupref);
	return %parents;
}

sub date2sec
{
	my ($date) = @_;
	my (@date) = split '-', $date;
	if ( $date eq '0000-00-00' || !$date || $date eq '')
	{
		return;
	}
	return timelocal( 0, 0, 12, $date[2], ( $date[1] - 1 ), ( $date[0] - 1900 ) );
}

sub sec2date
{
	my ($sec) = @_;

	my ($tm)    = localtime($sec);
	my ($month) = $tm->mon;
	$month++;
	my ($year) = $tm->year;
	$year += 1900;

	my ($date) = $year . "-" . $month . "-" . $tm->mday;
	return $date;
}

