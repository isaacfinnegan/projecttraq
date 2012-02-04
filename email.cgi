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
local(*c) = \%TraqConfig::c;
use CatchErrors qw($c{email}{webmaster});

&startLog();

my(%html,$html,$q,%users,$grp,$DEBUG,$userid,%groups,%res,$tmp);

$q=new CGI;

$DEBUG = $q->param('debug');
$userid = &getUserId($q);

#TODO update to allow project/group admins to send to groups they admin
unless(&isAdministrator($userid))
{
	&doError("Only a system admin may use this function");
	exit;
}

if($q->param('send'))
{
	my($address)=$q->param('addresses');
	my(@addresses)=split(/,/,$address);
	my $addr;
	foreach $addr (@addresses) {
	$addr=~ s/\n//g;
	&sendMail(	$addr,
				$q->param('from'),
				$q->param('subject'),
				$q->param('message'),
				$q->param('from')
				);
	}
	print $q->header;
	print "<html><body>Email Sent</body></html>";
	exit;
}

$grp=$q->param('group');
$html{PISSROOT}[0]=$c{url}{base};
$html{GRP}[0]=$grp;
$html{FROM}[0]=$c{email}{webmaster};
my($grpselect)=$grp.'_selected';
$html{$grpselect}[0]='selected';
%res=&doSql("select groupid,groupname from groups where groupname not like '%-owners' order by groupname asc");

%html=&mergeHashes(%res,%html);

if($grp && $grp eq 'all_users')
{
	%users=&doSql("select username,email from logins where email!='' order by email");
	$html{ADDRESSES}[0]=join(",\n",@{$users{email}});
	$html{all_users_selected}[0]='selected';
}
elsif($grp)
{
	%users=&doSql("select l.username,l.email from logins l, user_groups ug where email!='' and l.userid=ug.userid and ug.groupid=$grp order by email");
	$html{ADDRESSES}[0]=join(",\n",@{$users{email}});
	for(my($i)=0;$i<scalar(@{$html{groupid}});$i++)
	{
		if($grp eq $html{groupid}[$i])
		{
			$html{selected}[$i]='selected';
		}
		else
		{
			$html{selected}[$i]='';
		}
	}
}


my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'email.tmpl',$userid);
$html{FOOTER}[0] = &getFooter($userid, 'traq');
$html{HEADER}[0] = &getHeader($userid, 'traq');
$html=&Process(\%html,$templatefile);

print $q->header;
print $html; 
exit;