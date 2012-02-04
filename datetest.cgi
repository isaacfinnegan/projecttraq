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
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});

my($headersent) = 0;
my(%clear);
%{$c{cache}}=%clear;

&startLog();
my($LOGGING) = 5;

my($date,$q);
$q = new CGI;

print $q->header();
if($q->param('string'))
{
    $date=$q->param('string');
}

print "<html>
<head>
<title>Plain Text Date Tester</title>
</head>
<body>
<center>
<table style='border:1 px solid black;' cellpadding=2 cellspacing=0 border=0>
<tr><td align=center>
Enter a string to test for date conversion<br>
<form name='datetest' action=datetest.cgi method=get>
<input name=string type=text size=25 value='$date'><input type=submit value=Test>
</form>
Output:
<div style='border:1px solix black;'><pre>
";

if($date)
{
    print &makeDate($date);
}

print '
</pre></div><p/>

</td>
</tr>
<tr>
<td>
<font size=-1>
Examples:
<pre>
 Miscellaneous other allowed formats are:
 which dofw in mmm in YY      "first sunday in june
                              1996 at 14:00" **
 dofw week num YY             "sunday week 22 1995" **
 which dofw YY                "22nd sunday at noon" **
 dofw which week YY           "sunday 22nd week in
                              1996" **
 next/last dofw               "next friday at noon"
 next/last week/month         "next month"
 in num days/weeks/months     "in 3 weeks at 12:00"
 num days/weeks/months later  "3 weeks later"
 num days/weeks/months ago    "3 weeks ago"
 dofw in num week             "Friday in 2 weeks"
 in num weeks dofw            "in 2 weeks on friday"
 dofw num week ago            "Friday 2 weeks ago"
 num week ago dofw            "2 weeks ago friday"
 last day in mmm in YY        "last day of October"
 dofw                         "Friday" (Friday of
                              current week)
 Nth                          "12th", "1st" (day of
                              current month)
 epoch SECS                   seconds since the epoch
                              (negative values are
                              supported) 
</pre>
</font>
</td>
</tr>
</table>
</body></html>';

