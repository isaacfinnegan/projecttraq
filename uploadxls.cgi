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
use CGI;
use MIME::Base64;
use TraqConfig;
use TraqXls qw(&parseExcelFile &xlsHashToTable $rowbegin);
use dbFunctions;
use supportingFunctions;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
&startLog();
my ($LOGGING) = 5;
my ($DEBUG)   = 1;

my ( %res, $projectID, $connection, $q, $userid, $fname, $val , $html,$item ,@col,%rec,$rowbegin);
my($ProjectID, $ComponentID,$type);
$q      = new CGI;
$DEBUG  = $q->param('debug');
$userid = &getUserId($q);
my ($id)      = $q->param('id');
my $spec      = $q->param('spec');
my ($mode)    = $q->param('mode');
my ($dryrun)  = $q->param('dryrun');
if($q->param('details'))
{
    $mode='';
}
my(@usergroups)=&getGroupsFromUserId($userid);
my($groupid)=&getGroupIdFromName('ExcelImporter');
unless(grep(/^$groupid$/,@usergroups))
{
	&doError("You do not have permission to use this function");
	exit;
}

$res{'ID'}[0] = $id;
unless($mode)
{
    my(%results,$file);
    my($dirname)=$c{dir}{home};
    my(@specs);
    opendir(DIR, $dirname) or die "can't opendir $dirname: $!";
    while (defined($file = readdir(DIR))) {
        if($file=~/spec/)
        {
            push(@specs,$file);
        }
    }
    closedir(DIR);


    $results{SPEC_OPTIONLIST}[0]=&makeOptionList(\@specs,\@specs);

    if($q->param('details'))
    {
        &log("DEBUG: processing spec",7);
        $results{SPEC}[0]=$spec;
        $spec = $TraqConfig::c{dir}{home} . "$spec";
        open( SPEC, $spec ) || die "cannot open spec file\n";
        my (@spec) = <SPEC>;
        eval "@spec";
        my($hh)='A';
        my($gg)=0;
        &log("ERROR: spec error: $@\n",1) if $@;
        &log("DEBUG: processing spec - $spec",7);
        for($gg=0;$gg<$#col;$gg++)
        {
            $results{COL}[$gg]=$hh;
            if($c{general}{label}{$col[$gg]})
            {
                $results{FIELDNAME}[$gg]=$c{general}{label}{$col[$gg]};
            }
            else
            {
                $results{FIELDNAME}[$gg]="Unused ( $col[$gg] )";
            }
            $hh++
        }
    }
    my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"uploadxls.tmpl",$userid);
	$results{PISSROOT}[0] = $c{url}{base};
	$results{FOOTER}[0] = &getFooter($userid, 'traq');
	$results{HEADER}[0] = &getHeader($userid, 'traq');
    $html = Process(\%results, $templatefile);
    print $q->header;
    print $html;
    exit;
}


if ( $mode eq "upload" )
{
    
    # Read in file from upload and dump into a tmpfile
	my ($file) = $q->param('FILE');
	my $url=$q->param('url');
	my $tmpfile;
	if($file) {
		$fname = $file;
		$fname =~ s/.*[\\\/](.+)$/$1/g;
	  $tmpfile = "/var/tmp/" . time() . "-$userid" . "-$fname";
		open TMP, ">$tmpfile";
		undef $/;
		my ($contents) = <$file>;
		binmode TMP;
		print TMP $contents;
		close TMP;
  }
  elsif($url) {
  	$tmpfile = "/var/tmp/" . time() . "-$userid". "-url";
  	system("/usr/bin/wget -O $tmpfile \"$url\"");
  }
  
    print $q->header;
  	my(%results,@recs,$rec,$html);
  	if( $dryrun )
  	{
        $results{OUTPUT}[0].= "<b>DRY RUN - Changes will not be commited to the database!</b><br>\n";
    }
    $results{OUTPUT}[0].= "<pre>\tFile uploaded - $tmpfile\n";
	my %xls = TraqXls::parseExcelFile( $tmpfile, $spec );
    

    #DEBUG Print out the file data as an html table 
    if($q->param('tableonly'))
    {
        print TraqXls::xlsHashToTable(%xls);
        if($q->param('tableonly'))
        {
            exit;
        }
	}
    $results{OUTPUT}[0].="<pre>\n";
	unlink($tmpfile) || warn "Cannot unlink tmmpfile\n";

	#my(@columns) = sort(keys(%xls));
	# Step through each row and upload/update into projecttraq database
	&log("TEST2",7);
	my($reccheck);
	for ( my $i = 0 ; $i < scalar( @{ $xls{incrementer} } ) ; $i++ )
	{
	   $rec='';
		if ($xls{incrementer}[$i] )
		{
        	$reccheck='';
			#print "Row $xls{incrementer}[$i]:\n";
			if($xls{ext_ref}[$i] || $xls{record_id}[$i])
			{
			     $reccheck=&existsXlsRecord( $i, \%xls, $DEBUG );
			}
			if ( $reccheck )
            {
                $results{OUTPUT}[0].= "Found id $reccheck\n";
            }
			if ( $reccheck) # don't do anything if dryrun
			{
				$rec=&updateXlsRecord( $i, \%xls ,,$reccheck,$userid,$dryrun,$DEBUG);
				$results{OUTPUT}[0].= "\tFor Row: $i  Record $xls{ext_ref}[$i] exists, updating $rec\n";
			}
			else
			{
				$rec=&createXlsRecord( $i, \%xls ,$dryrun,$DEBUG);
				$results{OUTPUT}[0].= "\tFor Row: $i  Record does not exist, creating... $rec\n";
			}
# 			if( $reccheck && $dryrun)
# 			{
# 				$results{OUTPUT}[0].= "\tRecord $xls{ext_ref}[$i] exists, will update $reccheck\n";
# 			}
# 			elsif( $dryrun)
# 			{
# 				$results{OUTPUT}[0].= "\tRecord does not exist, will create new record\n";
# 			}
		}

		if($rec)
		{
		  push(@recs,$rec);
		}
	}
	$results{OUTPUT}[0].="</pre>";
	if($dryrun)
	{
        $results{DRYBEGIN}[0]='<!--';
        $results{DRYEND}[0]='-->';
    }
	$results{UPLOADQUERY}[0]="do_query.cgi?task_id_type=include&record_id=". join(',',@recs) . "&return_bugs=1&return_tasks=1";
    my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},"processxls.tmpl",$userid);
	$results{PISSROOT}[0] = $c{url}{base};
	$results{FOOTER}[0] = &getFooter($userid, 'traq');
	$results{HEADER}[0] = &getHeader($userid, 'traq');
    $html = Process(\%results, $templatefile);
    print $q->header;
    print $html;
    
    &log("DEBUG: created record_ids: " . join(',',@{$xls{record_id}}),7);

	exit;
}

# Check for existing record with ext_ref in traq_records
sub existsXlsRecord
{
	my $i   = shift;
	my $xls = shift;
	my (%xls)=%{$xls};
	my($DEBUG)=shift;
	if ( $xls{record_id}[$i] )
	{
		#print "RecordId found\n";
		$xls{record_id}[$i] =~ s/.*?(\d+).*/$1/;
		$xls{record_id}[$i] =~ s/[bBtT]//;
		#print "$xls{record_id}[$i]" if $DEBUG;
		return $xls{record_id}[$i];
	}

	my $sql = "select record_id from traq_records where ext_ref='$xls{ext_ref}[$i]'";
    &log("DEBUG: $sql",7);
	my %res = &doSql($sql);

	if ( $res{record_id}[0] )
	{
		return $res{record_id}[0];
	}
	return 0;
}


sub updateXlsRecord
{
	my ($i,$xls,$record_id,$updater,$dryrun,$DEBUG)   = @_;
	my (%xls)=%{$xls};
		my (@keys) = grep( !/^_/, keys(%xls) );
	@keys = grep( !/^incrementer/, @keys );
	my $key;
	my $where;
    	&log("TEST1",7);
	if ( $xls{record_id}[$i] )
	{
		$xls{record_id}[$i] =~ s/.*?(\d+).*/$1/;
		$xls{record_id}[$i] =~ s/[BbtT]//;
		#print "Doing record_id where clause\n" if $DEBUG;
		$where = "record_id = '$xls{record_id}[$i]'";
	}
	else
	{
		$where = "ext_ref = '$xls{ext_ref}[$i]'";
	}
	&log("DEBUG: where clause: $where",7);
	foreach $key (@keys)
	{
        next if $key eq 'null';        
        next if $key eq 'long_desc';
        next if $key eq 'record_id';
        next if $key eq 'projectid';
        next if $key eq 'componentid';
        next if $key eq 'type';
        next unless $key =~ /.+/;
        $xls{$key}[$i] =~ s/'/`/g;
        $xls{$key}[$i] =~ s/"/`/g;
       #TODO make to use db_UpdateRecord 
        my $sql = "update traq_records set $key='$xls{$key}[$i]' where 
        $where";
    	&log("SQL: $sql",7);
        &doSql($sql) unless $dryrun;
    }

	my (@nonfields) = grep( /^_/, keys(%xls) );
	foreach $key (@nonfields)
	{
		print "$key = $xls{$key}[$i]\n";
		$xls{$key}[$i] =~ s/'/`/g;
		$xls{$key}[$i] =~ s/"/`/g;
		$xls{long_desc}[$i] .= "\n$key = $xls{$key}[$i]" unless $key eq 'null';
	}
	my $sql = "insert into traq_longdescs (record_id, who, thetext, date) values 
  	('$record_id', '$updater', '$xls{long_desc}[$i]', now())";
	&doSql($sql) unless $dryrun;
	print "$sql\n" if $DEBUG;
    return $record_id;
}

sub createXlsRecord
{
	my ($i,$xls,$dryrun,$DEBUG)     =@_;

    # add fields in the spec to the record hash
	my (@keys) = grep( !/^_/, keys(%$xls) );
	@keys = grep( !/^incrementer/, @keys );
	my($key,$k,$error);
    my(%record);
	if($$xls{projectid}[$i] !~ /\d+/ && $$xls{projectid}[$i])
	{
	   $record{projectid}=&getProjectIdFromName($$xls{projectid}[$i]);
	}
	foreach $key (@keys)
	{
        if($key eq 'parent' && $$xls{$key}[$i])
        {
			$record{parent} = $$xls{record_id}[ $$xls{parent}[$i] -1 ];
        }
        elsif($key eq 'projectid')
        {
            next;
        }
        else
        {
            $$xls{$key}[$i] =~ s/'/`/g;
            $$xls{$key}[$i] =~ s/"/`/g;
            $record{$key}=&getSmartField($key,$$xls{$key}[$i],$record{projectid}) unless ($key eq 'null');
        }
#TODO would like better error catching on smartfield parsing
#         if($record{$key} && $key!='null' && $key!='')
#         {
#             $error.="\nError resolving $c{general}{label}{$key} for $$xls{$key}[$i]";
#         }

	}
	$key='';
	# add all fields from spreadsheet that do not map to record fields into the long_desc
	my (@nonfields) = grep( /^_/, keys(%$xls) );
	&log("DEBUG: " . join('--',@nonfields),7);
	foreach $key (@nonfields)
	{
		$record{long_desc} .= "\n$key = $$xls{$key}[$i]";
	}
	# neutralize quotes
	$record{long_desc} =~ s/'/`/g;
	$record{long_desc} =~ s/"/`/g;
	if($record{componentid} !~ /\d+/ && $record{componentid})
	{
	   $record{componentid}=&getComponentFromValue($record{componentid},$record{projectid});
	}
	# process CC usernames into UID's
	if(${$xls}{cc}[$i]=~/\w/)
    {
    	delete $record{cc};
        @{$record{cc}}=split(',',${$xls}{cc}[$i]);
        &log("DEBUG: test2");
        my(@tmpcc);
        for($k=0;$k<scalar(@{$record{cc}});$k++)
        {
           my($tmpuid)=&getUserIDfromUsername($record{cc}[$k]);
           if($tmpuid && $tmpuid!='')
           {
               push(@tmpcc,$tmpuid);
           }
           else
           {
               $error.="\nError resolving username for $record{cc}[$k]";
           }
        }
        @{$record{cc}}=@tmpcc;
    }	
	# only set reporter to user if it isn't in the spreadsheet
	$record{reporter}=$userid unless $record{reporter};
#	&log("DEBUG: record data: " . join('.',%record), 7);
    if($dryrun)
    {
        my($pname)=&getProjectNameFromId($record{projectid});
        unless($pname)
        {
            $error.="\nError resolving $c{general}{label}{projectid}";
        }
        my($cname)=&getComponentNameFromId($record{componentid}) || 'ERROR';
        unless($cname)
        {
            $error.="\nError resolving $c{general}{label}{componentid}";
        }
        if($error)
        {
            return " ERROR: $error";
        }
        else
        {
            return "(new) for $c{general}{label}{projectid}: $pname and $c{general}{label}{componentid}: $cname"; 
        }
    }
    else
    {
        unless($record{componentid} && $record{projectid})
        {
           return;
        }
       my $newRecordId=&db_CreateRecord(\%record,$userid);
        $$xls{record_id}[$i]=$newRecordId;
        &log("DEBUG: created new record $newRecordId ($$xls{short_desc}[$i]) from excel file row: $i - $$xls{record_id}[$i]",7);
        return $newRecordId;
    }
}

