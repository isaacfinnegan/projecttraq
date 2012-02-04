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

package TraqXls;
use strict;
use Exporter;
use Spreadsheet::ParseExcel;
use supportingFunctions;
use vars qw(
  @col
  @EXPORT
);
@EXPORT = qw(&parseExcelFile);
use Date::Calc;
use TraqConfig;
use vars qw(%c);
local (*c) = \%TraqConfig::c;

#parseExcelFile();
my ( $iR, $iC, $oWkS, $oWkC );

# Print out an xls hash result as an html table
sub xlsHashToTable
{
	print "HashtoTable\n</pre>";
	my %xls = @_;
	my (@keys) = sort( keys(%xls) );
	print "<table border=1>";
	print "<tr>";
	my $key;
	foreach $key (@keys) { print "<td>$key</td>"; }
	print "</tr>";

	for ( my $i = 0 ; $i < scalar( @{ $xls{incrementer} } ) ; $i++ )
	{
		print "<tr>\n";
		my $key;
		foreach $key (@keys)
		{
			print "<td>$xls{$key}[$i]</td>";
		}
		print "</tr>\n";
	}
	print "</table>";
}

# read in excel file and specfile and parse spreadsheet into hash structure
sub parseExcelFile
{
	my (%ss, $flg1904);
	my $datefmt = 'yyyy-mm-dd';    # ISO 8601
	my ($file)     = shift || '../test.xls';
	my ($specfile) = shift;                    # ||  '../samsung-a820xls.spec';
	$specfile = $TraqConfig::c{dir}{home} . "$specfile";
	my ( $ProjectID, $ComponentID, $rowbegin, %rec, $target_project, $colend ,$yy,$empty);
	open( SPEC, $specfile ) || die "cannot open spec file\n";
	my (@spec) = <SPEC>;
	eval "@spec";
	my $excelObj = new Spreadsheet::ParseExcel;
	my $oBook    = $excelObj->Parse("$file");
	if($oBook->{Flg1904} || $oBook->{Flag1904})
	{
		$flg1904=1;
	}
	for ( my $iSheet = 0 ; $iSheet < $oBook->{SheetCount} ; $iSheet++ )
	{
		$oWkS = $oBook->{Worksheet}[$iSheet];

		#print "--------- SHEET:", $oWkS->{Name}, "\n";
		for ( my $iR = $oWkS->{MinRow} ; defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++ )
		{
		    $empty=0;
		    
			#parsing row
			next unless $iR >= $rowbegin;
			if(%rec)
			{
                foreach $yy (keys(%rec))
                {
                    $ss{$yy}[$iR]=$rec{$yy};
                }
            }
            $ss{incrementer}[$iR]=$iR;
			for ( my $iC = $oWkS->{MinCol} ; defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ; $iC++ )
			{
                #parsing each field in row                
                last if $iC > $#col;
                $oWkC = $oWkS->{Cells}[$iR][$iC];
                if( $oWkC->{Type} eq 'Date')
                {
                    $ss{ $col[$iC] }[$iR] = &Spreadsheet::ParseExcel::Utility::ExcelFmt($datefmt,$oWkC->{Val},$flg1904);
				}
                else
                {
	                $ss{ $col[$iC] }[$iR] = $oWkC->{Val};
                }
                $empty++ if $oWkC->{Val};
            }

            # exit if last row had no data
			last unless $empty;
		}
	}

	#print $ss{ext_ref}[3];
	return %ss;
}
return 1;

