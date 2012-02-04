#!/usr/bin/perl

use lib "../lib";
use TraqConfig;
use Traqfields;
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use Date::Calc qw(:all);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;

my ( $NUMQUERIES, $LOGGING, $q, $userid, $status, %results, @recordlist, $sql,
     $key, $key2, $html, $xml, $html_or_xml, $i, $jj, $report_selection, @selections );
my (@chartcolors) = ("ff0000", "ff9900", "ffff00", "009900", "0000ff", "9966AA", "BBBBBB");
my ($rptTitle) = "";
my ($temptotal);
$NUMQUERIES = 0;
&startLog();
$LOGGING = 5;
my %results;
$q      = new CGI;
$userid = &getUserId($q);
my ($now) = localtime();

my ($mode)       = $q->param('mode') || "project";
my ($format)     = $q->param('format');
my ($reporttype) = $q->param('reporttype');
my ($text);
my (@type)      = $q->param('recordtype');
my ($datestart) = $q->param('start_date');
my ($datestop)  = $q->param('stop_date');
my ($xmlout) = $q->param('xmlout') || 0;
my ($chart) = $q->param('chart');


$datestart = &makeDate($datestart);
$datestop  = &makeDate($datestop);
my ($ydel)       = $q->param('ydelimit');
my ($xdel)       = $q->param('xdelimit');
my ($closed)     = $q->param('excludeclosed');
my ($staletype)     = $q->param('staletype');
my ($datedel)    = $q->param('datedelimit');
my (@usergroups) = my ($findcount) = $q->param('count_new');
my ($fixcount)   = $q->param('count_fix');
my ($closecount) = $q->param('count_closed');
my ($counttype)  = $q->param('recordcount') || 'count';

unless (    $reporttype ne 'activity'
         || $datestart =~ /^\d\d\d\d\-\d{1,2}\-\d{1,2}$/i
         || $datestop  =~ /^\d\d\d\d\-\d{1,2}\-\d{1,2}$/i )
{
    doError("Need to enter date values");
}

$results{'TIME'}[0] = localtime( time() );

if($chart && !$xmlout)
{
	my (%html,$templatefile);
	my $url=$ENV{REQUEST_URI};
	$url.="&xmlout=1";
	$url=~s/&/;/g;
	$html{URL}[0]=$url;
	$html{'PISSROOT'}[0] = $c{'url'}{'base'};

	$html{CHARTHEIGHT}[0]=$q->param('chartheight') || 400;
	$html{CHARTWIDTH}[0]=$q->param('chartwidth') || 650;
	if($q->param('chart'))
	{
		$html{CHARTTYPE}[0]= "$c{url}{base}/flash/Charts/" . $q->param('chart');
	}
	else
	{
		$html{CHARTTYPE}[0]= "$c{url}{base}/flash/Charts/FCF_MSColumn2D.swf";
	}
    $templatefile=&getTemplateFile( $c{dir}{reporttemplates}, "chart.tmpl", $userid );
	$html = Process( \%html, $templatefile );
	print $q->header;
	print $html;

	exit;
}


# Send headers for file download if comma delimited was chosen.
# Get record set to report on.
# Projects to report on
my (@projs) = $q->param('projectid');
my ($projectids);
if ( scalar(@projs) > 1 )
{
    $projectids = join( ',', @projs );
}
elsif ( scalar(@projs) eq 1 )
{
    $projectids = $projs[0];
}
my (@comps)   = $q->param('componentid');
my (@milestones)   = $q->param('target_milestone');
my($miles)=join(',',@milestones);
my ($compids) = join( ',', @comps );
my (@users)   = $q->param('users');
my ($queryid) = $q->param('queryid');
my ( $userids, $reclist );
if ( scalar(@users) > 1 )
{
    $userids = join( ',', @users );
}
elsif ( scalar(@users) eq 1 )
{
    $userids = $users[0];
}
if ($queryid)
{
    my ( $savedquerysql, $savedsortorder, $url_query_string ) =
      &getQuery( $queryid, $userid );
    my ($tmpq) = new CGI($url_query_string);
    $savedquerysql =
      &ConstructQuery( $tmpq, $userid, \@usergroups, 'record_id' );
    $savedquerysql =~ s/rec\.\*/rec\.record_id/g;
    my (%tmpresult) = &doSql($savedquerysql);
    $reclist = join( ',', @{ $tmpresult{record_id} } );
}

# Build sql for record set to report on
if ( $reporttype eq 'activity' )
{
    $sql = "select distinct rec.record_id,rec.type,rec.status";
    $sql .= ",act.newvalue,act.oldvalue,act.fieldname,act.date,act.who ";

    # add ydel
    unless ( $ydel eq 'who' )
    {
        $sql .= ",rec.$ydel ";
    }
    $sql .= " from traq_records rec ,traq_activity act ";
}
elsif ( $reporttype eq 'statistical' )
{
    $sql = "select distinct rec.projectid,rec.record_id,rec.type,rec.status";
    $sql .= ",rec.$xdel,rec.$ydel from traq_records rec ";
}
elsif ( $reporttype eq 'staleness' )
{
    $sql = "select distinct rec.projectid,rec.record_id,rec.type,rec.status";
    $sql .= ",rec.creation_ts,rec.delta_ts,rec.$ydel from traq_records rec ";
}
elsif ( $reporttype eq 'hour' )
{
    $sql = "select distinct rec.projectid,rec.record_id,rec.type,rec.status";
    $sql .= ",rec.units_req,rec.$ydel from traq_records rec ";
}
elsif ( $reporttype eq 'task_delinq' )
{
    $sql = "SELECT   rec.$ydel, COUNT( *) AS cnt_total_tasks
   , SUM( CASE
             WHEN rec.target_date = '0000-00-00'
                THEN 1
             ELSE 0
          END) AS cnt_td_null
   /*don't have hours remaining*/
     ,SUM( CASE
              WHEN rec.units_req = 0
                 THEN 1
              ELSE 0
           END) AS cnt_0hrs_rem
   /*not closed and more than 30 days delinquent */
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND curdate() - rec.target_date > 30
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_td_gt_30days_past
   /*not closed and 15 to 30 days delinquent */
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND curdate() - rec.target_date BETWEEN 15 AND 30
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_td_15_30days_past
   /*not closed and 8 to 14 days delinquent */
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND curdate() - rec.target_date BETWEEN 8 AND 14
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_td_8_14days_past
   /*not closed and 1 to 7 days delinquent */
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND curdate() - rec.target_date BETWEEN 1 AND 7
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_td_1_7days_past
   /*could be more than 7 days behind based on hours remaining*/
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND rec.units_req != 0
                    AND curdate() - rec.target_date - rec.units_req > 7
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_pos_gt_7day_behind
   /*could be more than 7 days behind based on hours remaining*/
     ,SUM( CASE
              WHEN (    (   NOT (rec.TYPE = 'bug' AND rec.status >= $c{bugtraq}{closethreshold})
                         OR NOT (rec.TYPE = 'task' AND rec.status >= $c{tasktraq}{closethreshold})
                        )
                    AND rec.target_date != '0000-00-00'
                    AND rec.units_req != 0
                    AND curdate() - rec.target_date - rec.units_req BETWEEN 1
                                                                    AND 7
                   )
                 THEN 1
              ELSE 0
           END
      ) AS cnt_pos_1_7day_behind
   , SUM( CASE
             WHEN rec.target_date >= curdate()
                THEN 1
             ELSE 0
          END) AS cnt_td_future
   , SUM( CASE
             WHEN rec.TYPE = 'bug' AND rec.status >= 11
                THEN 1
             WHEN rec.TYPE = 'task' AND rec.status >= 12
                THEN 1
             ELSE 0
          END
     ) AS cnt_completed_tasks
   , SUM( CASE
            WHEN x.td_change_cnt > 6
              THEN 1
            ELSE 0
          END
     ) AS cnt_task_7date_changes
from traq_records rec, 
(
select rec.record_id, count(act.record_id) as td_change_cnt
FROM traq_records rec left join traq_activity act on act.record_id=rec.record_id and act.fieldname='target_date'
GROUP BY rec.record_id
) x
"
}
$sql .= "where rec.record_id > 0 ";
if ($projectids)
{
    foreach $i (@projs)
    {
        push( @selections, &getProjectNameFromId($i) );
    }
    $sql .= " and rec.projectid in ($projectids) ";
}
if ($compids)
{
    foreach $i (@comps)
    {
        push( @selections, &supportingFunctions::getComponentNameFromId($i) );
    }
    $sql .= " and rec.componentid in ($compids) ";
}
if ($miles)
{
    foreach $i (@milestones)
    {
        push( @selections, &supportingFunctions::getMilestoneDisplayValue('',$i) );
    }
    $sql .= " and rec.target_milestone in ($miles) ";
}
if ($userids)
{
    foreach $i (@users)
    {
        push( @selections, &getNameFromId($i) );
    }
    if ( $reporttype eq 'activity' )
    {
        $sql .= " and act.who in ($userids) ";
    }
    else
    {
        $sql .= " and rec.assigned_to in ($userids) ";
    }
}
if ($queryid)
{
    $sql .= " and rec.record_id in ($reclist) ";
}
if ( $reporttype eq 'activity' )
{
    $report_selection = "Activity Report ($datestart - $datestop) -";
    $sql .=
" and act.record_id=rec.record_id and act.date < \"$datestop\" and act.date > \"$datestart\" order by act.date";
}
elsif ( $reporttype eq 'statistical' )
{
    $report_selection = "Statistic Report -";
    $sql .= " order by rec.record_id ";
}
elsif ( $reporttype eq 'staleness' )
{
    $report_selection = "Staleness Report -";
    $sql .= " order by rec.record_id ";
}
elsif ( $reporttype eq 'task_delinq' )
{
    $report_selection = "Target Date Status Report -";

    #If using saved query get record id's for this report
    if ( $q->param('qname') )
    {

        # get record set sql from saved query
        my ( $tmpsql, %tmpresults );
        my ($query_name) = $q->param('qname');
        my ($orderby)    = &getSavedOrderBy($userid);
        @selections = ( ( 'Saved Query: ' . substr( $query_name, 5 ) ) );
        $tmpsql = &getCannedQuery( $query_name, $orderby, $q, $userid );
        %tmpresults = secureRecordGet( $tmpsql, $userid );
        my (@tmpreclist) = @{ $tmpresults{record_id} };
        $sql .= " and rec.record_id in (" . join( ',', @tmpreclist ) . ") ";
    }

    $sql .=
      " and x.record_id=rec.record_id group by rec.$ydel order by 1, 2, 3 ";
}

# If saved query is being used, then use sql from that instead
if ( $q->param('qname') && $reporttype ne 'task_delinq' )
{

    # get record set sql from saved query
    my ($query_name) = $q->param('qname');
    my ($orderby)    = &getSavedOrderBy($userid);
    push( @selections, ( 'Saved Query: ' . substr( $query_name, 5 ) ) );
    $sql = &getCannedQuery( $query_name, $orderby, $q, $userid );
}
$report_selection .= " (" . join( ',', @selections ) . ")";

%results = secureRecordGet( $sql, $userid );

&log( "DEBUG: query returned columns: " . join( ',', keys(%results) ), 7 );

my ( %bugresults, %taskresults );

# Split results into hashes of task records and bug records
if ( $reporttype eq 'statistical' || $reporttype eq 'activity' )
{
    if (%results)
    {
        for ( $i = 0 ; $i < scalar( @{ $results{record_id} } ) ; $i++ )
        {
            foreach $key ( keys(%results) )
            {
                if ( $results{type}[$i] eq 'task' )
                {
                    push( @{ $taskresults{$key} }, $results{$key}[$i] );
                }
                if ( $results{type}[$i] eq 'bug' )
                {
                    push( @{ $bugresults{$key} }, $results{$key}[$i] );
                }
            }
        }
    }
}

$html .= '<LINK REL=stylesheet HREF="../traq.css" TYPE="text/css">';
$html .= '<b>' . $report_selection . '</b><br>';

#make tables or XMLs
if ( $reporttype eq 'statistical' )
{
    if ( grep( /bug/, @type ) )
    {
        $html .= "<br><b>Bug Report</b><br>";
		$rptTitle = "Bug Report";

        if (%bugresults)
        {
			
            $html_or_xml =
              makeStatReport( \%bugresults, $xdel, $ydel, 'bug', $closed,
                              $counttype, $xmlout, $rptTitle );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
			
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
    if ( grep( /task/, @type ) )
    {
        $html .= "<br><b>Task Report</b><br>";
		$rptTitle = "Task Report";
        if (%taskresults)
        {
            $html_or_xml  =
              makeStatReport( \%taskresults, $xdel, $ydel, 'task', $closed,
                              $counttype, $xmlout, $rptTitle );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
}
if ( $reporttype eq 'staleness' )
{
    if ( grep( /bug/, @type ) )
    {
        if (%results)
        {
            $html_or_xml  =
              makeStalenessReport( \%results, $xdel, $ydel, '', $staletype,
                              $counttype, $xmlout, $rptTitle );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
}
if ( $reporttype eq 'activity' )
{
    if ( grep( /bug/, @type ) )
    {
        $html .= "<br><b>Bug Report</b><br>";
		$rptTitle = "Bug Report";
        if (%bugresults)
        {
            $html_or_xml  = makeActReport(
                                    \%bugresults, $datedel,  $ydel,
                                    'bug',        $closed,   $counttype,
                                    $findcount,   $fixcount, $closecount,
                                    $datestart,   $datestop, $xmlout, $rptTitle
            );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
    if ( grep( /task/, @type ) )
    {
        $html .= "<br><b>Task Report</b><br>";
		$rptTitle = "Task Report";
        if (%taskresults)
        {
            $html_or_xml  = makeActReport(
                                    \%taskresults, $datedel,  $ydel,
                                    'task',        $closed,   $counttype,
                                    $findcount,    $fixcount, $closecount,
                                    $datestart,    $datestop, $xmlout, $rptTitle
            );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
}
if ( $reporttype eq 'task_delinq' )
{
    my (@returnfields) = (
                           'cnt_0hrs_rem',           'cnt_td_gt_30days_past',
                           'cnt_td_15_30days_past',  'cnt_td_8_14days_past',
                           'cnt_td_1_7days_past',    'cnt_pos_gt_7day_behind',
                           'cnt_pos_1_7day_behind',  'cnt_td_future',
                           'cnt_completed_tasks',    'cnt_total_tasks',
                           'cnt_task_7date_changes', 'cnt_td_null'
    );
    my ( $ii, $jj, %html );
    $html{ydellabel}[0] = $c{general}{label}{$ydel};
    for ( $jj = 0 ; $jj < scalar( @{ $results{cnt_total_tasks} } ) ; $jj++ )
    {
        $html{ydel}[$jj] =
          &getDisplayValue( $results{$ydel}[$jj], $ydel, 'task', '0' );
        foreach $ii (@returnfields)
        {
            $html{$ii}[$jj] = $results{$ii}[$jj];
        }
    }
    my ($templatefile) =
      &getTemplateFile( $c{dir}{reporttemplates}, "task_delinq.tmpl", $userid );
    $html = Process( \%html, $templatefile );

}
if ( $reporttype eq 'hour' )
{
    if ( grep( /bug/, @type ) )
    {
        $html .= "<br><b>Bug Report</b><br>";
		$rptTitle = "Bug Report";
        if (%bugresults)
        {
            $html_or_xml  = makeHourReport(
                                     \%bugresults, $datedel,  $ydel,
                                     'bug',        $closed,   $counttype,
                                     $findcount,   $fixcount, $closecount,
                                     $datestart,   $datestop, $xmlout, $rptTitle
            );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
    if ( grep( /task/, @type ) )
    {
        $html .= "<br><b>Task Report</b><br>";
		$rptTitle = "Task Report";
        if (%taskresults)
        {
            $html_or_xml  = makeHourReport(
                                     \%taskresults, $datedel,  $ydel,
                                     'task',        $closed,   $counttype,
                                     $findcount,    $fixcount, $closecount,
                                     $datestart,    $datestop, $xmlout, $rptTitle
            );
			if( $xmlout ne "1" ){
				$html .=$html_or_xml;
			}
        }
        else
        {
            $html .= "No records found to report on";
        }
    }
}

if( $xmlout eq "1" ){
	print "Content-type: text/plain\n\n";
}else{
	print $q->header;
}


if( $xmlout eq "1" ){
	#$html_or_xml = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>".$html_or_xml;
	print  $html_or_xml;
}else{
	print $html;
}
exit;

###################
###################

sub makeHourReport
{
    my (
         $recordsetref, $datedel,   $ydel,      $type,
         $closed,       $counttype, $findcount, $fixcount,
         $closecount,   $datestart, $datestop, $xmlout, $rptTitle
    ) = @_;
    my (%results) = %$recordsetref;
    my ( %report, $i, $jj );

# Setup columns beforehand since the column delimiter is time based and not field based
    my ( @columns, $row, $rowsize, $firstrow, $col );

    if ( $datedel eq 'none' )
    {
        @columns = ("$datestart");
    }
    if ( $datedel eq 'day' )
    {
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            my (@cycledate) = Add_Delta_Days( split( '-', $currdate ), 1 );
            $currdate = join( '-', @cycledate );
            push( @columns, join( '-', $currdate ) );
        }
    }
    if ( $datedel eq 'week' )
    {
        $jj = 1;
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            if ( $jj eq '7' )
            {
                $jj = 1;
                $currdate =
                  join( '-', Add_Delta_Days( split( '-', $currdate ), 7 ) );
                push( @columns, $currdate );
            }
            $jj++;
        }
    }
    if ( $datedel eq 'month' )
    {
        $jj = 0;
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            my (@currdate) = split( '-', $currdate );
            my (@cycledate) = Add_Delta_Days( split( '-', $currdate ), $i );
            if ( $currdate[1] ne $cycledate[1] )
            {
                $currdate = join( '-', @cycledate );
                push( @columns, join( '-', $currdate ) );
            }
        }
    }
    my ( %totals, $tick );

    # Calculate report hash
    for ( $i = 0 ; $i < scalar( @{ $results{record_id} } ) ; $i++ )
    {
        my (@recdate) = split( ' ', $results{target_date}[$i] );
        @recdate = split( '-', $recdate[0] );
        my ($area) = $results{type}[$i] . 'traq';
        for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
        {
            my ($tallyho);
            if ( !$columns[ $jj + 1 ]
                 && Delta_Days( split( '-', $columns[$jj] ), @recdate ) >= 0 )
            {
                $tallyho = 'yes';
            }
            elsif ( !$columns[ $jj + 1 ]
                    && Delta_Days( split( '-', $columns[$jj] ), @recdate ) < 0 )
            {
                $tallyho = 'no';
            }
            elsif (
                   Delta_Days( @recdate, split( '-', $columns[ $jj + 1 ] ) ) > 0
                   && Delta_Days( split( '-', $columns[$jj] ), @recdate ) >= 0 )
            {
                $tallyho = 'yes';
            }
            else
            {
                $tallyho = 'no';
            }
            if ( $tallyho eq 'yes' )
            {
                $report{ $results{$ydel}[$i] }{ $columns[$jj] }{recs}
                  { $results{record_id}[$i] }++;
                $report{ $results{$ydel}[$i] }{ $columns[$jj] }{Hours} +=
                  $results{units_req}[$i];
                $totals{ $columns[$jj] }{ $results{record_id}[$i] }++;
            }
        }
    }

    #draw column headings
    my ($output) = "<table cellspacing=0 cellpadding=2 class=";
    if ( $q->param('tableclass') )
    {
        $output .= $q->param('tableclass');
    }
    else
    {
        $output .= 'report';
    }
    $output .= "><tr><th>&nbsp;</th><th></th>\n";
    foreach $col (@columns)
    {
        $output .= "<th>$col</th>";
    }
    $output .= "<th class=reporttotal>Total</th></tr>";
    $rowsize = $findcount + $fixcount + $closecount;
    my ($temptotal);
    my ($total);

    #which stats to draw
    my ( @stats, $subrow );
    push( @stats, 'New' )      if $findcount;
    push( @stats, 'Resolved' ) if $fixcount;
    push( @stats, 'Closed' )   if $closecount;

    # draw report table
    my (@rows);
    if ( &isSystemMenu($ydel) )
    {
        my (%tmp) =
          &doSql(
"select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$ydel\" order by value asc"
          );
        @rows = @{ $tmp{value} };
    }
    else
    {
        @rows = keys(%report);
    }
    foreach $row (@rows)
    {
        $temptotal = 0;
        $firstrow  = 1;
        $output .= "<tr>\n" unless $firstrow;
        $output .=
          "<td>" . getDisplayValue( $row, $ydel, $type, '0' ) . "</td>";
        $output .= "<td class=reportdata>$subrow</td>";
        for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
        {
            $output .= "<td class=reportdata>";
            if ( $report{$row}{ $columns[$jj] }{$subrow} )
            {
                $output .= "<a href=\"$c{url}{base}/do_query.cgi?record_id="
                  . join( "%2C",
                          keys( %{ $report{$row}{ $columns[$jj] }{recs} } ) )
                  . "\">";
                $output .= $report{$row}{ $columns[$jj] }{Hours};
                $output .= "</a>";
                $temptotal = $temptotal + $report{$row}{ $columns[$jj] }{Hours};
            }
            $output .= "&nbsp;</td>\n";
        }
        $output .= "<td class=reporttotal>$temptotal</td>";
        $output .= "</tr>\n";

    }

    #Make bottom totals
    $total = 0;
    $output .= "<tr><td></td><td class=reporttotal>Total</td>\n";
    for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
    {
        $temptotal = 0;
        foreach $row ( keys(%report) )
        {
            foreach $subrow ( keys( %{ $report{$row}{ $columns[$jj] } } ) )
            {
                if ( $report{$row}{ $columns[$jj] }{$subrow} )
                {
                    $temptotal = $temptotal +
                      scalar(
                         keys( %{ $report{$row}{ $columns[$jj] }{$subrow} } ) );
                }
            }
        }

        #$output.="<td>$temptotal</td>";
        if ( $totals{ $columns[$jj] } )
        {
            $output .=
"<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
              . join( "%2C", keys( %{ $totals{ $columns[$jj] } } ) ) . "\">";
            $output .= scalar( keys( %{ $totals{ $columns[$jj] } } ) );
            $output .= "</a></td>\n";
            $total = $total + scalar( keys( %{ $totals{ $columns[$jj] } } ) );
        }
        else
        {
            $output .= "<td>&nbsp;</td>";
        }

    }
    $output .= "<td class=reporttotal>$total</td></tr>";
    $output .= "</table>";

    return $output;

}

sub makeActReport
{
    my (
         $recordsetref, $datedel,   $ydel,      $type,
         $closed,       $counttype, $findcount, $fixcount,
         $closecount,   $datestart, $datestop, $xmlout, $rptTitle
    ) = @_;
    my (%results) = %$recordsetref;
    my ( %report, $i, $jj , @pieces, $dispyear, $dispmonth);
		my ($year, @months, @weekDays, $curmonth, $curyear, @pieces, $dispyear, $dispmonth, $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings );

# Setup columns beforehand since the column delimiter is time based and not field based
    my ( @columns, $row, $rowsize, $firstrow, $col );

    if ( $datedel eq 'none' )
    {
        @columns = ("$datestart");
    }
    if ( $datedel eq 'day' )
    {
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i=0 ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            my (@cycledate) = Add_Delta_Days( split( '-', $currdate ), 1 );
            $currdate = join( '-', @cycledate );
            push( @columns, join( '-', $currdate ) );
        }
    }
    if ( $datedel eq 'week' )
    {
        $jj = 1;
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i=0 ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            if ( $jj eq '7' )
            {
                $jj = 1;
                $currdate =
                  join( '-', Add_Delta_Days( split( '-', $currdate ), 7 ) );
                push( @columns, $currdate );
            }
            else
            {
            	$jj++;
			}
        }
    }
    if ( $datedel eq 'month' )
    {
        $jj = 0;
        my ($currdate) = $datestart;
        push( @columns, $currdate );
        for ( $i=0 ;
              $i <
              Delta_Days( split( '-', $datestart ), split( '-', $datestop ) ) ;
              $i++ )
        {
            my (@currdate) = split( '-', $currdate );
            my (@cycledate) = Add_Delta_Days( split( '-', $datestart ), $i );
            if ( $currdate[1] ne $cycledate[1] )
            {
                $currdate = join( '-', @cycledate );
                push( @columns, join( '-', $currdate ) );
            }
        }
    }    
    my ( %totals, $tick );

    # Calculate report hash
    for ( $i = 0 ; $i < scalar( @{ $results{record_id} } ) ; $i++ )
    {
        my (@recdate) = split( ' ', $results{date}[$i] );
        @recdate = split( '-', $recdate[0] );
        my ($area) = $results{type}[$i] . 'traq';
        for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
        {
            my ($tallyho);
            if ( !$columns[ $jj + 1 ]
                 && Delta_Days( split( '-', $columns[$jj] ), @recdate ) >= 0 )
            {
                $tallyho = 'yes';
            }
            elsif ( !$columns[ $jj + 1 ]
                    && Delta_Days( split( '-', $columns[$jj] ), @recdate ) < 0 )
            {
                $tallyho = 'no';
            }
            elsif (
                   Delta_Days( @recdate, split( '-', $columns[ $jj + 1 ] ) ) > 0
                   && Delta_Days( split( '-', $columns[$jj] ), @recdate ) >= 0 )
            {
                $tallyho = 'yes';
            }
            else
            {
                $tallyho = 'no';
            }
            if ( $tallyho eq 'yes' )
            {
                if (    $results{fieldname}[$i] eq 'status'
                     && $results{newvalue}[$i] >= $c{$area}{closethreshold} )
                {
                    $report{ $results{$ydel}[$i] }{ $columns[$jj] }{Closed}
                      { $results{record_id}[$i] }++;
                    $tick++;
                }
                if (    $results{fieldname}[$i] eq 'status'
                     && $results{newvalue}[$i] >= $c{$area}{resolved}
                     && $results{newvalue}[$i] < $c{$area}{closethreshold} )
                {
                    $report{ $results{$ydel}[$i] }{ $columns[$jj] }{Resolved}
                      { $results{record_id}[$i] }++;
                    $tick++;
                }
                if ( $results{fieldname}[$i] eq 'record_id' )
                {
                    $report{ $results{$ydel}[$i] }{ $columns[$jj] }{New}
                      { $results{record_id}[$i] }++;
                    $tick++;
                }
                if ($tick)
                {
                    $totals{ $columns[$jj] }{ $results{record_id}[$i] }++;
                    $tick = 0;
                }
            }
        }
    }
	my ($output);
	my ($row2, $ll);
	my ($colorOffset) = 0;
	if( $xmlout ne "1" ){
	
	    #draw column headings
	    $output = "<table cellspacing=0 cellpadding=2 class=";
	    if ( $q->param('tableclass') )
	    {
	        $output .= $q->param('tableclass');
	    }
	    else
	    {
	        $output .= 'report';
	    }
	    $output .= "><tr><th>&nbsp;</th><th></th>\n";
	    foreach $col (@columns)
	    {
	        $output .= "<th>$col</th>";
	    }
	    $output .= "<th class=reporttotal>Total</th></tr>";
	}else{ # XML output
	
		$output = "\n<graph  caption=\"".$report_selection ." - ".$rptTitle."\" xAxisName='Date' yAxisName='Count'  shownames=\"1\" showvalues=\"0\" decimalPrecision=\"0\" numberPrefix=\"\" showSum=\"1\" useRoundEdges=\"1\" legendBorderAlpha=\"0\" labelDisplay='wrap' slantLabels='1' "; 
		if(scalar(@columns)>6)
		{
				$output.="rotateNames='1'>\n";
		}
		else
		{
				$output.=">\n";
		}
		$output.="<categories>\n";
		foreach (@columns)
		{
			$output.="<category name='$_'/>\n";
		}
		$output.="</categories>\n";

#$output .= "\n<styles><axis_category size='9' color='000099' alpha='0' font='verdana'  bold='false' skip='0' orientation='horizontal' />";
#$output .= "\n<axis_category size='9' color='dddddd' alpha='0' font='verdana'  bold='false' skip='0' orientation='horizontal' />";
#$output .= "\n<axis_ticks value_ticks='false' category_ticks='true' major_thickness='1' minor_thickness='1' minor_count='1' major_color='000000' minor_color='222222' position='outside' />";

#$output .= "\n</styles>";

	
		@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$year = 1900 + $yearOffset;

		#danger $output .= "<categories fontSize='9'>\n";
		$curyear = $year;  
		$curmonth = $month;  
		 foreach $col (@columns)
		 {
		 	#kluge fix. get current month and current year
			# do not display if col data > cur data
			@pieces = split("-", $col);
			$dispyear =  $pieces[0];  
			$dispmonth = $pieces[1]-1;  
		 }

	}

    $rowsize = $findcount + $fixcount + $closecount;
    my ($temptotal);
    my ($total);

    #which stats to draw
    my ( @stats, $subrow );
    push( @stats, 'New' )      if $findcount;
    push( @stats, 'Resolved' ) if $fixcount;
    push( @stats, 'Closed' )   if $closecount;

    # draw report table
    my (@rows);
    if ( &isSystemMenu($ydel) )
    {
        my (%tmp) =
          &doSql(
"select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$ydel\" order by value asc"
          );
        @rows = @{ $tmp{value} };
    }
    else
    {
        @rows = keys(%report);
    }
	

	
    foreach $row (@rows)
    {
        $temptotal = 0;
	
		
		if( $xmlout ne "1" ){
        	$output .=
          "<td rowspan=$rowsize>"
          . getDisplayValue( $row, $ydel, $type, '0' ) . "</td>";
		 }
        $firstrow = 1;
        foreach $subrow (@stats)
        {
			if( $xmlout ne "1" ){
            	$output .= "<tr>\n" unless $firstrow;
			}
			else
			{
				$output.="<dataset seriesname='$subrow' color='$chartcolors[$colorOffset]'>\n";
			}
            $firstrow  = 0;
            $temptotal = 0;
			if( $xmlout ne "1" ){
            	$output .= "<td class=reportdata>$subrow</td>";
			}
	
            for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
            {
										  
			 	@pieces = split("-", $columns[$jj]);
				$dispyear =  $pieces[0];  
				$dispmonth = $pieces[1]-1;  
			
				if( $xmlout ne "1" ){
                	$output .= "<td class=reportdata>";
				}
				else
				{
						$output.="<set link='$c{url}{base}/do_query.cgi?record_id=" . join("%2C", keys(  %{ $report{$row}{ $columns[$jj] }{$subrow}}))  . "'";
						$output.=" value='" . scalar(keys(  %{ $report{$row}{ $columns[$jj] }{$subrow}} )) . "' />\n";
				}
																																																									                                       
                if ( $counttype eq 'count' )
                {
                    if ( $report{$row}{ $columns[$jj] }{$subrow} )
                    {
						if( $xmlout ne "1" ){
                        $output .=
                          "<a href=\"$c{url}{base}/do_query.cgi?record_id="
                          . join(
                                  "%2C",
                                  keys(
                                        %{
                                            $report{$row}{ $columns[$jj] }{$subrow}
                                          }
                                  )
                          ) . "\">";
                        $output .=
                          scalar(
                                keys(
                                    %{ $report{$row}{ $columns[$jj] }{$subrow} }
                                )
                          );
						  
                        $output .= "</a>";
						}
						
                        $temptotal =
                          $temptotal + scalar(
                                keys(
                                    %{ $report{$row}{ $columns[$jj] }{$subrow} }
                                )
                          );
                    }
                }
                elsif ( $counttype eq 'list' )
                {
                    if ( $report{$row}{ $columns[$jj] }{$subrow} )
                    {
                        foreach $col (
                                sort { $a <=> $b }
                                keys(
                                    %{ $report{$row}{ $columns[$jj] }{$subrow} }
                                )
                          )
                        {
							if( $xmlout ne "1" ){
                            	$output .=
"<a href=\"$c{url}{base}/redir.cgi?id=$col\">$col</a> ";
							}
                        }
                        $temptotal =
                          $temptotal + scalar(
                                keys(
                                    %{ $report{$row}{ $columns[$jj] }{$subrow} }
                                )
                          );
						  
                    }
                }
				if( $xmlout ne "1" ){
                	$output .= "&nbsp;</td>\n";
				}
            }
			if( $xmlout ne "1" ){
            	$output .= "<td class=reporttotal>$temptotal</td>";
            	$output .= "</tr>\n";
			}
			if( $xmlout eq "1" ){
				$colorOffset ++;
				$colorOffset ++;
				$output.="</dataset>\n";
			}
        }

    }

    #Make bottom totals
    $total = 0;
	if( $xmlout ne "1" ){
   	 $output .= "<tr><td></td><td class=reporttotal>Total</td>\n";
	}
    for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
    {
        $temptotal = 0;
        foreach $row ( keys(%report) )
        {
            foreach $subrow ( keys( %{ $report{$row}{ $columns[$jj] } } ) )
            {
                if ( $report{$row}{ $columns[$jj] }{$subrow} )
                {
                    $temptotal = $temptotal +
                      scalar(
                         keys( %{ $report{$row}{ $columns[$jj] }{$subrow} } ) );
                }
            }
        }

        #$output.="<td>$temptotal</td>";
        if ( $totals{ $columns[$jj] } )
        {
			if( $xmlout ne "1" ){
         	   $output .=
"<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
              . join( "%2C", keys( %{ $totals{ $columns[$jj] } } ) ) . "\">";
         	   $output .= scalar( keys( %{ $totals{ $columns[$jj] } } ) );
         	   $output .= "</a></td>\n";
			}
			elsif(0){ 
			
				@pieces = split("-", $columns[$jj]);
				$output .= "<set label=\"" .$columns[$jj]  . "\" ";
				$output .=  " value=\"".scalar( keys( %{ $totals{ $columns[$jj] } } ) )."\"  />\n";

								
			}
            $total = $total + scalar( keys( %{ $totals{ $columns[$jj] } } ) );
        }
        else
        {
			if( $xmlout ne "1" ){
            	$output .= "<td>&nbsp;</td>";
			}else{
				@pieces = split("-", $columns[$jj]);
				$dispyear =  $pieces[0];  
				$dispmonth = $pieces[1]-1; 
					if( $dispyear <= $curyear ){
								
						if( (($curyear == $dispyear) && ( $curmonth >= $dispmonth)) ){
							$output .= "<set label=\"" .$columns[$jj]  . "\" ";
							$output .=  " value=\"0\"  />\n";
						}
					}
			}
        }

    }
	if( $xmlout ne "1" ){
	    $output .= "<td class=reporttotal>$total</td></tr>";
	    $output .= "</table>";
	}else{
		 $output .= "</graph>";
	}

    return $output;

}

sub makeStatReport
{
    my ( $recordsetref, $xdel, $ydel, $type, $closed, $counttype, $xmlout, $rptTitle ) = @_;
    my (%results) = %$recordsetref;
    my ( %report, $i, $jj );
	my(%proj);
    # count the records
    for ( $i = 0 ; $i < scalar( @{ $results{record_id} } ) ; $i++ )
    {
        my ($area) = $type . 'traq';
        unless ( $closed && $results{status}[$i] >= $c{$area}{closethreshold} )
        {
            push(
                  @{ $report{ $results{$ydel}[$i] }{ $results{$xdel}[$i] } },
                  $results{record_id}[$i]
            );
            $proj{$results{projectid}[$i]}++;
        }
    }
    my($projects)=join(',',keys(%proj));

    my ($col);
    my ($row);
    my (@columns);

    # determine columns/rows for report
    if ( &isSystemMenu($xdel) )
    {
        my (%tmp) =
          &doSql(
"select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$xdel\""
          );
        @columns = @{ $tmp{value} };
    }
    else
    {
        foreach $key ( keys(%report) )
        {
            foreach $key2 ( keys( %{ $report{$key} } ) )
            {
                unless ( grep( /$key2/, @columns ) )
                {
                    push( @columns, $key2 );
                }
            }
        }
    }
    @columns = sort { $a <=> $b } @columns;
    if ( grep ( /$xdel/, split( ',', $c{general}{rolemenu} ) )
         || $xdel eq 'target_milestone' )
    {
        @columns = sort
        {
            &getDisplayValue( $a, $xdel, $type, '0' )
              cmp &getDisplayValue( $b, $xdel, $type, '0' )
        } @columns;
    }
    elsif ( $xdel eq 'target_date' || $xdel eq 'start_date' )
    {
        @columns = sort { $a cmp $b } @columns;
    }
    else
    {
        @columns = sort { $a <=> $b } @columns;
    }
    my (@rows);
    if ( &isSystemMenu($ydel) )
    {
        my (%tmp) =
          &doSql(
"select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$ydel\""
          );
        @rows = @{ $tmp{value} };
    }
    else
    {
        @rows = keys(%report);
    }
    if ( grep ( /$ydel/, split( ',', $c{general}{rolemenu} ) )
         || $ydel eq 'target_milestone' )
    {
        @rows = sort
        {
            &getDisplayValue( $a, $ydel, $type, '0' )
              cmp &getDisplayValue( $b, $ydel, $type, '0' )
        } @rows;
    }
    elsif ( $ydel eq 'target_date' || $ydel eq 'start_date' )
    {
        @rows = sort { $a cmp $b } @rows;
    }
    else
    {
        @rows = sort { 		if ( $a =~ /^-?\d+$/ && $b =~ /^-?\d+$/ )
							{
								$a <=> $b;
							}
							else
							{
								lc($a) cmp lc($b);
							}
				 } @rows;
    }

    #generate HTML from reporthash
	my ($output);
		my ($row2, $ll);
	my ($colorOffset) = 0;
	if( $xmlout ne "1" ){
	    $output = "<table cellspacing=0 cellpadding=2 class=";
	    if ( $q->param('tableclass') )
	    {
	        $output .= $q->param('tableclass');
	    }
	    else
	    {
	        $output .= 'report';
	    }
	    $output .= ">\n";
	
	    #make top row labels
	    $output .= "<tr><th>&nbsp;</th>\n";
	    for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
	    {
	        $output .= "<th>"
	          . getDisplayValue( $columns[$jj], $xdel, $type, $projects ) . "</th>";
	    }
	    $output .= "<th class=reporttotal>Total</th></tr>";
	}else{ # XML output
	
		$output = "\n<graph decimalPrecision=\"0\" caption=\"$report_selection - $rptTitle\" xAxisName=\"$c{general}{label}{$ydel} - $c{general}{label}{$xdel}\" yAxisName=\"Count\"  shownames=\"1\" showValues=\"0\" >\n";

		$output .= "<categories fontSize=\"9\">\n";
		foreach $row (@rows)
    	{	
			 $output .= "<category name=\"" . getDisplayValue( $row, $ydel, $type, $projects ) . "\"/>\n";
		}
		$output .= "</categories>\n";
		
		for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ ){
			$output .= "<dataset seriesName=\"".getDisplayValue( $columns[$jj], $xdel, $type, $projects ) . "\" color=\"".$chartcolors[$colorOffset]."\" showValues=\"0\">\n";
			foreach $row2 (@rows){
				for ( $ll = 0 ; $ll < scalar(@columns) ; $ll=$ll+scalar(@columns) ){
			 		if ( $report{$row2}{ $columns[$jj] } ){
						$output .=  "<set value=\"".scalar( @{ $report{$row2}{ $columns[$jj] } })."\"";
						$output .= " link=\"$c{url}{base}/do_query.cgi?record_id=" . join("%2C",@{$report{$row2}{ $columns[$jj] } } ) . "\" ";
						$output .= "/>\n";
					}else{
						$output .=  "<set value=\"0\" />\n";
					}
				}
			}
			$colorOffset ++;
	       $output .= "</dataset>\n";
	    }
		
	}

    # make data rows
    my (@temptotal);
    my ($total);
	
	my ($name );
    foreach $row (@rows)
    {
        my (@temptotal);
		if( $xmlout ne "1" ){
       		 $output .= "<tr>\n";
       		 $output .=
       		   "<td>" . getDisplayValue( $row, $ydel, $type, $projects ) . "</td>";
		}
        for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
        {
			if( $xmlout ne "1" ){
           		 $output .= "<td class=reportdata>";
			}
            if ( $counttype eq 'count' )
            {
                if ( $report{$row}{ $columns[$jj] } )
                {
					if( $xmlout ne "1" ){
	                    $output .=
	                        "<a href=\"$c{url}{base}/do_query.cgi?record_id="
	                      . join( "%2C", @{ $report{$row}{ $columns[$jj] } } )
	                      . "\">";
                   		 $output .= scalar( @{ $report{$row}{ $columns[$jj] } } );
                    	$output .= "</a>";
					}
                    push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );
                }
            }
            elsif ( $counttype eq 'list' )
            {
                if ( $report{$row}{ $columns[$jj] } )
                {
                    foreach $col ( sort { $a <=> $b }
                                   @{ $report{$row}{ $columns[$jj] } } )
                    {
						if( $xmlout ne "1" ){
	                        $output .=
	"<a href=\"$c{url}{base}/redir.cgi?id=$col\">$col</a> ";
						}
                    }
                    push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );
                }
            }
			if( $xmlout ne "1" ){
           	 $output .= "&nbsp;</td>\n";
			}
        }
		if( $xmlout ne "1" ){
	        $output .=
	"<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
	          . join( "%2C", @temptotal ) . "\">";
	        $output .= scalar(@temptotal) . "</a></td>";
	        $output .= "</tr>\n";
		}
        $total = $total + scalar(@temptotal);
    }

    #Make bottom totals
	if( $xmlout ne "1" ){
    	$output .= "<tr><td class=reporttotal>Total</td>\n";
	}
    for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
    {
        my (@temptotal);
        foreach $row ( keys(%report) )
        {
            if ( $report{$row}{ $columns[$jj] } )
            {

               #$temptotal=$temptotal + scalar(@{$report{$row}{$columns[$jj]}});
                push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );

            }
        }
		if( $xmlout ne "1" ){
        	$output .=
"<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
          . join( "%2C", @temptotal ) . "\">";
        	$output .= scalar(@temptotal) . "</a></td>";
		}
    }
	if( $xmlout ne "1" ){
	   	 $output .= "<td class=reporttotal>$total</td></tr>";
	    $output .= "</table>";
	}else{
		#temp remove $output .= "<grandtotal>".$total."</grandtotal></bottomtotalrow>";
		 $output .= "</graph>\n";
	}
    return $output;
}

sub makeStalenessReport
{
    my ( $recordsetref, $xdel, $ydel, $type, $stalefield, $counttype , $xmlout, $rptTitle) = @_;
    my (%results) = %$recordsetref;
    my ( %report, $i, $jj, $delta );
    #setup time
	my @today = &Date::Calc::Today();
    &log("DEBUG: Executing staleness reccount: $#{$results{record_id}} , for $stalefield ");
###########
    # count the records
    for ( $i = 0 ; $i < scalar( @{ $results{record_id} } ) ; $i++ )
    {
        my ($area) = $results{type}[$i] . 'traq';
        if ( $results{status}[$i] < $c{$area}{closethreshold} )
        {
            # get date delta information
            my(@tmp);
            if($stalefield eq 'delta_ts' && $results{$stalefield}[$i])
            {
                @tmp=split(' ',$results{$stalefield}[$i]);
            }
            else
            {
                @tmp=split(' ',$results{'creation_ts'}[$i]);
            }
            my(@recdate)=split('-',$tmp[0]);
            $delta=&Delta_Days($recdate[0],$recdate[1],$recdate[2],$today[0],$today[1],$today[2]);
            if($delta >30)
            {
                push(@{ $report{ $results{$ydel}[$i] }{'30 days or longer'}},  $results{record_id}[$i] );
            }
            if($delta <= 30 && $delta >7)
            {
                push(@{ $report{ $results{$ydel}[$i] }{'7 - 30 days'}},$results{record_id}[$i] );
            }
            if($delta < 7)
            {
                push(@{ $report{ $results{$ydel}[$i] }{'less than 7 days'}},  $results{record_id}[$i] );
            }
#            push(@{ $report{ $results{$ydel}[$i] }{'total'}}, $results{record_id}[$i] );
            $report{ $results{$ydel}[$i] }{'score'}=$report{ $results{$ydel}[$i] }{'score'} + $delta;
        }
    }
#    &log("DEBUG: proccessed summary data:" . scalar(@{ $report{ $results{$ydel}[$i] }{'total'}}) . " rows");
###########
    my ($col);
    my ($row);
    my (@columns)=('30 days or longer','7 - 30 days','less than 7 days');

    # determine columns/rows for report
#     if ( &isSystemMenu($xdel) )
#     {
#         my (%tmp) =
#           &doSql(
# "select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$xdel\""
#           );
#         @columns = @{ $tmp{value} };
#     }
#     else
#     {
#         foreach $key ( keys(%report) )
#         {
#             foreach $key2 ( keys( %{ $report{$key} } ) )
#             {
#                 unless ( grep( /$key2/, @columns ) )
#                 {
#                     push( @columns, $key2 );
#                 }
#             }
#         }
#     }
#     @columns = sort { $a <=> $b } @columns;
#     if ( grep ( /$xdel/, split( ',', $c{general}{rolemenu} ) )
#          || $xdel eq 'target_milestone' )
#     {
#         @columns = sort
#         {
#             &getDisplayValue( $a, $xdel, $type, '0' )
#               cmp &getDisplayValue( $b, $xdel, $type, '0' )
#         } @columns;
#     }
#     elsif ( $xdel eq 'target_date' || $xdel eq 'start_date' )
#     {
#         @columns = sort { $a cmp $b } @columns;
#     }
#     else
#     {
#         @columns = sort { $a <=> $b } @columns;
#     }
    my (@rows);
    if ( &isSystemMenu($ydel) )
    {
        my (%tmp) =
          &doSql(
"select value from traq_menus where project=0 and rec_type like \"%$type%\" and menuname=\"$ydel\""
          );
        @rows = @{ $tmp{value} };
    }
    else
    {
        @rows = keys(%report);
    }
    if ( grep ( /$ydel/, split( ',', $c{general}{rolemenu} ) )
         || $ydel eq 'target_milestone' )
    {
        @rows = sort
        {
            &getDisplayValue( $a, $ydel, $type, '0' )
              cmp &getDisplayValue( $b, $ydel, $type, '0' )
        } @rows;
    }
    elsif ( $ydel eq 'target_date' || $ydel eq 'start_date' )
    {
        @rows = sort { $a cmp $b } @rows;
    }
    else
    {
        @rows = sort { $a <=> $b } @rows;
    }

    #generate HTML from reporthash

    my ($output) = "<table cellspacing=0 cellpadding=2 class=";
    if ( $q->param('tableclass') )
    {
        $output .= $q->param('tableclass');
    }
    else
    {
        $output .= 'report';
    }
    $output .= ">\n";

    #make top row labels
    $output .= "<tr><th>&nbsp;$c{general}{label}{$ydel}</th>\n";
    for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
    {
        $output .= "<th>"
          . getDisplayValue( $columns[$jj], $xdel, $type, '0' ) . "</th>";
    }
    $output .= "<th class=reporttotal>Total</th><th class='reporttotal score'>Score (issues * days open)</th></tr>";

    # make data rows
    my (@temptotal);
    my ($total);
    foreach $row (@rows)
    {
        my (@temptotal);
        $output .= "<tr>\n";
        $output .=
          "<td align=right>" . getDisplayValue( $row, $ydel, $type, '0' ) . "</td>";
        for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
        {
            $output .= "<td class=reportdata>";
            if ( $counttype eq 'count' )
            {
                if ( $report{$row}{ $columns[$jj] } )
                {
                    $output .=
                        "<a href=\"$c{url}{base}/do_query.cgi?record_id="
                      . join( "%2C", @{ $report{$row}{ $columns[$jj] } } )
                      . "\">";
                    $output .= scalar( @{ $report{$row}{ $columns[$jj] } } );
                    $output .= "</a>";
                    push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );
                }
            }
            elsif ( $counttype eq 'list' )
            {
                if ( $report{$row}{ $columns[$jj] } )
                {
                    foreach $col ( sort { $a <=> $b }
                                   @{ $report{$row}{ $columns[$jj] } } )
                    {
                        $output .=
"<a href=\"$c{url}{base}/redir.cgi?id=$col\">$col</a> ";
                    }
                    push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );
                }
            }
            $output .= "&nbsp;</td>\n";
        }
        $output .=
"<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
          . join( "%2C", @temptotal ) . "\">";
        $output .= scalar(@temptotal) . "</a></td>";
        $output .= "<td class=score>$report{ $row }{'score'}  </td>";
        $output .= "</tr>\n";
        $total = $total + scalar(@temptotal);
    }

    #Make bottom totals
#     $output .= "<tr><td class=reporttotal>Total</td>\n";
#     for ( $jj = 0 ; $jj < scalar(@columns) ; $jj++ )
#     {
#         my (@temptotal);
#         foreach $row ( keys(%report) )
#         {
#             if ( $report{$row}{ $columns[$jj] } )
#             {
# 
#                #$temptotal=$temptotal + scalar(@{$report{$row}{$columns[$jj]}});
#                 push( @temptotal, @{ $report{$row}{ $columns[$jj] } } );
# 
#             }
#         }
#         $output .=
# "<td class=reporttotal><a href=\"$c{url}{base}/do_query.cgi?record_id="
#           . join( "%2C", @temptotal ) . "\">";
#         $output .= scalar(@temptotal) . "</a></td>";
#     }
#     $output .= "<td class=reporttotal>$total</td></tr>";
    $output .= "</table>";
    return $output;
}






