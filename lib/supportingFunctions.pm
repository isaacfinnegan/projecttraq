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
package supportingFunctions;

use Exporter ();
use strict;
use vars qw(
  $VERSION
  @ISA
  @EXPORT
  @EXPORT_TAGS
  @EXPORT_OK);
@ISA    = qw(Exporter);
@EXPORT = qw(&getDefaultQa
  &getUserIDfromUsername
  &getTemplateFile
  &getGroupIdFromName
  &getGroupsFromUserId
  &db_CreateRecord
  &db_GetRecordField
  &db_UpdateRecord
  &db_addChild
  &makeDate
  &getComponentidCC
  &getProjectidCC
  &process_file_upload
  &date2time
  &getUserOptionList
  &populateUserCache
  &populateMenuCache
  &populateMilestoneCache
  &populateProjectCache
  &populateComponentCache
  &time_now
  &bogusChangeCheck
  &getAttachments
  &isCreateAuthorized
  &mergeResults
  &verifyDependencies
  &db_GetUserHashforProject
  &db_GetRecord
  &getDefaultTech
  &getDefaultProjectQa
  &getDefaultProjectTech
  &getParents
  &getChildren
  &populateHeaderFooter
  &getFooter
  &getHeader
  &startLog
  &log
  &stopLog
  &makeMysqlTimestamp
  &getUserId
  &getProjectNameFromId
  &getLongDesc
  &getRecordGroups
  &getComponentGroups
  &getNameFromId
  &getNamesFromIds
  &getGroupsFromEmployeeId
  &getGroupsFromUnixName
  &getEmployeeIdFromUnixName
  &getEmployeeIdFromName
  &getEmployeeList
  &getCCList
  &getMenu
  &getComponents
  &getRecordCcs
  &doError
  &updateLongDesc
  &deleteCc
  &insertNewCc
  &updateRecord
  &getRecord
  &getMenuDisplayValue
  &makeActivityEntry
  &makePrettyTimestamp
  &addRecordNote
  &getSmartField
  &getMenuValue
  &getRecordType
  &getNamedQuery
  &getNamedQueries
  &saveNamedQuery
  &deleteNamedQuery
  &saveTemplate
  &getTemplates
  &getTemplate
  &saveResults
  &getResults
  &getMilestoneDisplayValue
  &getMilestones
  &isEditAuthorized
  &escapeQuotes
  &unEscapeQuotes
  &escapeHtml
  &getMailPrefs
  &sendMail
  &getNumAttachments
  &saveReturnFields
  &getSavedReturnFields
  &getReturnFields
  &getKeywords
  &getRecordKeywords
  &getProjectBuildIds
  &ReadConfig
  &getSavedOrderBy
  &GetQueryName
  &GetPrevNextResults
  &GetCookieValue
  &EncodeForCookie
  &DecodeFromCookie
  &ConvertMultiples
  &ConstructQuery
  &ProcessBooleans
  &ProcessBoolean
  &AnyWords
  &NoWords
  &AllNumbers
  &AllWords
  &SeparateMenus
  &GetMenus
  &GetEmployeeList
  &GetUserProjects
  &GetJustUserRecords
  &GetUserGroups
  &GetProjectComponents
  &GetUserComponents
  &GetMilestones
  &GetVersions
  &getSmartValue
  &getComponentFromValue
  &getComponentNameFromId
  &getProjectIdFromName
  &isProjectOwner
  &getProjectOwnerGroup
  &getReporter
  &isReporter
  &getServices
  &getAuthorizedProjects
  &getEmail
  &getUserDetails
  &isAdministrator
  &canEditField
  &mergeHashes
  &isValidRecord
  &isGroupAdmin
  &isProjectAdmin
  &getProjectName
  &getProjectGroups
  &getNewQueryId
  &getQuery
  &saveQuery
  &getPreferredOrder
  &getLastChangedBy
  &isActive
  &basicHashto64
  &basicHashfrom64
  &secureRecordGet
  &makeJs
  &getHeader
  &date2sec
  &sec2date
  &getLastNote
  &emailConfirmation
  &getFieldLabel
  &formatDataStructure
  &printDataStructure
  &validateId
  &validateUsername
  &makeOptionList
  &getMenuOptionList
  &makeSessionCookie
  &getSessionCookie
  &setSessionCookie
  &populateLabels
  &getCannedQuery
  &getDisplayValue
  &makeUserOptionList
  &isSystemMenu
  &validateEmail
);
our %EXPORT_TAGS = ( ALL => [ @EXPORT, @EXPORT_OK ] );

use DataProc qw(&Process);
use Traqfields;
use TraqConfig;
use CGI;
use dbFunctions;
use vars qw(%c);
*c = \%TraqConfig::c;
use Mail::Sendmail;
use URI::Escape;
use MIME::Base64;
use Crypt::Blowfish;
use Crypt::CBC;
use Date::Calc;
use Date::Manip;
#use Storable qw(&nfreeze &thaw);
use JSON;  # replaced Stoarable with JSON calls
use Data::Dumper;
my ( $userid, $DEBUG );
if ( $c{debug} )
{
	eval "use Data::Dumper";
}
if ( $c{logging}{usesyslog} )
{
	eval 'use Sys::Syslog qw(:DEFAULT setlogsock)';
}
if ( $c{cache}{usecache} )
{
	eval 'use Cache::FileCache qw(all)';
}
##############################################################
sub getDefaultQa
{
	my ($id) = @_;
	if ( $c{cache}{usecache} )
	{
		unless ($id)
		{
			return '';
		}
		my ($lookup) = "component=$id=initialqacontact";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "component-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&populateComponentCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select initialqacontact from traq_components where componentid=$id";
		my (%res) = &doSql($sql);
		return $res{'initialqacontact'}[0];
	}
}
##############################################################
sub getDefaultTech
{
	my ($id) = @_;
	if ( $c{cache}{usecache} )
	{
		unless ($id)
		{
			return '';
		}
		my ($lookup) = "component=$id=initialowner";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "component-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&populateComponentCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select initialowner from traq_components where componentid=$id";
		my (%res) = &doSql($sql);
		return $res{'initialowner'}[0];
	}
}
##############################################################
sub getDefaultProjectQa
{
	my ($pid) = @_;
	my ($sql) = "select default_qa from traq_project where projectid=$pid";
	my (%res) = &doSql($sql);
	return $res{'default_qa'}[0];
}
##############################################################
sub getDefaultProjectTech
{
	my ($pid) = @_;
	my ($sql) = "select default_dev from traq_project where projectid=$pid";
	my (%res) = &doSql($sql);
	return $res{'default_dev'}[0];
}
##############################################################

sub getParents
{
	my ( $id, $groupref ) = @_;
	my ($grouplist) = join( ',', @$groupref );
	my ($sql) =
"select distinct dep.*,rec.type,rec.status,rec.record_id from acl_traq_records acl, traq_dependencies dep, traq_records rec where dep.blocked=rec.record_id and dep.dependson=$id and acl.record_id=rec.record_id and acl.groupid in ($grouplist)";
	my (%res) = &doSql($sql);
	return %res;
}

##############################################################
sub getChildren
{
	my ( $id, $groupref ) = @_;
	my ($grouplist) = join( ',', @$groupref );
	my ($sql) =
"select distinct rec.*,dep.*,count(lkupdep.dependson) as children from acl_traq_records acl, traq_dependencies dep, traq_records rec left join traq_dependencies lkupdep on lkupdep.blocked=rec.record_id where dep.blocked=$id and dep.dependson=rec.record_id and acl.record_id=rec.record_id and acl.groupid in ($grouplist) group by rec.record_id";
	my (%res) = &doSql($sql);
	return %res;
}
##############################################################
sub populateHeaderFooter
{
}

sub getFooter
{
	my ($q)    = new CGI;
	my ($html) = "";
	unless ( !$c{general}{footer} || $q->param('footer') eq '0' )
	{
		my ( $userid, $type ) = @_;
		my (%res) = &getNamedQueries( $userid, "" );
		$type = $type || "traq";
		my ($area);
		if ( $type eq 'traq' )
		{
			$area = '';
		}
		%res = &populateLabels( \%res, $area );
		$res{DOQUERY}[0]  = $c{url}{doquery};
		$res{BASE}[0]     = $c{url}{base};
		$res{USERNAME}[0] = getNameFromId( $userid, 'username' );
		$res{FULLNAME}[0] = getNameFromId($userid);
		my ($template) = "footer-" . $type . ".tmpl";
		$template=&getTemplateFile($c{dir}{footers},$template,$userid);
		$html = &Process( \%res, $template );
	}
	if ( $q->param('debug') )
	{
        $html.="<hr>Javascript Debug:<br><TEXTAREA COLS=80 ROWS=24 ID=debug></TEXTAREA><br><SPAN style='text-decoration:underline; color:blue;cursor:pointer;' ONCLICK='eval(document.getElementById(\"debug\").value);'>Evaluate javascript in above textarea</span>\n<hr>";
		foreach ( keys(%ENV) )
		{
			$html .= "$_ : $ENV{$_}<br>\n";
		}
	}
	return $html;
}
###############################################################
sub getHeader
{
	my ($q) = new CGI;
	if ( !$c{general}{header} || $q->param('header') eq '0' )
	{
		return "";
	}
	my ( $userid, $type ) = @_;
	my ( %res, %res2, $length );
	%res  = &getNamedQueries( $userid, "" );
	%res2 = &getTemplates( $userid,    "" );
	$type = $type || "traq";
	if (%res)
	{

		for ( my ($i) = 0 ; $i < scalar( @{ $res{userid} } ) ; $i++ )
		{
			$res{DOQUERY}[$i]  = $c{url}{doquery};
			$res{name}[$i] =~ s/'/`/g;
			$res{NAME_ESC}[$i] = uri_escape( $res{name}[$i] );
			$res{QUERYURL}[$i] = $c{url}{base} . '/' . $res{url}[$i];
			$res{QUERYURL}[$i] =~ s/queryname=.+?[&;]//;
			$length = length( $res{name}[$i] ) if ( $length < length( $res{name}[$i] ) );
		}
	}
	$res{USERID}[0]    = $userid;
	$res{QUERYSIZE}[0] = ( $length + 5 ) * 6;
	$length            = 0;
	$res{DOQUERY}[0]   = $c{url}{doquery};
	if (%res2)
	{
		for ( my ($i) = 0 ; $i < scalar( @{ $res2{category} } ) ; $i++ )
		{
			$res{TYPE}[$i]     = $res2{type}[$i];
			$res{TEMPNAME}[$i] = $res2{name}[$i];
			$res{BASE}[$i]     = $c{url}{base};
			$res{USER}[$i]     = $res2{category}[$i];
			$length = length( $res{TEMPNAME}[$i] ) if ( $length < length( $res{TEMPNAME}[$i] ) );
		}
	}

	$res{TEMPLATESIZE}[0] = ( $length + 10 ) * 6;
	$res{BASE}[0]         = $c{url}{base};
	$res{TASKTRAQ}[0]     = $c{url}{task};
	$res{BUGTRAQ}[0]      = $c{url}{bug};
	$res{USERNAME}[0]     = getNameFromId( $userid, 'username' );
	$res{FULLNAME}[0]     = getNameFromId($userid);
	my ($area);
	if ( $type eq 'traq' )
	{
		$area = '';
	}
	%res = &populateLabels( \%res, $area );
	my ($template) = "header-" . $type . ".tmpl";
    $template=&getTemplateFile($c{dir}{headers},$template,$userid);
	my $html = &Process( \%res, $template );
	return $html;
}

##############################################################
sub startLog
{
	if ( $c{logging}{usesyslog} )
	{
		setlogsock('unix');
		my (@name) = split( /\//, $0 );
		my ($size) = scalar(@name);
		$size--;
		my ($prog) = $name[$size];

		#openlog("$prog\[$$\]", '', '');
		openlog( "$prog", 'cons,pid', 'user' );
	}
	if ( $c{logging}{useapache} )
	{
	}
}
##############################################################
sub log
{
	my ( $string, $level ) = @_;
	if ( $c{'logging'}{'usesyslog'} )
	{
		if ( $level <= $c{logging}{loglevel} )
		{
			syslog( 'info', "[piss][user:$main::userid] $string" );
		}
	}
	if ( $c{logging}{useapacheerror} )
	{
		print STDERR "$string\n";
	}
}
##############################################################
sub stopLog
{
	if ( $c{logging}{usesyslog} )
	{
		closelog();
	}
}
##############################################################
sub makeMysqlTimestamp
{
	my ($time) = @_;
	my (@now)  = localtime($time);
	$now[5] += 1900;
	$now[4] += 1;
	$now[4] =~ s/\b(\d)\b/0$1/;
	$now[3] =~ s/\b(\d)\b/0$1/;
	$now[2] =~ s/\b(\d)\b/0$1/;
	$now[1] =~ s/\b(\d)\b/0$1/;
	$now[0] =~ s/\b(\d)\b/0$1/;
	my ($timestring) = $now[5] . $now[4] . $now[3] . $now[2] . $now[1] . $now[0];
	return $timestring;

}
##############################################################
sub makeSessionCookie
{
	my ($hashref) = @_;
	my (%session) = %{$hashref};

	$session{timestamp} = time();
	my ($session) = to_json( \%session);

	#	my($key) = pack("H16", "0123456789ABCDEF");
	my ($key)    = $c{session}{key};
	my ($cipher) = Crypt::CBC->new($key,'Blowfish');

	my ($encrypted_session) = $cipher->encrypt($session);
	$encrypted_session = encode_base64($encrypted_session);

	return $encrypted_session;
}
##############################################################
sub getSessionCookie
{
	my ($session) = @_;
	my ($cgi)     = new CGI;
	my ($id)      = $cgi->param('id');
	my ($key)     = $c{session}{key};
	my ($cipher) = Crypt::CBC->new($key,'Blowfish');

	eval { $session=decode_base64($session) };
	my ($decrypted_session) = $cipher->decrypt($session);
	my (%session_info);
	eval { %session_info = %{ from_json( $decrypted_session ) } };
	if ($@)
	{
		&log("ERROR: eval for session_info failed: $@", 5);
		print $cgi->redirect("$c{url}{loginpage}?id=$id");
		exit;
	}

	# kick out if session is too old
	unless ( ( time() - ( $session_info{timestamp} ) ) < $c{session}{timeout} )
	{
		print $cgi->redirect("$c{url}{loginpage}?id=$id");
		exit;
	}

	return %session_info;
}
##############################################################
sub setSessionCookie
{
	my ( $q, $username ) = @_;
	my (%session);
	$session{username} = $username;
	my ($session_data)   = makeSessionCookie( \%session );
	my ($session_cookie) = $q->cookie(
		-name    => 'session',
		-value   => "$session_data",
		-expires => "+$c{session}{timeout}",
		-path    => '/',
	);
	print $q->header( -cookie => [$session_cookie] );
	&log( "DEBUG: user session created", 5 );
}

##############################################################
sub getUserId
{
	my ($cgi)     = @_;
	my $oruser = $cgi->param('oruser');
	my $orpasswd = $cgi->param('orpasswd');
	my $oruserid = $cgi->param('oruserid');
	my ($cname)   = $cgi->cookie('cname');
	my ($cpass)   = $cgi->cookie('cpwd');
	my ($session) = $cgi->cookie('pt_session');
	my ($id)      = $cgi->param('id') || '';
	my ( $passreturn, $error, $ldap, $mesg, $result );
	if ( $c{profile} && $cgi->param('testuser') )
	{
		return $cgi->param('testuser');
	}
	&log( "USER: got cname and cpass cookies: $cname xxxxx", 5 );
&log("USER: looking for override", 5);
if($oruser && $orpasswd) {
	if($oruser eq "$c{tasktraq}{oruser}" && $orpasswd eq "$c{tasktraq}{orpasswd}") {
		&log("Got override user and password: $oruser eq $c{tasktraq}{oruser} $orpasswd  $c{tasktraq}{orpasswd}\n");
		&log("override user: $oruserid\n");
		return $oruserid;
	}
}
	# Use external access function to get username if config
	if ( $c{externalaccess}{useoutsideLogin} )
	{
		$cname = &TraqConfig::outsideLogin($cgi);
		return &getEmployeeIdFromUnixName($cname);
	}

	# Check for session cookie and extract user info
	if ( $session && $c{session}{enable} )
	{
		my (%session_info) = getSessionCookie($session);
		my ($userid) = &getEmployeeIdFromUnixName( $session_info{username}, 1 );
		if ( $userid eq 'INACTIVE' )
		{
			print $cgi->redirect("$c{url}{loginpage}?id=$id");
			exit;
		}

		#		&setSessionCookie($cgi,$session_info{username});
		return $userid;
	}

	if ( $c{externalaccess}{allowvisitor} )
	{
		if ( $cgi->cookie('cname') eq 'visitor' || $cgi->param('visitor') )
		{
			&setSessionCookie( $cgi, 'visitor' );
			my ($userid) = &getEmployeeIdFromUnixName('visitor') || 0;
			return $userid;
		}
	}

	# Redirect to login page if cname or session do not exist.
	unless ( ( $cname && $cpass ) || $session )
	{
		print $cgi->redirect("$c{url}{loginpage}?req=$ENV{REQUEST_URI}");
		exit;
	}

	# Try to bind to ldap server as user to do authentication via LDAP if config
	if ( $c{ldap}{ldapauth} && $cname )
	{
		$ldap = Net::LDAP->new( $c{ldap}{server} ) or die "$@"; 
		if($c{ldap}{authbind})
		{
			$mesg=$ldap->bind($c{ldap}{authbind}, password=> $c{ldap}{authpass});
			$mesg->code &&	&doError("initial bind" . $mesg->error);
		}
		else
		{
			$mesg=$ldap->bind;
			$mesg->code &&	&doError("anonymous bind" . $mesg->error);
			
		}
		$mesg=$ldap->search(base=> $c{ldap}{basedn}, filter=>"($c{ldap}{userattr}=$cname)");
		$mesg->code &&	&doError($mesg->error);
		my(@entries)=$mesg->entries;
		my($binddn)=$entries[0]->dn();
		&log("AUTH: LDAP user $cname found: $binddn",7);
		$mesg = $ldap->bind( $binddn, password => $cpass );
		if($mesg->code)
		{
			&log("AUTH: LDAP login failed for $cname",1);
		}
		else
		{
			&log("AUTH: LDAP login success for $cname",7);
			$passreturn = $cpass;
		}
	}

	# Otherwise, just use internal database to verify password.  (this shouldn't be used much anymore)
	# function should have already returned
	else
	{
		my (%res) = &doSql("select password from $c{db}{logintable} where $c{db}{logintablename}=\"$cname\"");
		&log( "USER: getting password from db $res{'password'}[0]", 5 );
		$passreturn = $res{password}[0];
	}

	# when password is correct proceed
	if ( $cpass eq $passreturn )
	{

		# get userid from database
		my ($userid) = &getEmployeeIdFromUnixName($cname);
		unless ($userid)
		{
			&log("SYS: no user found in user table");

			# auto create user if config
			if ( $c{ldap}{autocreate} && $c{ldap}{ldapauth} )
			{
				$result = $ldap->search(
					base   => $c{ldap}{basedn},
					filter => "(&(uid=$cname))"
				);
				$result->code && print "failed to view entry: " . $result->error;
				my (@entries) = $result->entries;
				my ($entry)   = $entries[0];
				my ($attr)    = $entry->get('cn');
				$attr =~ /(\S*)\s(\S*)/g;
				my ($first)   = $1;
				my ($last)    = $entry->get('sn');
				my ($email)   = $entry->get('mail');
				my ($user_id) = $entry->get('uidNumber');
				$userid = $user_id;

				unless ( &validateId($userid) )
				{
					&doError(
						"Error: Unable to create account with that userid in the database.
						<br>Please contact the system administrator.
						<br><a href=\"$c{url}{base}/logout.cgi\">Logout and try again</a>
						"
					);
					exit;
				}
				unless ( &validateUsername($cname) )
				{
					&doError(
						"Error: Unable to create account with that username in the database.
						<br>Please contact the system administrator.
						<br><a href=\"$c{url}{base}/logout.cgi\">Logout and try again</a>
						"
					);
					exit;
				}
				my ($sql) = "insert into logins (username, userid, first_name, last_name, email, password,";
				$sql .= "bugtraqprefs, returnfields, active, recordeditprivs,order1) values (\"$cname\", $user_id, \"$first\", \"$last\", ";
				$sql .= "\"$email\", \"ldap\", \"$c{useraccount}{prefs}\", \"$c{useraccount}{returnfields}\", \"Yes\", \"$c{useraccount}{editprivs}\",\"status asc\")";
				&log("SQL: $sql",7);
				&doSql($sql);
				$sql = "insert into user_groups set userid=$user_id, groupid=3";
				&log("SQL: $sql",7);
				&doSql($sql);

				if ( $c{ldap}{autogroup} )
				{
					my ($sql) = "insert into user_groups set userid=$userid, groupid=$c{ldap}{autogroup}";
					&log("SQL: $sql",7);
					&doSql($sql);
				}
				&log("USER: user auto-created after successful LDAP authentication (userid=$user_id)");
			}
			else
			{
				&doError(
					"Error: There is no account with that username in the database.
					<br>Please contact the system administrator.
					<br><a href=\"$c{url}{base}/logout.cgi\">Logout and try again</a>
					"
				);
			}

		}
		&setSessionCookie( $cgi, $cname );
		return $userid;
	}
	else
	{
		print $cgi->redirect("$c{url}{loginpage}?id=$id");
		exit;
	}
}
##############################################################
sub getProjectNameFromId
{
	my ($id,$err) = @_;
	unless ($id)
	{
		return '';
	}
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "project=$id=name";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "project-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&populateProjectCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select project from traq_project where projectid=$id";
		my (%res) = &doSql($sql);
		unless (%res)
		{
		    if($err)
		    {
		      $err="Error getting project name for $id";
		      return $err;
		    }
		    else
		    {
    			&doError( "Error getting project name for $id", $sql );
		    }
		}
		return ${ $res{'project'} }[0];
	}
}
##############################################################
sub getLongDesc
{
	my ( $recid, $plain ,$returnitem,$recref,$userid) = @_;
	my ($sql) = "select * from traq_longdescs where record_id=$recid order by date";
	my (%res) = &doSql($sql);
	my($type,$foo,$pid,%rec,$act,$area);
	my(@rolemenu)=split(',',$c{general}{rolemenu});
	push(@rolemenu,'who');
	my(@systemmenu)=split(',',$c{general}{systemmenu});
	if($recref)
	{
	   $act=1;
    }
	unless (%res)
	{
		return '';
	}
	my ( $line, $ret, $i, %out );
    for ( $i = 0 ; $i < scalar( @{ $res{'date'} } ) ; $i++ )
    {
        $out{ $res{date}[$i] }{'comment'} = $res{'thetext'}[$i];
        $out{ $res{date}[$i] }{'who'} = $res{'who'}[$i];
    }

    if ($act)
    {
        if(!$recref)
        {
            %rec=&db_GetRecord($recid);
        }
        else
        {
            %rec=%{$recref};
        }
        $type=$rec{type};
        $pid=$rec{pid};
        my ($sql) =
"select * from traq_activity where record_id=$recid and fieldname != 'delta_ts' and fieldname!='record_id' order by date";
        my (%res) = &doSql($sql);
        if($res{date})
        {
            for ( $i = 0 ; $i < scalar( @{ $res{'date'} } ) ; $i++ )
            {
                if ( $res{'fieldname'}[$i] eq 'text' )
                {
                    next;
                }
                my ($changesize);
                if($out{ $res{date}[$i] }{'change'})
                {
                    $changesize= scalar( @{ $out{ $res{date}[$i] }{'change'} } );
                }
                else
                {
                    $changesize=0;
                }
                $out{ $res{date}[$i] }{'who'} = $res{'who'}[$i];
                $out{ $res{date}[$i] }{'change'}[$changesize]{'field'}= $res{'fieldname'}[$i];
                $out{ $res{date}[$i] }{'change'}[$changesize]{'oldvalue'}= $res{'oldvalue'}[$i];
                $out{ $res{date}[$i] }{'change'}[$changesize]{'newvalue'}= $res{'newvalue'}[$i];
            }
        }
    }
    my($date);
    my(@changedates)=keys(%out);
    @changedates=sort { $a cmp $b }(@changedates);
    my($z)=0;
    foreach $date (@changedates)
    {
        if($out{$date}{comment})
        {
            $ret.="<div class=comment><div class=commentheader>";
        }
        else
        {
            $ret.="<div class=activity><div class=activityheader>";
        }
        if ($plain)
        {
            $ret .= "$date " . &getNameFromId( $out{$date}{who} ) . "  Comment #$z:\n";
        }
        else
        {
            $ret .= "<div class=time>$date</div><div class=who>" . &getNameFromId( $out{$date}{who} ) . "</div>";
        }
        if($out{$date}{comment})
        {
            # Escape html char into entities, unless email reply
            if ( $out{$date}{comment} =~ /^emailreply:/ )
            {
                $out{$date}{comment} =~ s/^emailreply:/<font size=-1 color=grey><i>Email Reply<\/i>:<\/font>\\n/;
            }
            else
            {
                $out{$date}{comment} = &unEscapeQuotes( $out{$date}{comment} );
                $out{$date}{comment} = &escapeHtml( $out{$date}{comment} );
            }
            if($z==0)
            {	
	            $ret .= "<div class=commentlabel><a name='comment$z'></a><a class=commentheader href='#comment$z'>$c{$type . 'traq'}{'label'}{long_desc}:</a></div>";
	            #$ret .= "<div>";
	            $ret .= "<div class=commenttext>$out{$date}{comment}</div></div>";
			}
			else
			{
	            $ret .= "<div class=commentlabel><a name='comment$z'></a><a class=commentheader href='#comment$z'>$c{$type . 'traq'}{'label'}{note} # $z:</a></div><div class=commenttext>$out{$date}{comment}</div></div>";
            }
            $z++;
        }
        if($out{$date}{change})
        {
            if($out{$date}{comment})
            {   
                &log("DEBUG: Comment $z has div for activity",7);
                $ret.="<div class=activity>";        
            }
            else
            {
                $ret.="</div>";
            }
            $ret.="<div class=activitylabel>Record Activity:</div>";
            for($i=0;$i<scalar(@{$out{$date}{change}});$i++)
            {
                if ( $out{$date}{'change'}[$i]{'field'} eq 'text' )
                {
                      next;
                }
                unless( $out{$date}{'change'}[$i]{'newvalue'} || $out{$date}{'change'}[$i]{'oldvalue'} )
				{

                    next;
                }
                if( $out{ $date }{'change'}[$i]{'field'} eq 'who')
                {
                    $out{$date}{'change'}[$i]{'oldvalue'}=&getNameFromId($out{$date}{'change'}[$i]{'oldvalue'}) if $out{$date}{'change'}[$i]{'oldvalue'};
                    $out{$date}{'change'}[$i]{'newvalue'}=&getNameFromId($out{$date}{'change'}[$i]{'newvalue'}) if $out{$date}{'change'}[$i]{'newvalue'};
                    if($out{$date}{'change'}[$i]{'newvalue'})
                    {
                    $ret.="<div class=activityfield>Add $c{general}{'label'}{'cc'}</div> '<div class=activityvalue>$out{$date}{'change'}[$i]{'newvalue'}</div>'";
                    }
                    if($out{$date}{'change'}[$i]{'oldvalue'})
                    {
                    $ret.="<div class=activityfield>Remove $c{general}{'label'}{'cc'}</div> '<div class=activityvalue>$out{$date}{'change'}[$i]{'oldvalue'}</div>'";
                    }
                    $ret.="<div class=nl></div>";
                    next;
                }
                if( $out{ $date }{'change'}[$i]{'field'} eq 'create')
                {
                    $ret.="<div class=activityfield>Add Attachment</div> '<div class=activityvalue>$out{$date}{'change'}[$i]{'newvalue'}</div>'";
                    $ret.="<div class=nl></div>";
                    next;
                }
                if( $out{ $date }{'change'}[$i]{'field'} eq 'delete')
                {
                    $ret.="<div class=activityfield>Remove Attachment</div> '<div class=activityvalue>$out{$date}{'change'}[$i]{'oldvalue'}</div>'";
                    next;
                }
                $rec{ $out{$date}{'change'}[$i]{'field'} }=$out{$date}{'change'}[$i]{'newvalue'};
                $out{$date}{'change'}[$i]{'newvalue'}=&Traqfields::getFieldDisplayValue($out{$date}{'change'}[$i]{'field'},\%rec,$userid);
                $rec{ $out{$date}{'change'}[$i]{'field'} }=$out{$date}{'change'}[$i]{'oldvalue'};
                $out{$date}{'change'}[$i]{'oldvalue'}=&Traqfields::getFieldDisplayValue($out{$date}{'change'}[$i]{'field'},\%rec,$userid);
                $ret.="<div class=activityfield>$c{$type . 'traq'}{'label'}{$out{$date}{'change'}[$i]{'field'}}</div> from '<div class=activityvalue>$out{$date}{'change'}[$i]{'oldvalue'}</div>' to '<div class=activityvalue>$out{$date}{'change'}[$i]{'newvalue'}</div>'";
                $ret.="<div class=nl></div>";
            }
            if($out{$date}{comment})
            {   
                $ret.="</div>";        
            }
        }
        $ret.="</div>";
    }
    unless ($plain)
    {
        $ret =~ s/\n/<br>/g;
    }
    $ret =~ s/(\d{4}-\d{2}-\d{2} \d{2}:\d{d2}:\d{2} \w+-*\s*\w+, \w+\s*\(*\w*\)*:)/\<b\>$1\<\/b\>/g;    
    
# 	my (%prefs) = &getMailPrefs($main::userid);
# 	if ( grep( /hackme/, @{ $prefs{'prefs'} } ) )
# 	{
# 		$ret = &hackerize($ret);
# 	}
	return $ret;
}
##############################################################
# getRecordGroups(recordid)
sub getRecordGroups
{
	my ($recordid) = @_;
	my ($sql)      = "select groupid from acl_traq_records where record_id=\"$recordid\"";
	my (%res)      = &doSql($sql);
	unless (%res)
	{

		#&doError("Error geting groups for record:$recordid", $sql);
		&doError("Invalid Record ID.");
	}
	my (@ret) = @{ $res{'groupid'} };
	return @ret;
}
##############################################################
# getComponentGroups(recordid)
sub getComponentGroups
{
	my ($componentid) = @_;
	my ($sql)         = "select groupid from acl_traq_components where componentid=$componentid";
	my (%res)         = &doSql($sql);
	unless (%res)
	{
		&doError( "Error geting groups for component:$componentid", $sql );
	}
	my (@ret) = @{ $res{'groupid'} };
	return @ret;
}
##############################################################
# getNameFromId(userid)
sub getNameFromId
{
	my ( $uid, $format ) = @_;
	my ( $name, %res, $sql, $lookup );
	my ($userid) = $uid;
	unless ( $uid =~ /\d+/ ) { return; }
	if ( $c{cache}{usecache} )
	{
		if ( $format eq 'username' )
		{
			$lookup = "user=$userid=username";
		}
		else
		{
			$lookup = "user=$userid=last_name";
		}
		my ($cache) = new Cache::FileCache( { 'namespace' => "user-$c{session}{key}" } );
		my ($value) = $cache->get($lookup);
		if ( not defined $value )
		{
			&log( "DEBUG: cache lookup failed for $lookup.  will repopulate cache", 7 );
			&populateUserCache();
		}
		if ( $format eq 'username' )
		{
			return $cache->get($lookup);

		}
		else
		{
			if ( $c{useraccount}{sortname} eq 'last_name' )
			{
				$value = $cache->get("user=$userid=last_name") . ', ' . $cache->get("user=$userid=first_name");
			}
			else
			{
				$value = $cache->get("user=$userid=first_name") . ' ' . $cache->get("user=$userid=last_name");
			}
			return $value;
		}
	}
	else
	{
		$sql  = "select first_name,last_name,username from $c{db}{logintable} where $c{db}{logintablekey}=\"$uid\"";
		%res  = &doSql($sql);
		$name = $res{'last_name'}[0] . ", " . $res{'first_name'}[0] if ( $c{useraccount}{sortname} eq 'last_name' );
		$name = $res{'first_name'}[0] . " " . $res{'last_name'}[0] if ( $c{useraccount}{sortname} eq 'first_name' );
		if ( $format eq 'username' )
		{
			return $res{username}[0];
		}
		else
		{
			return $name;
		}
	}
}
##############################################################
sub getNamesFromIds
{
	my (@uid) = @_;
	my ( %names, $uid, @newuids );
	unless ( scalar(@uid) ) { return; }

	# 	foreach $uid (@uid)
	# 	{
	# 		if($c{cache}{user}{$uid}{last_name} && $c{cache}{user}{$uid}{first_name})
	# 		{
	# 			$names{$uid}=$c{cache}{user}{$uid}{last_name} . ", " . $c{cache}{user}{$uid}{first_name};
	# 			&log("PRO: cache hit");
	# 		}
	# 		elsif($uid ne '0')
	# 		{
	# 			push (@newuids,$uid);
	# 		}
	# 	}
	#
	#Bypass caching, since it is apparently broken here
	@newuids = @uid;
	if ( scalar(@newuids) )
	{
		my ($uids) = join( ',', @newuids );
		my ($sql)  = "select first_name,last_name,$c{db}{logintablekey} from $c{db}{logintable} where $c{db}{logintablekey} in (\"$uids\")";
		my (%res)  = &doSql($sql);
		for ( my ($i) = 0 ; $i < scalar( @{ $res{'last_name'} } ) ; $i++ )
		{
			my ($name) = $res{'last_name'}[$i] . ", " . $res{'first_name'}[$i];
			$names{ $res{ $c{db}{logintablekey} }[$i] }                      = $name;
			$c{cache}{user}{ $res{ $c{db}{logintablekey} }[$i] }{last_name}  = $res{'last_name'}[$i];
			$c{cache}{user}{ $res{ $c{db}{logintablekey} }[$i] }{first_name} = $res{'first_name'}[$i];
		}
	}
	return %names;
}

##############################################################
# getGroupsFromEmployeeId(empid)
sub getGroupsFromEmployeeId
{
	my ($uid) = @_;
	return &getGroupsFromUserId($uid);
}
##############################################################
# getGroupsFromUserId(userid)
sub getGroupsFromUserId
{
	my ($uid) = @_;
	my ($sql) = "select groupid from user_groups where userid=$uid";
	my (%res) = &doSql($sql);
	my (@groups);
	if (%res)
	{
		@groups = @{ $res{'groupid'} };
	}
	return @groups;
}
##############################################################
# getGroupsFromUnixName(unixname)
sub getGroupsFromUnixName
{
	my ($unixname) = @_;
	my ($uid)      = getEmployeeIdFromUnixName($unixname);
	return &getGroupsFromEmployeeId($uid);
}
##############################################################
# getEmployeeIdFromUnixName(unixname)
sub getEmployeeIdFromUnixName
{
	my ($unixname) = @_;
	my ($sql)      = "select $c{db}{logintablekey} from $c{db}{logintable} where $c{db}{logintablename}=\"$unixname\"";
	&log("SQL: $sql",7);
	my (%res) = &doSql($sql);
	my ($id)  = $res{ $c{db}{logintablekey} }[0];
	return $id;
}
##############################################################
# getEmployeeIdFromName("last, first")
sub getEmployeeIdFromName
{
	my ( $fullname, $valid ) = @_;
	$fullname =~ s/ //;
	my ( $last, $first ) = split( /,/, $fullname );
	my ($sql) = "select $c{db}{logintablekey},active from $c{db}{logintable} where last_name=\"$last\" and first_name=\"$first\"";
	my (%res) = &doSql($sql);
	if ( $valid && $res{active} ne 'Yes' )
	{
		return 'INACTIVE';
	}
	my ($id) = $res{ $c{db}{logintablekey} }[0];
	return $id;
}

##############################################################
### getEmployeeList
##############################################################
sub getEmployeeList
{
	my ( $full, $projectid, $active, $complete ) = @_;
	my ( $activeClause, @return, %return_hash, $sql );
	$active = $active || "Yes";
	if ( $active eq "Yes" )
	{
		$activeClause = "active = \"Yes\"";
	}
	elsif ( $active eq "No" )
	{
		$activeClause = "active = \"No\"";
	}
	elsif ( $active eq "All" )
	{
		$activeClause = "active in (\"Yes\", \"No\" , \"\")";
	}
	my ($completeclause) = " and emp.userid > 1 ";
	if ($complete)
	{
		$completeclause = "";
	}
	if ($projectid)
	{
		$sql =
"select emp.first_name,emp.last_name,emp.$c{db}{logintablekey},usg.groupid,acl.groupid,acl.projectid from $c{db}{logintable} emp, user_groups usg, acl_traq_projects acl where $activeClause  and emp.$c{db}{logintablekey}=usg.userid and usg.groupid in (acl.groupid) and acl.projectid=$projectid $completeclause and emp.last_name like \"%_%\""
		  . " and $activeClause order by $c{useraccount}{sortname}";
	}
	else
	{
		$completeclause = " and userid > 1 ";
		if ($complete)
		{
			$completeclause = "";
		}
		$sql =
"select first_name,last_name,$c{db}{logintablekey} from $c{db}{logintable} where $activeClause and last_name like \"%_%\" $completeclause order by $c{useraccount}{sortname}";
	}
	my (%res);
	%res = &doSql($sql);
	if ( !keys(%res) )
	{
		return %return_hash if $full;
		return (@return);
	}
	my ($name);
	for ( my ($i) = 0 ; $i < scalar( @{ $res{'last_name'} } ) ; $i++ )
	{
		$c{cache}{user}{ $res{ $c{db}{logintablekey} }[$i] }{last_name}  = $res{'last_name'}[$i];
		$c{cache}{user}{ $res{ $c{db}{logintablekey} }[$i] }{first_name} = $res{'first_name'}[$i];
		$name = "$res{'last_name'}[$i], $res{'first_name'}[$i]" if ( $c{useraccount}{sortname} eq 'last_name' );
		$name = "$res{'first_name'}[$i] $res{'last_name'}[$i]"  if ( $c{useraccount}{sortname} eq 'first_name' );
		if ($full)
		{
			chomp($name);
			$return_hash{"$name"} = $res{ $c{db}{logintablekey} }[$i];

		}
		else
		{
			push( @return, $name );
		}
	}
	if ($full)
	{
		return %return_hash;
	}
	return (@return);

}
##############################################################
# getCCList
##############################################################
sub getCCList
{
	my ( $full, $proj, $act ) = @_;
	return ( &getEmployeeList( $full, $proj, $act ) );
}
##############################################################
# getMenu(menuname, full|0)
##############################################################
sub getMenu
{
	my ( $menuName, $full, $projectid, $defaults ) = @_;
	&log("PRO: get menu call menu: $menuName , project: $projectid") if $c{profile};
	my ( @return, %hash, @values, %temphash );
	my ( $typesql, $type, %pres, %return, $val );
	if ($main::TASKS)
	{
		$type    = 'task';
		$typesql = "rec_type like \"%task%\"";
	}
	else
	{
		$type    = 'bug';
		$typesql = "rec_type like \"%bug%\"";
	}

	#get project menus
	unless ( $c{cache}{menu}{$menuName}{$projectid} )
	{
		&log("PRO: menu cache populated for project $projectid") if $c{profile};
		my ($sql) = "select distinct menuname,display_value,value from traq_menus where project=$projectid and $typesql order by menuname,value";

		#	    my($sql) = "select distinct def,menuname,display_value,value from traq_menus where project=$projectid and $typesql order by menuname,value";
		if ( $defaults && $pres{value}[0] eq "" )
		{

			#			$sql = "select distinct def,menuname,display_value,value from traq_menus where project in ($projectid, 0) and $typesql order by menuname,value";
			$sql = "select distinct menuname,display_value,value from traq_menus where project in ($projectid, 0) and $typesql order by menuname,value";
		}
		my (%pres) = &doSql($sql);

		# Put data returned from database into cache
		if (%pres)
		{
			for ( my ($x) = 0 ; $x < scalar( @{ $pres{'value'} } ) ; $x++ )
			{
				$c{cache}{menu}{ $pres{'menuname'}[$x] }{$projectid}{$type}{ $pres{'value'}[$x] } = $pres{'display_value'}[$x];
			}
		}
	}

	# Convert to hash of arrays to return
	my ($x) = 0;
	if ( $c{cache}{menu}{$menuName}{$projectid} )
	{
		%temphash = %{ $c{cache}{menu}{$menuName}{$projectid}{$type} };
		@values   = keys(%temphash);
	}
	@values = sort { $a <=> $b } @values;
	foreach $val (@values)
	{
		$return{'value'}[$x]         = $val;
		$return{'display_value'}[$x] = $c{cache}{menu}{$menuName}{$projectid}{$type}{$val};
		$x++;
	}
	if ($full)
	{
		return (%return);
	}
	@return = @{ $return{'value'} };
	return (@return);
}
##############################################################
# getComponents(projectid, componentid,rec_type)
##############################################################
sub getComponents
{
	my ( $sql, @return, %hash, %return, $value, $projectclause );
	my ( $projectid, $compid, $type ) = @_;
	unless ( $c{cache}{project}{$projectid}{component} )
	{
		$sql =
"select rec_type,description,component,componentid,initialowner,initialqacontact,projectid from traq_components where projectid in ($projectid) and active=\"checked\" order by component";
		%hash = &doSql($sql);
		if ( !%hash || $projectid =~ /,/ )
		{
			return %hash;
		}
		for ( my ($x) = 0 ; $x < scalar( @{ $hash{'componentid'} } ) ; $x++ )
		{
			$c{cache}{project}{$projectid}{component}{ $hash{'componentid'}[$x] }{name}             = $hash{'component'}[$x];
			$c{cache}{project}{$projectid}{component}{ $hash{'componentid'}[$x] }{description}      = $hash{'description'}[$x];
			$c{cache}{project}{$projectid}{component}{ $hash{'componentid'}[$x] }{type}             = $hash{'rec_type'}[$x];
			$c{cache}{project}{$projectid}{component}{ $hash{'componentid'}[$x] }{initialowner}     = $hash{'initialowner'}[$x];
			$c{cache}{project}{$projectid}{component}{ $hash{'componentid'}[$x] }{initialqacontact} = $hash{'initialqacontact'}[$x];
		}
	}
	if ($compid)
	{

		#$sql = "select component,componentid from traq_components where componentid=$compid order by component";
		$return{'component'}[0]        = $c{cache}{project}{$projectid}{component}{$compid}{name};
		$return{'componentid'}[0]      = $compid;
		$return{'description'}[0]      = $c{cache}{project}{$projectid}{component}{$compid}{description};
		$return{'initialowner'}[0]     = $c{cache}{project}{$projectid}{component}{$compid}{initialowner};
		$return{'initialqacontact'}[0] = $c{cache}{project}{$projectid}{component}{$compid}{initialqacontact};
	}
	elsif ($type)
	{

#$sql = "select description,component,componentid from traq_components where projectid=\"$projectid\" and active=\"checked\" and rec_type like \"%$type%\" order by component";
		my ($x)        = 0;
		my (%temphash) = %{ $c{cache}{project}{$projectid}{component} };
		foreach $value ( sort { $temphash{$a}{name} cmp $temphash{$b}{name} } keys(%temphash) )
		{
			if ( grep( /$type/, ( $c{cache}{project}{$projectid}{component}{$value}{type} ) ) )
			{
				$return{'component'}[$x]        = $c{cache}{project}{$projectid}{component}{$value}{name};
				$return{'componentid'}[$x]      = $value;
				$return{'description'}[$x]      = $c{cache}{project}{$projectid}{component}{$value}{description};
				$return{'initialowner'}[$x]     = $c{cache}{project}{$projectid}{component}{$value}{initialowner};
				$return{'initialqacontact'}[$x] = $c{cache}{project}{$projectid}{component}{$value}{initialqacontact};
				$x++;
			}
		}
	}
	else
	{
		my ($x)        = 0;
		my (%temphash) = %{ $c{cache}{project}{$projectid}{component} };
		foreach $value ( sort { $temphash{$a}{name} cmp $temphash{$b}{name} } keys(%temphash) )
		{
			$return{'component'}[$x]        = $c{cache}{project}{$projectid}{component}{$value}{name};
			$return{'componentid'}[$x]      = $value;
			$return{'description'}[$x]      = $c{cache}{project}{$projectid}{component}{$compid}{description};
			$return{'initialowner'}[$x]     = $c{cache}{project}{$projectid}{component}{$compid}{initialowner};
			$return{'initialqacontact'}[$x] = $c{cache}{project}{$projectid}{component}{$compid}{initialqacontact};
			$x++;
		}

	}
	return (%return);
}
##############################################################
sub getRecordCcs
{
	my ($id)  = @_;
	my ($sql) = "select who from traq_cc where record_id=$id";
	my (%res) = &doSql($sql);
	if (%res)
	{
		return @{ $res{'who'} };
	}
}
##############################################################
sub doError
{
	my (%res);
	my ( $str, $sql, $cgi, $title ) = @_;
	$title = "Error" unless $title;
	if ($cgi)
	{
		print $cgi->redirect("$c{url}{base}/actioncomplete.cgi?action=$title&result=$str");
		stopLog();
		exit;
	}
	my ($q) = new CGI;
	print $q->header;
	if ($sql) { $res{'SQLLABEL'}[0] = "SqlString: "; }
	$res{'TITLE'}[0] = $title;
	$str =~ s/\%20/\ /g;
	$res{'ERRORSTRING'}[0] = $str;
	$res{'SQL'}[0]         = $sql;
	$res{HEADER}[0] = &getHeader( $userid, "traq" );
	$res{FOOTER}[0] = &getFooter( $userid, "traq" );
	$res{PISSROOT}[0] = $c{url}{base};
    my($templatefile)=&getTemplateFile($c{dir}{errorTemplate});
	my ($html) = Process( \%res, $templatefile);
	print $html;
	my ($errstr) = $str;
	if ($sql) { $errstr .= " sql: $sql"; }
	&log( "Error: $errstr", 2 );
	&stopLog;
	exit 0;
}

##############################################################
sub updateLongDesc
{
	my ( $new, $old, $record, $user ) = @_;
	my ($now) = &makeMysqlTimestamp( time() );
	my ($sql) = "insert into traq_longdescs set who=\"$user\",thetext=\"$new\",date=$now,record_id=$record";
	&log("SQL: $sql",7);
	print "updated traq_longdescs<br>" if $main::DEBUG;
	&doSql($sql);
	&log( "note added", 5 );

}
##############################################################
sub deleteCc
{
	my ( $record, $cc, $user ) = @_;
	my ($sql) = "delete from traq_cc where record_id=$record and who=$cc";
	&log( "SQL: $sql", 7 );
	&doSql($sql);
	my ($now) = &makeMysqlTimestamp( time() );
	$sql = "insert into traq_activity set record_id=$record,who=$user,date=$now,fieldname=\"who\",oldvalue=\"$cc\",newvalue=\"\",tablename=\"traq_cc\"";
	&log( "SQL: $sql", 7 );
	&doSql($sql);
}
##############################################################
sub insertNewCc
{
	my ( $record, $cc, $user ) = @_;
	if ( !$cc )
	{
		return;
	}
	my ($sql) = "insert into traq_cc set record_id=$record,who=$cc";
	&log("SQL: $sql",7);
	&doSql($sql);
	my ($now) = &makeMysqlTimestamp( time() );
	$sql = "insert into traq_activity set record_id=$record,who=$user,date=$now,fieldname=\"who\",newvalue=\"$cc\",tablename=\"traq_cc\"";
	&log("SQL: $sql",7);
	&doSql($sql);

}
##############################################################
# updateRecord(recordId, table, field, oldvalue, newvalue, user)
sub updateRecord
{
	my ( $id, $table, $field, $old, $new, $user ) = @_;
	my ($now) = &makeMysqlTimestamp( time() );
	my ($sql) = "update $table set $field=\"$new\",delta_ts=now() where record_id=$id";
	&log("SQL: $sql",7);
	&doSql($sql);
	$sql = "insert into traq_activity set record_id=$id,who=$user,date=now(),fieldname=\"$field\",oldvalue=\"$old\",newvalue=\"$new\",tablename=\"$table\"";
	&log("SQL: $sql",7);
	&doSql($sql);
	&log( "updated record:$id, table:$table, field:$field, old:$old, new:$new by $user", 5 );

}
##############################################################
sub db_GetRecord
{
	my ($recordid) = @_;
	my ($sql)      =
	  " select rec.*,dep.dependson as children from traq_records rec left join traq_dependencies dep on rec.record_id=dep.blocked where record_id=\"$recordid\" ";
	&log( "Retrieving record $recordid with $sql", 5 );
	my (%res) = &doSql($sql);
	unless (%res)
	{
		&doError( "Error retrieving record: $recordid", $sql );
	}
	my ( %record, $key );
	foreach $key ( keys(%res) )
	{
		$record{$key} = $res{$key}[0];
	}
	return %record;
}

sub db_GetRecordField
{
	my ($recordid,$field) = @_;
	my ($sql)      =
	  " select rec.field from traq_records rec where record_id=\"$recordid\" ";
	&log( "Lookup $field for record $recordid with $sql", 5 );
	my (%res) = &doSql($sql);
	unless (%res)
	{
		&doError( "Error retrieving record: $recordid", $sql );
	}
	return $res{$field}[0];
}

#TODO DYNAMICFIELD
sub getRecord
{
	&log("PRO: getrecord call.  query count: $c{cache}{totalqueries}") if $c{profile};
	my ( $recordid, $type ) = @_;
	my ($sql) = "select * from traq_records where record_id=\"$recordid\"";
	&log( "Retrieving record $recordid with $sql", 5 );
	my (%res) = &doSql($sql);
	unless (%res)
	{
		&doError( "Error retrieving record: $recordid", $sql );
	}

	&log("PRO: query count: $c{cache}{totalqueries}") if $c{profile};

	if ( $type eq "raw" ) { return %res; }
	my (%ret);
	${ $ret{'RECORDID'} }[0] = $recordid;
	${ $ret{'TYPE'} }[0]     = $res{'type'}[0];
	my (@recids) = ( ${ $res{'assigned_to'} }[0], ${ $res{'tech_contact'} }[0], ${ $res{'qa_contact'} }[0], ${ $res{'reporter'} }[0] );
	getNamesFromIds(@recids);
	${ $ret{'ASSIGNED_TO_ID'} }[0]    = ${ $res{'assigned_to'} }[0];
	${ $ret{'ASSIGNED_TO_NAME'} }[0]  = &getNameFromId( ${ $res{'assigned_to'} }[0] );
	${ $ret{'TECH_CONTACT_ID'} }[0]   = ${ $res{'tech_contact'} }[0];
	${ $ret{'TECH_CONTACT_NAME'} }[0] = &getNameFromId( ${ $res{'tech_contact'} }[0] );
	${ $ret{'QA_CONTACT_ID'} }[0]     = ${ $res{'qa_contact'} }[0];
	${ $ret{'QA_CONTACT_NAME'} }[0]   = &getNameFromId( ${ $res{'qa_contact'} }[0] );
	${ $ret{'REPORTER'} }[0]          = &getNameFromId( ${ $res{'reporter'} }[0] );
	${ $ret{'REPORTERID'} }[0]        = ${ $res{'reporter'} }[0];
	${ $ret{'PRODUCTID'} }[0]         = ${ $res{'projectid'} }[0];
	${ $ret{'PRODUCT'} }[0]           = &getProjectNameFromId( ${ $res{'projectid'} }[0] );
	${ $ret{'PROJECT'} }[0]           = ${ $ret{'PRODUCT'} }[0];
	${ $ret{'RTYPE'} }[0]             = uc( substr( ${ $res{'type'} }[0], 0, 1 ) );
	${ $ret{'NUMATTACH'} }[0]         = &getNumAttachments($recordid);
	${ $ret{delta_ts} }[0]            = $res{delta_ts}[0];
	${ $ret{creation_ts} }[0]         = $res{creation_ts}[0];
	$sql = "select who from traq_cc where record_id=$recordid";
	my (%res2) = &doSql($sql);
	my ($i);

	if (%res2)
	{
		for ( $i = 0 ; $i < scalar( @{ $res2{'who'} } ) ; $i++ )
		{
			my ($ccid) = ${ $res2{'who'} }[$i];
			my ($name) = &getNameFromId($ccid);
			${ $ret{'CCID'} }[$i]   = $ccid;
			${ $ret{'CCNAME'} }[$i] = $name;
		}
	}

	my (@keywords);
	@keywords = split( / /, $res{'keywords'}[0] );
	$ret{'KEYWORDS'}[0] = $res{'keywords'}[0];
	my (%keywordDetails) = &getKeywords(@keywords);
	if (%keywordDetails)
	{
		for ( my ($i) = 0 ; $i < scalar( @{ $keywordDetails{'name'} } ) ; $i++ )
		{
			$ret{'KEYWORDSELVALUE'}[$i] = $keywordDetails{'keywordid'}[$i];
			$ret{'KEYWORDDISPVAL'}[$i]  = $keywordDetails{'name'}[$i];

		}
	}
	&log("PRO: query count: $c{cache}{totalqueries}") if $c{profile};
	${ $ret{'BUILDIDSELVALUE'} }[0] = ${ $res{'version'} }[0];
	${ $ret{'BUILDIDDISPVAL'} }[0]  = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "version", ${ $res{'version'} }[0], $res{'type'}[0], '' );
	${ $ret{'PLATFORMSELVAL'} }[0]  = ${ $res{'bug_platform'} }[0];
	${ $ret{'PLATFORMDISPVAL'} }[0] = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "bug_platform", ${ $res{'bug_platform'} }[0], $res{'type'}[0], '' );
	${ $ret{'OPSYSSELVAL'} }[0]     = ${ $res{'bug_op_sys'} }[0];
	${ $ret{'OPSYSDISPVAL'} }[0]    = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "bug_op_sys", ${ $res{'bug_op_sys'} }[0], $res{'type'}[0], '' );
	${ $ret{'REPROSELVAL'} }[0]     = ${ $res{'reproducibility'} }[0];
	${ $ret{'REPRODISPVAL'} }[0]    = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "reproducibility", ${ $res{'reproducibility'} }[0], $res{'type'}[0], '' );
	${ $ret{'PRIORITYSELVAL'} }[0]  = ${ $res{'priority'} }[0];
	${ $ret{'PRIORITYDISPVAL'} }[0] = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "priority", ${ $res{'priority'} }[0], $res{'type'}[0], '' );
	${ $ret{'SEVERITYSELVAL'} }[0]  = ${ $res{'severity'} }[0];
	${ $ret{'SEVERITYDISPVAL'} }[0] = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "severity", ${ $res{'severity'} }[0], $res{'type'}[0], '' );
	${ $ret{'COMPONENTSELVAL'} }[0] = ${ $res{'componentid'} }[0];

	my (%res4) = &getComponents( ${ $res{'projectid'} }[0], ${ $res{'componentid'} }[0] );

	${ $ret{'COMPONENTDISPVAL'} }[0] = ${ $res4{'component'} }[0];
	${ $ret{'SHORT_DESC'} }[0]       = ${ $res{'short_desc'} }[0];
	${ $ret{'SHORT_DESC'} }[0]       = &escapeQuotes( ${ $ret{'SHORT_DESC'} }[0] );
	${ $ret{'KEYWORDS'} }[0]         = ${ $res{'keywords'} }[0];
	${ $ret{'CHANGELIST'} }[0]       = ${ $res{'changelist'} }[0];
	${ $ret{'WHITEBOARD'} }[0]       = &escapeHtml( ${ $res{'status_whiteboard'} }[0] );
	if ( $res{'target_date'}[0] eq "0000-00-00" )
	{
		$res{'target_date'}[0] = '';
	}
	else
	{
		${ $ret{'TARGET_DATE'} }[0] = &escapeHtml( ${ $res{'target_date'} }[0] );
	}
	if ( $res{'start_date'}[0] eq "0000-00-00" )
	{
		$res{'start_date'}[0] = '';
	}
	else
	{
		${ $ret{'START_DATE'} }[0] = &escapeHtml( ${ $res{'start_date'} }[0] );
	}

	&log("PRO: query count: $c{cache}{totalqueries}") if $c{profile};

	${ $ret{'UNITS_REQ'} }[0]         = &escapeHtml( ${ $res{'units_req'} }[0] );
	${ $ret{'LONG_DESC'} }[0]         = &getLongDesc($recordid);
	${ $ret{'MILESTONEVAL'} }[0]      = ${ $res{'target_milestone'} }[0];
	${ $ret{'MILESTONEDISPVAL'} }[0]  = &getMilestoneDisplayValue( $res{'projectid'}[0], $res{target_milestone}[0] );
	${ $ret{'RESOLUTIONSELVAL'} }[0]  = ${ $res{'resolution'} }[0];
	${ $ret{'RESOLUTIONDISPVAL'} }[0] = &getMenuDisplayValue( ${ $res{'projectid'} }[0], "resolution", ${ $res{'resolution'} }[0], $res{'type'}[0], '' );
	$ret{'RECORDSTATUS'}[0] = &getMenuDisplayValue( $res{'projectid'}[0], "status", $res{'status'}[0], $res{'type'}[0], '' );
	${ $ret{'RECORDSTATUSV'} }[0] = $res{'status'}[0];
	my (%deps) = &getChildren( $recordid, ('0') );
	my ($z) = 0;
	my ($dep);

	foreach $dep ( @{ $deps{'dependson'} } )
	{
		${ $ret{'CHRTYPE'} }[$z]       = uc( substr( ${ $deps{'type'} }[$z], 0, 1 ) );
		${ $ret{'CHILDID'} }[$z]       = $dep;
		${ $ret{'CHILDIDSTATUS'} }[$z] = &getMenuDisplayValue( ${ res { 'projectid' } }[0], "status", ${ $deps{'status'} }[$z], $res{'type'}[0], '' );
		if (   $ret{'CHILDIDSTATUS'}[$z] eq 'Resolved'
			|| $ret{'CHILDIDSTATUS'}[$z] eq 'Verified'
			|| $ret{'CHILDIDSTATUS'}[$z] eq 'Closed' )
		{
			$ret{'CHILDIDSTRIKE'}[$z] = "<STRIKE>";
		}
		$z++;
	}
	%deps = {};
	$z    = 0;
	%deps = &getParents( $recordid, ('0') );
	foreach $dep ( @{ $deps{'blocked'} } )
	{
		${ $ret{'PARTYPE'} }[$z]        = uc( substr( ${ $deps{'type'} }[$z], 0, 1 ) );
		${ $ret{'PARENTID'} }[$z]       = $dep;
		${ $ret{'PARENTIDSTATUS'} }[$z] = &getMenuDisplayValue( ${ res { 'projectid' } }[0], "status", ${ $deps{'status'} }[$z], $res{'type'}[0], '' );
		if (   $ret{'PARENTIDSTATUS'}[$z] eq 'Resolved'
			|| $ret{'PARENTIDSTATUS'}[$z] eq 'Verified'
			|| $ret{'PARENTIDSTATUS'}[$z] eq 'Closed' )
		{
			$ret{'PARENTIDSTRIKE'}[$z] = "<STRIKE>";
		}
		$z++;
	}
	&log("PRO: end of get record query count: $c{cache}{totalqueries}") if $c{profile};

	return %ret;

}
##############################################################
sub getMenuDisplayValue
{
	my ( $project, $menuname, $value, $type, $all ) = @_;
	my (@sysmenu) = split( ',', $c{general}{systemmenu} );
	if ( grep( /^$menuname$/, @sysmenu ) )
	{
		$project = 0;
	}
	if ( !$value )
	{
		return '';
	}
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "menu=$menuname=$project=$type=$value";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "menu-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&log( "DEBUG: cache lookup failed for $lookup.  will repopulate cache", 7 );
			&populateMenuCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select menuname,value,display_value from traq_menus where menuname=\"$menuname\" and project in ($project, 0) and value=\"$value\"";
		unless ($all)
		{
			if ( $type eq 'task' )
			{
				$sql .= " and rec_type like \"%task%\"";
			}
			else
			{
				$sql .= " and rec_type like \"%bug%\"";
			}
		}
		$sql .= " order by menuname,value";
		&log("SQL: $sql",7);
		my (%res3) = &doSql($sql);
		return $res3{display_value}[0];
	}
}
##############################################################
sub makeActivityEntry
{
	my ( $user, $record, $table, $field, $old, $new ) = @_;
	$old = &escapeQuotes($old);
	$new = &escapeQuotes($new);
	my ($now) = &makeMysqlTimestamp( time() );
	my ($sql) = "insert into traq_activity set fieldname=\"$field\",date=\"$now\",record_id=$record,who=$user,tablename=\"$table\",oldvalue=\"$old\",newvalue=\"$new\"";
	&doSql($sql);
	&log( "Added activity entry for record $record", 4 );
}

##############################################################
sub makePrettyTimestamp
{
	my ($time)  = @_;
	my (@time)  = localtime($time);
	my ($month) = $time[4] + 1;
	if ( $month == 1 )
	{
		$month = "January";
	}
	elsif ( $month == 2 )
	{
		$month = "February";
	}
	elsif ( $month == 3 )
	{
		$month = "March";
	}
	elsif ( $month == 4 )
	{
		$month = "April";
	}
	elsif ( $month == 5 )
	{
		$month = "May";
	}
	elsif ( $month == 6 )
	{
		$month = "June";
	}
	elsif ( $month == 7 )
	{
		$month = "July";
	}
	elsif ( $month == 8 )
	{
		$month = "August";
	}
	elsif ( $month == 9 )
	{
		$month = "September";
	}
	elsif ( $month == 10 )
	{
		$month = "October";
	}
	elsif ( $month == 11 )
	{
		$month = "November";
	}
	elsif ( $month == 12 )
	{
		$month = "December";
	}
	my ($day)  = $time[3];
	my ($year) = $time[5] + 1900;
	my ($hour) = $time[2];
	my ($min)  = $time[1];
	$hour =~ s/^(\d){1]$/0$1/;
	return "$month $day, $year, $hour:$min";

	return "testing";

}
#####################################################################
sub addRecordNote
{
	my ( $id, $note, $userid ) = @_;
	my ($ts)  = &makePrettyTimestamp( time() );
	my ($who) = &getNameFromId($userid);
	&updateLongDesc( $note, "old", $id, $userid );
	&makeActivityEntry( $userid, $id, "long_desc", "text", "old", "note_added" );
}
#####################################################################
sub getLastNote
{
	my ($id)  = shift;
	my ($sql) = "select * from traq_longdescs where record_id=$id order by date desc";
	my (%res) = doSql($sql);
	my ($who) = getNameFromId( $res{who}[0] );
	return "$who - " . "$res{thetext}[0]";
}
#####################################################################
sub getSmartField
{
	my ( $field, $disp, $project ) = @_;
	my (@dd);
	unless($project)
	{
	   $project=0;
	}
	@dd = split( ',', $c{general}{rolemenu} );
	if ( grep( /^$field$/, @dd ) || $field eq "cc" )
	{
		if ( $disp =~ /\w+/ )
		{
			$disp = &getEmployeeIdFromUnixName($disp);
		}
	}
	@dd = split( ',', $c{general}{systemmenu} );
	push( @dd, split( ',', $c{general}{projectmenu} ) );
	if ( grep( /^$field$/, @dd ) )
	{
		&log( "getting menu value for $disp", 5 );
		if ( $disp =~ /\w+/ )
		{
			$disp = &getMenuValue( $project, $field, $disp );
			&log( "getting menu value for $disp", 5 );
		}
	}
	return $disp;

}
##############################################################
sub getMenuValue
{
	my ( $project, $menuname, $disp , $type, $return_undef_on_failure) = @_;
	my ($sql) = "select value from traq_menus where project in ($project, 0) and display_value=\"$disp\" and menuname=\"$menuname\"";
    if($type)
    {   
        $sql.=" and rec_type like '$type'";
    }
	&log("SQL: $sql",7);
	my (%res3) = &doSql($sql);
	unless (%res3)
	{
		return undef if $return_undef_on_failure;
		&doError( "Error getting $menuname menu value for '$disp'", $sql );
	}
	return ${ $res3{'value'} }[0];

}
##############################################################
sub getRecordType
{
	my ($id) = @_;
	unless ( $id =~ /\d+/ ) { return; }
	my ($sql) = "select type from traq_records where record_id=\"$id\"";
	my (%res) = &doSql($sql);
	return $res{'type'}[0];
}

##############################################################
sub getNamedQuery
{
	my ( $user, $query ) = @_;
	unless ( $user && $query ) { return; }
	my ($sql)    = "select query from traq_namedqueries where userid=\"$user\" and name=\"$query\"";
	my (%res)    = &doSql($sql);
	my ($string) = &decode_base64( $res{'query'}[0] );
	unless ($string)
	{
		&doError("No query found.");
	}
	return $string;
}
##############################################################
sub getNamedQueries
{
	my ( $user, $type ) = @_;
	unless ($user) { return; }
	my $sql;
	if ( $type eq "task" )
	{
		$sql = "select * from traq_namedqueries where userid=\"$user\" and name != \"defaultquery\" and type=\"task\" order by name";
	}
	elsif ( $type eq "bug" )
	{
		$sql = "select * from traq_namedqueries where userid=\"$user\" and name != \"defaultquery\" and type=\"bug\" order by name";
	}
	else
	{
		$sql = "select * from traq_namedqueries where userid=\"$user\" and name != \"defaultquery\" order by type,name";
	}
	my (%res) = &doSql($sql);
	if (%res)
	{
		my ($after);
		for ( my ($i) = 0 ; $i < scalar( @{ $res{'name'} } ) ; $i++ )
		{
			if ( $res{'type'}[$i] eq "task" )
			{
				$after = $i;
				last;
			}
		}
	}
	return %res;
}
##############################################################
sub saveNamedQuery
{
	my ( $user, $name, $sql, $cgi, $type ) = @_;
	return unless $user && $name && $sql;
	unless ( $name eq "defaultquery" )
	{
		$sql =~ s/order by .+//g;
	}
	$sql =~ /(type\w*=\w*\"\w+\"),*/;
	my ($typestr);
	$typestr = "type=\"$type\"";

	$sql =~ s/and rec\.record_id in .+//g;
	$sql = encode_base64($sql);
	my ($insert) = "insert into traq_namedqueries set userid=\"$user\", ";
	$insert .= "name=\"$name\",query=\"$sql\",$typestr";
	if ($cgi)
	{
		my ($url) = $cgi->url( -path_info => 1, -query => 1, -relative => 1 );

		#$url =~ s/.+:\/\///;
		$insert .= ",url=\"$url\"";
	}
	&deleteNamedQuery( $user, $name );
	&doSql($insert);
}
##############################################################
sub deleteNamedQuery
{
	my ( $user, $name ) = @_;
	return unless $user && $name;
	my ($sql) = "delete from traq_namedqueries where userid=\"$user\" and name=\"$name\"";
	&doSql($sql);
}
##############################################################
sub saveTemplate
{
	my ( $userid, $cgi, $templatename, $projectid, $type ) = @_;
	$templatename =~ s/\s+/\_/g;
	$type = $type || "bug";
	return unless ( $userid && $cgi && $templatename );
	my ($url)       = $cgi->self_url;
	my (%cgihash)   = $cgi->Vars;
	my ($cgiasblob) = to_json( \%cgihash);
	my ($category)  = $cgi->param('category');
	my ($enc)       = encode_base64($cgiasblob) || &log( "Couldn't encode CGI hash", 1 );
	&doSql("delete from traq_templates where name=\"$templatename\" and category=\"$category\"");
	my ($sql) = "insert into traq_templates set projectid=\"$projectid\",category=\"$category\",name=\"$templatename\",template=\"$enc\",type=\"$type\"";
	&doSql($sql);
	&log( "saved template: $templatename: $sql", 5 );
}
##############################################################
sub getTemplates
{
	my ( $category, $type ) = @_;
	return unless $category;
	my ($sql) = "select * from traq_templates where category=\"$category\" order by type";
	my (%res) = &doSql($sql);
	return %res;
}
##############################################################
sub getTemplate
{
	my ( $category, $name ) = @_;
	return unless ( $category && $name );
	my ($sql) = "select template,projectid from traq_templates where category=\"$category\" and name=\"$name\"";
	my (%res) = &doSql($sql);
	&log( "template retrieval sql succeeded", 5 );
	my ($dec)   = decode_base64( $res{'template'}[0] );
	my %cgihash = %{ from_json($dec) };
	my $cgi     = new CGI( \%cgihash );
	return ( $cgi, $res{'projectid'}[0] );
}

##############################################################
# Save set of records into results
sub saveResults
{
	my ( $userid, $results ) = @_;
	&doSql("delete from traq_results where userid=\"$userid\"");
	my ($sql) = "insert into traq_results set userid=\"$userid\",result=\"$results\"";
	&doSql($sql);
}
##############################################################
sub getResults
{
	my ($userid) = @_;
	my (%res)    = &doSql("select result from traq_results where userid=\"$userid\"");
	return $res{'result'}[0];
}

##############################################################
sub getMilestoneDisplayValue
{
	my ( $project, $milestone ) = @_;
	unless ($milestone)
	{
		return;
	}
	my ( $item, $i );
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "target_milestone=$milestone";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "milestone-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&populateMilestoneCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select milestone,milestoneid from traq_milestones where milestoneid='$milestone'";
		&log("SQL: $sql",7);
		my (%res3) = &doSql($sql);
		return $res3{milestone}[0];
	}
}
##############################################################
sub getMilestones
{
	my ( $sql, @return, %hash, $projectclause );
	my ($projectid) = @_;

	$sql  = "select distinct * from traq_milestones where projectid in ($projectid, 0) order by milestone";
	%hash = &doSql($sql);
	return %hash;
}
##############################################################

##############################################################################
#
#  GetMilestones()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $hashref = &GetMilestones(\%results, $db_ref);
#
#  Takes in a reference to an associative array and a DB handle
#  and get all rows from PROJECTS table
#
##############################################################################
sub GetMilestones
{
	my ( $hashref, $dbref, $project ) = @_;
	$project = $project || 0;
	return getMilestones($project);
}

#----------------------------------------------------------------------------------

sub isEditAuthorized
{
	my ( $uid, $recordid ) = @_;
	&log( "Attempting authorization of user:$uid for record: $recordid", 5 );
	my (@recordgroups) = &getRecordGroups($recordid);
	my (@usergroups)   = &getGroupsFromEmployeeId($uid);
	my $group;
	foreach $group (@recordgroups)
	{
		my $g;
		foreach $g (@usergroups)
		{
			if ( $g == $group )
			{
				return 1;
				&log( "Authorization succeeded", 5 );
			}
		}
	}
	&log( "Authorization failed", 5 );
	return 0;

}

sub escapeQuotes
{
	my ($text) = @_;

	#$text =~ s/\"/\\\"/g;
	#$text =~ s/\'/\\\'/g;
	$text =~ s/\x93|\x94/"/g;
	$text =~ s/\"/&#034;/g;
	$text =~ s/\'/&#039;/g;
	$text =~ s/\\/\\\\/g;
	return $text;
}

sub unEscapeQuotes
{
	my ($text) = @_;

	#$text =~ s/\\\"/\"/g;
	#$text =~ s/\\\'/\'/g;
	$text =~ s/&#034;/\"/g;
	$text =~ s/&#039;/\'/g;
	$text =~ s/\\\\/\\/g;
	return $text;
}

sub escapeHtml
{
	my ($text) = @_;
	$text =~ s/&#039;/#039;/g;
	$text =~ s/&#034;/#034;/g;
	$text =~ s/&(.+?;)/&amp;$1/g;
	$text =~ s/#039;/&#039;/g;
	$text =~ s/#034;/&#034;/g;
	$text =~ s/\</&lt;/g;
	$text =~ s/\>/&gt;/g;
	return $text;
}

sub unescapeHtml
{
	my ($text) = @_;
	$text =~ s/&lt;/\</g;
	$text =~ s/&gt;/\>/g;
	return $text;
}

sub getMailPrefs
{
	my ($userid) = @_;
	unless ($userid) { return 0; }
	my ($sql) = "select email,bugtraqprefs from $c{db}{logintable} where $c{db}{logintablekey}=\"$userid\"";
	my (%res) = &doSql($sql);
	my (%return);
	$return{'email'} = $res{'email'}[0];
	@{ $return{'prefs'} } = split( / /, $res{'bugtraqprefs'}[0] );

	&log( "PREFS: for user $userid, got @{$return{'prefs'}} email: $return{'email'}", 5 );
	return %return;

}

sub sendMail
{
	my ( $to, $from, $subject, $text, $replyid , $xheaders ) = @_;
	warn("----------------\n");
	warn("$to\n");
	unless ( $to && $subject ) { return 0; }
	my ($reply);
	if ( $c{email}{reply} eq 'user' && $replyid > 1 )
	{
		$from = &getEmail("$replyid");
	}
	my ($contenttype) = $c{email}{mime} || 'text/plain';
	my (%mail) = (
		To             => "$to",
		From           => "$from",
		Subject        => "$subject",
		Message        => "$text",
		'content-type' => $contenttype
	);
	foreach my $x (keys(%{$xheaders}))
	{
		$mail{$x}=$$xheaders{$x};
	}
	my ($q) = new CGI;
	sendmail(%mail) || &log( "MAIL: couldn't send mail $Mail::Sendmail::error", 1 );
	&log( "MAIL: sent to $to, from: $from.", 5 );
	return 1;
}

sub getNumAttachments
{
	my ($recordid) = @_;
	my ($sql)      = "select attach_id from traq_attachments where record_id=\"$recordid\"";
	my (%res)      = doSql($sql);
	if (%res)
	{
		my ($num) = scalar( @{ $res{'attach_id'} } );
		return $num || "0";
	}
	else
	{
		return "0";
	}

}

sub saveReturnFields
{
	my ( $returnref, $userid ) = @_;
	my ($fields) = join( ",", @$returnref );
	my ($sql) = "update logins set bugreturnfields=\"$fields\",returnfields=\"$fields\" where userid=\"$userid\"";
	&doSql($sql);
}

sub getSavedReturnFields
{
	my ($userid) = @_;
	my (%res);
	%res = &doSql("select returnfields from logins where userid=\"$userid\"");
	if ( $res{'returnfields'}[0] )
	{
		return ( split( /,/, $res{'returnfields'}[0] ) );
	}
	else
	{
		return ( "status", "short_desc", "record_id" );
	}
}

sub getReturnFields
{
	my ( $q, $userid ) = @_;
	my (@fields);
	if ( $q->param('returnFields') )
	{
		@fields = split( /\^/, $q->param('returnFields') );
		return @fields;
	}
	if ( $q->param('return_id') )
	{
		push( @fields, "record_id" );
	}
	if ( $q->param('return_assigned') )
	{
		push( @fields, "assigned_to" );
	}
	if ( $q->param('return_target_date') )
	{
		push( @fields, "target_date" );
	}
	if ( $q->param('return_units_req') )
	{
		push( @fields, "units_req" );
	}
	if ( $q->param('return_cdate') )
	{
		push( @fields, "creation_ts" );
	}
	if ( $q->param('return_deltadate') )
	{
		push( @fields, "delta_ts" );
	}
	if ( $q->param('return_changedby') )
	{
		push( @fields, "changedby" );
	}
	if ( $q->param('return_pri') )
	{
		push( @fields, "priority" );
	}
	if ( $q->param('return_sev') )
	{
		push( @fields, "severity" );
	}
	if ( $q->param('return_qa') )
	{
		push( @fields, "qa_contact" );
	}
	if ( $q->param('return_tech') )
	{
		push( @fields, "tech_contact" );
	}
	if ( $q->param('return_reporter') )
	{
		push( @fields, "reporter" );
	}
	if ( $q->param('return_sum') )
	{
		push( @fields, "short_desc" );
	}
	if ( $q->param('return_plat') )
	{
		push( @fields, "bug_platform" );
	}
	if ( $q->param('return_comp') )
	{
		push( @fields, "componentid" );
	}
	if ( $q->param('return_version') )
	{
		push( @fields, "version" );
	}
	if ( $q->param('return_status') )
	{
		push( @fields, "status" );
	}
	if ( $q->param('return_project') )
	{
		push( @fields, "projectid" );
	}
	if ( $q->param('return_resolution') )
	{
		push( @fields, "resolution" );
	}
	if ( $q->param('return_whiteboard') )
	{
		push( @fields, "status_whiteboard" );
	}
	if ( $q->param('return_type') )
	{
		push( @fields, "type" );
	}
	if ( $q->param('return_target_milestone') )
	{
		push( @fields, "target_milestone" );
	}
	if ( $q->param('return_keyword') )
	{
		push( @fields, "keyword" );
	}
	if (@fields)
	{
		&saveReturnFields( \@fields, $userid );
	}
	else
	{
		@fields = &getSavedReturnFields($userid);
	}
	return @fields;
}

sub getKeywords
{
	my (@list) = @_;
	if (@list)
	{
		my ($keywords) = join( "','", @list );
		$keywords = "'" . $keywords . "'";

		my ($sql) = "select * from traq_keywords where keywordid in ($keywords) order by name";
		return ( &doSql($sql) );

	}
	else
	{
		my ($sql) = "select * from traq_keywords order by name";
		return ( &doSql($sql) );
	}
}

sub getRecordKeywords
{
	my ($rec) = shift;
	my (%res) = &doSql("select wrd.name from traq_keywords wrd, traq_keywordref ref where ref.record_id=$rec and wrd.keywordid=ref.keywordid order by wrd.name");
	my ($words);
	if (%res)
	{
		$words = join( ",", @{ $res{name} } );
	}
	else
	{
		$words = '';
	}
	return $words;

}

sub makeJs()
{
	my ( $projects, $type, $groups ) = @_;
	$type='';
	&log( "API: makeJs : " . join( '-', @$projects ) . ",$type," . join( '-', @$groups ), 7 );
	my ( $project, $js );
	$js = "";
	#$js .= "var menuhash=[];\n";

	#\nvar vers=[]; \nvar mile=[];\n";
	$js .= "menuhash['componentid']=[];\n";
	$js .= "menuhash['target_milestone']=[];\n";
	$js .= "menuhash['version']=[];\n";
	foreach $project (@$projects)
	{
		$js .= "menuhash['componentid'][$project] = [];\n";
		my (%projcomps) = &GetProjectComponents( $project, $type, @$groups );
		if (%projcomps)
		{
			&log( "DEBUG: got " . scalar( @{ $projcomps{componentid} } ) . " components for makeJs", 7 );
			for ( my ($i) = 0 ; $i < scalar( @{ $projcomps{'componentid'} } ) ; $i++ )
			{
				$js .= "menuhash['componentid'][$project][$i] = [];\n";
				$js .= "menuhash['componentid'][$project][$i][0] = \"$projcomps{'component'}[$i]\";\n";
				$js .= "menuhash['componentid'][$project][$i][1] = \"$projcomps{'componentid'}[$i]\";\n";
			}
		}
	}
	foreach $project (@$projects)
	{
		$js .= "menuhash['version'][$project] = [];\n";
		my (%projbuilds) = &getProjectBuildIds($project);
		if (%projbuilds)
		{
			&log( "DEBUG: got " . scalar( @{ $projbuilds{'value'} } ) . " buildids for makeJs", 7 );
			for ( my ($i) = 0 ; $i < scalar( @{ $projbuilds{'value'} } ) ; $i++ )
			{
				$js .= "menuhash['version'][$project][$i] = [];\n";
				$js .= "menuhash['version'][$project][$i][0] = \"$projbuilds{'value'}[$i]\";\n";
				$js .= "menuhash['version'][$project][$i][1] = \"$projbuilds{'value'}[$i]\";\n";
			}
		}
	}
	foreach $project (@$projects)
	{
		$js .= "menuhash['target_milestone'][$project] = [];\n";
		my (%projbuilds) = &getMilestones($project);
		if (%projbuilds)
		{
			&log( "DEBUG: got " . scalar( @{ $projbuilds{'milestoneid'} } ) . " milestones for makeJs", 7 );
			for ( my ($i) = 0 ; $i < scalar( @{ $projbuilds{'milestoneid'} } ) ; $i++ )
			{
				$js .= "menuhash['target_milestone'][$project][$i] = [];\n";
				$js .= "menuhash['target_milestone'][$project][$i][0] = \"$projbuilds{'milestone'}[$i]\";\n";
				$js .= "menuhash['target_milestone'][$project][$i][1] = \"$projbuilds{'milestoneid'}[$i]\";\n";
			}
		}
	}

	return $js;
}
#########################################
sub getProjectBuildIds
{
	my ($project) = @_;
	my ($sql);
	my (%res);
	if ($main::TASKS)
	{
		$sql = "select * from traq_menus where menuname=\"version\" and project=$project and rec_type like \"%task%\"";
	}
	else
	{
		$sql = "select * from traq_menus where menuname=\"version\" and project=$project and rec_type like \"%bug%\"";
	}
	%res = &doSql($sql);
	return %res;
}

##############################################################################
#
#  ReadConfig()
#
#  Usage: $hashref = &ReadConfig();
#
#  Reads in the startup params such as database name, host, username, and password
#  and returs a reference to a hash containing those setup params
##############################################################################
sub ReadConfig
{
	my %hash;
	$hash{'cgi_path'}               = "/piss/bug/";
	$hash{'query_template'}         = "$c{dir}{generaltemplates}/temp_query.tmpl";
	$hash{'query_results_template'} = "$c{dir}{generaltemplates}/query_results.tmpl";
	$hash{'user_template'}          = "$c{dir}{generaltemplates}/user_select.tmpl";
	$hash{'saved_query_template'}   = "$c{dir}{generaltemplates}/saved_queries.tmpl";

	# miscellaneous
	$hash{'num_of_booleans'} = 3;
	return \%hash;
}

#----------------------------------------------------------------------------------
sub getSavedOrderBy
{
	my ($user) = @_;
	my ($sql)  = "select order1,order2,order3 from logins where userid=\"$user\"";
	my (%res)  = &doSql($sql);
	my ($return);
	if ( $res{'order1'}[0] )
	{
		$return = $res{'order1'}[0];
	}
	else { return "rec.status"; }
	if ( $res{'order2'}[0] && $res{'order1'}[0] )
	{
		$return .= ", " . $res{'order2'}[0];
	}
	if ( $res{'order3'}[0] && $res{'order1'}[0] && $res{'order2'}[0] )
	{
		$return .= ", " . $res{'order3'}[0];
	}
	return $return;

}
##############################################################################
sub GetQueryName
{
	my ($q)     = @_;
	my $qname   = "";
	my $orderby = "rec.severity";
	$qname = $q->param('qname');
	my ($user) = &getUserId($q);
	$orderby = $q->param('orderby');
	unless ($orderby)
	{
		$orderby = &getSavedOrderBy($user);
	}
	else
	{
		$orderby = 'rec.status';
	}
	if ( $orderby eq "rec.assigned_to" )
	{
		$orderby = "log.last_name";
	}
	my (@foo);
	$foo[0] = $qname;
	$foo[1] = $orderby;
	return @foo;

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  GetPrevNextResults()
#
#  Usage: ($prev, $next) = &GetPrevNextResults($current_bug);
#
#  reads the cookie and gets a list of the saved queries contained therein
##############################################################################
sub GetPrevNextResults
{
	my ( $current, $userid ) = @_;
	my @prevnext;
	my $list;
	my $prev;
	my $next;
	my ($index);
	my $decoded;
	$decoded = &getResults($userid);
	my (@results)    = split( /,/, $decoded );
	my ($numresults) = scalar(@results);

	for ( my ($i) = 0 ; $i < scalar(@results) ; $i++ )
	{
		if ( $results[$i] == $current )
		{
			$index = $i + 1;
			last;
		}
	}
	$index = $index || "0";
	$decoded =~ /(\d*),$current/;
	$prev = $1;

	$decoded =~ /($current),(\d*)/;
	$next = $2;
	return ( $prev, $next, $index, $numresults );

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  GetCookieValue()
#
#  Usage: $result = &GetCookieValue($name);
#
#  reads the cookie and gets the variable you request by name, decoded
##############################################################################
sub GetCookieValue
{
	my ($name) = @_;
	my $value = "";

	# get the cookie named $name
	my $cookie = $ENV{'HTTP_COOKIE'};
	my @pieces = split( /\;/, $cookie );
	my $piece;
	foreach $piece (@pieces)
	{
		if ( $piece =~ /$name=(.*)/ )
		{
			$value = $1;
		}
	}
	my $decoded = &DecodeFromCookie($value);

	return $decoded;

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  EncodeForCookie()
#
#  Usage: $encoded = &EncodeForCookie($string);
#
#  converts "=", " ", ";", and "," so queries will fit in the cookie
#  THIS IS A CUSTOM ENCODING METHOD
##############################################################################
sub EncodeForCookie
{
	my ($my_string) = @_;

	# replace offending chars with innocuous equivalents
	$my_string =~ s/\;/\^\^semicolon\^\^/g;
	$my_string =~ s/ /\^\^space\^\^/g;
	$my_string =~ s/\,/\^\^comma\^\^/g;
	$my_string =~ s/\=/\^\^equals\^\^/g;

	#my($enc) = encode_base64($my_string);
	return $my_string;
}

#----------------------------------------------------------------------------------

##############################################################################
#
#  DecodeFromCookie()
#
#  Usage: $decoded = &DecodeFromCookie($string);
#
#  decode something stored in a cookie
#  THIS IS A CUSTOM ENCODING METHOD
##############################################################################
sub DecodeFromCookie
{
	my ($my_string) = @_;

	# replace innocuous equivalents with offending chars
	$my_string =~ s/\^\^semicolon\^\^/\;/g;
	$my_string =~ s/\^\^space\^\^/ /g;
	$my_string =~ s/\^\^comma\^\^/\,/g;
	$my_string =~ s/\^\^equals\^\^/\=/g;

	return $my_string;

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  ConvertMultiples() -- INTERNAL FUNCTION ONLY
#
#  Usage: $clause = &ConvertMultiples($type, $column_name, $string_to_split);
#
#  takes in a list of ids and the column and constructs part of a where clause
##############################################################################
sub ConvertMultiples
{
	my ( $type, $column, @list ) = @_;

	my $clause = "$column in (";

	if ( $type eq "num" )
	{
		my $item;
		foreach $item (@list)
		{
			$clause .= "$item,";
		}
	}
	else
	{
		my $item;
		foreach $item (@list)
		{
			$clause .= "\'$item\',";
		}
	}

	$clause =~ s/\,\Z/\)/;    # replace the last comma with an end parenthesis

	return $clause;

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  ConstructQuery()
#
#  Usage: $sql_statement = &ConstructQuery($dbref, *paramhash);
#
#  Takes in an associative array and converts keys and values
#  to parts of a larger where clause
#
#
#  THIS IS WHERE THE COMPLICATED QUERIES ARE MADE.
#
##############################################################################
sub ConstructQuery
{
	my ( $q, $userid, $usergroups ,$orderby ) = @_;

	my $db = $q->param('db_ref');
	my $status_clause;
	my @clauses;
	my %results;

	my @groups = @$usergroups;
	my ( $ff, $fromtick, $cctick, $dd );

	my $sql          = "select distinct rec.*,count(lkupdep.dependson) as children ";
	my $from_clause  = "from traq_records rec left join traq_dependencies lkupdep on rec.record_id=lkupdep.blocked ";
	my $where_clause = " where ";

	# get hash of field list for processing sql Assembly
	# will use this field list to 'walkthrough' fields to assemble sql query
	my (%fieldlist) = %{ $c{general}{label} };


    ### special query option to do a general query across several fields
    my($queryall)=$q->param('queryall');
    $queryall=~s/\s$//;
    if($queryall=~/\W/)
    {
		$from_clause =~ s/from/from traq_longdescs lng,/;
		push( @clauses, "lng.record_id = rec.record_id" );
		# setup new big OR query clause
		my($queryallclause)=" ( ";
		$queryallclause.=&AllWords( "rec.short_desc", $queryall );
		$queryallclause.=" or " . &AllWords( "rec.status_whiteboard", $queryall );
		$queryallclause.=" or " . &AllWords( "lng.thetext", $queryall );
		$queryallclause.=" ) ";
        push(@clauses,$queryallclause);   
    }

	#step through the roles and assemble sql for each role and role by group
	# and left joins for the roles to reference the usernames / sort
	my (@roleclauses);
	foreach $ff ( split( ',', $c{general}{rolemenu} ) )
	{
		if ( $q->param($ff) ne '' && $fieldlist{$ff}  )
		{
			$from_clause .= " left join logins lkup$ff on lkup$ff.userid=rec.$ff ";
			delete( $fieldlist{$ff} );
		}
		if ( $q->param($ff) ne '' )
		{
			&log( "ConstructQuery: assembling sql for $ff", 5 );
			push( @roleclauses, &ConvertMultiples( "num", $ff, $q->param($ff) ) );
		}

		# query by groups sql assembly
		if ( $q->param( $ff . 'group' ) ne '' )
		{
			&log( "ConstructQuery: assembling sql for $ff group", 5 );
			$from_clause .= "left join user_groups lkup$ff" . "group on lkup$ff" . "group.userid=rec.$ff";
			push( @roleclauses, " lkup$ff" . "group.groupid in (" . join( ',', $q->param( $ff . 'group' ) ) . ")" );
		}
	}

	# cc sql query
	if ( $q->param('cc') ne '' )
	{
		&log( "ConstructQuery: assembling sql for cc", 5 );
		my ($cc) = join( ',', $q->param('cc') );
		push( @roleclauses, "cc.who in ($cc)" );
		if ( !$cctick )
		{
			$from_clause .= " left join traq_cc cc on cc.record_id=rec.record_id";
			$cctick++;
		}
	}
	if ( $q->param('ccgroup') ne '' )
	{
		&log( "ConstructQuery: assembling sql for ccgroup", 5 );
		if ( !$cctick )
		{
			$from_clause .= " left join traq_cc cc on cc.record_id=rec.record_id";
			$cctick++;
		}
		push( @roleclauses, "(cc.who = grp.userid and grp.groupid in (" . join( ',', $q->param('ccgroup') ) . "))" );
	}
	if ( scalar(@roleclauses) )
	{
		my ($roleclause) = "(" . join( ( " " . $q->param('role_andor') . " " ), @roleclauses ) . ")";
		push( @clauses, $roleclause );
	}

	# Do special cases for $c{general}{externalfields}
	# query by ccgroups sql assembly
	foreach $ff ( split( ',', $c{general}{externalfields} ) )
	{
		delete( $fieldlist{$ff} );
	}

	# long_desc sql assembly
	if ( $q->param('long_desc') ne '' )
	{
		&log( "ConstructQuery: assembling sql for long_desc", 5 );
		my ($desc) = $q->param('long_desc');

		#my ($desc) = &escapeQuotes($q->param('long_desc'));
		if ( $q->param('long_desc_type') eq "substring" )
		{
			push( @clauses, "lng.thetext like \'\%$desc\%\'" );
		}
		elsif ( $q->param('long_desc_type') eq "casesubstring" )
		{
			push( @clauses, "lng.thetext like \'\%$desc\%\'" );
		}
		elsif ( $q->param('long_desc_type') eq "regexp" )
		{
			push( @clauses, "lng.thetext regexp \'$desc\'" );
		}
		elsif ( $q->param('long_desc_type') eq "notregexp" )
		{
			push( @clauses, "lng.thetext not regexp \'$desc\'" );
		}
		elsif ( $q->param('long_desc_type') eq "allwords" )
		{
			push( @clauses, &AllWords( "lng.thetext", $desc ) );
		}
		elsif ( $q->param('long_desc_type') eq "anywords" )
		{
			push( @clauses, &AnyWords( "lng.thetext", $desc ) );
		}
		push( @clauses, "lng.record_id = rec.record_id" ) unless $queryall;
		$from_clause .= ", traq_longdescs lng" unless $queryall;
	}

	# keywords sql assembly
	if ( $q->param('keywords') ne '' )
	{
		&log( "ConstructQuery: assembling sql for keywords", 5 );
		if ( $q->param('keywords_type') eq "none" )
		{
			my $key_col_name = "ky.keywordid not";    # becomes "key.keywordid not in (" in ConvertMultiples
			push( @clauses, &ConvertMultiples( "num", $key_col_name, $q->param('keywords') ) );
		}
		elsif ( $q->param('keywords_type') eq "all" )
		{
			my $keyword_clause = "";
			$keyword_clause = &AllNumbers( "ky.keywordid", $q->param('keywords') );
			push( @clauses, "$keyword_clause" );
		}
		else
		{
			my $key_col_name = "ky.keywordid";
			push( @clauses, &ConvertMultiples( "num", $key_col_name, $q->param('keywords') ) );
		}

		push( @clauses, "ky.record_id = rec.record_id" );
		$from_clause .= ", traq_keywordref ky";
	}

	# add attachment query sql
	if ( $q->param('attach_have') )
	{
		&log( "ConstructQuery: assembling sql for attachments", 5 );
		$from_clause .= ", traq_attachments att";
		my ($att) = $q->param('attach_have');
		if ( $att eq "Yes" )
		{
			push( @clauses, "att.record_id=rec.record_id" );
		}
		else
		{
			push( @clauses, "att.record_id!=rec.record_id" );
		}

	}

	# sql to return status_class (open,resolved,closed)
	if ( $q->param('status_class') )
	{
		my ($status_class) = $q->param('status_class');
		if ( $status_class eq 'open' )
		{
			push( @clauses, "((rec.status<$c{bugtraq}{resolved} and rec.type='bug') or (rec.status<$c{tasktraq}{closethreshold} and rec.type='task'))" );
		}
		if ( $status_class eq 'closed' )
		{
			push( @clauses, "((rec.status>=$c{bugtraq}{closethreshold} and rec.type='bug') or (rec.status>=$c{tasktraq}{closethreshold} and rec.type='task'))" );
		}
		if ( $status_class eq 'resolved' )
		{
			push( @clauses, "((rec.status=$c{bugtraq}{resolved} and rec.type='bug') or (rec.type='task'))" );
		}
	}

	# sql to only return 1 record type
	if ( $q->param('return_bugs') && $q->param('return_tasks') )
	{
	}
	elsif ( $q->param('return_bugs') )
	{
		push( @clauses, "rec.type=\"bug\"" );
	}
	elsif ( $q->param('return_tasks') )
	{
		push( @clauses, "rec.type=\"task\"" );
	}
	delete( $fieldlist{'type'} );

	# get list of fields that are menu based fields (in traq_menus)
	my (@menus) = split( ',', $c{general}{systemmenu} );
	push( @menus, split( ',', $c{general}{projectmenu} ) );

	# add special projecttraq fields that work the same as the menu fields but are not in traq_menus
	push( @menus, ( 'projectid', 'componentid', 'target_milestone' ) );

	# process sql assembly foreach field that is a menu
	foreach $ff (@menus)
	{
		my @ff=$q->param($ff);
		
		if($q->param($ff)=~/,/)
		{
			@ff=split(',',$q->param($ff));
		}
		if ( $fieldlist{$ff} && $q->param($ff) ne '' )
		{
			&log( "ConstructQuery: assembling sql for $ff", 5 );
			# put parameters into sql, first wrap any non-int's in quotes
			my ($values) = join ',', map 
			{
				if($_ eq '-null-')	
				{
					"''"
				}
				else
				{
					"'$_'" 
				}
			} @ff;
			if(grep /-null-/, @ff)
			{
				push( @clauses, " (rec.$ff in ($values) or rec.$ff is null )" );
			}
			else
			{
				push( @clauses, " rec.$ff in ($values) " );
			}
		}
		delete( $fieldlist{$ff} );
	}

	# process date based fields
	my (@dates) = split( ',', $c{general}{datefields} );
	
	foreach $ff (@dates)
	{
		my ($startdate) = $q->param( 'start_' . $ff );
		$startdate = &makeDate($startdate);
		my ($enddate) = $q->param( 'end_' . $ff );
		$enddate = &makeDate($enddate);
		if ($startdate)
		{
			&log( "ConstructQuery: assembling sql for $ff", 5 );
			push( @clauses, "rec.$ff >= \'$startdate 00:00:01\'" );
		}
		if ($enddate)
		{
			&log( "ConstructQuery: assembling sql for $ff", 5 );
			push( @clauses, "rec.$ff <= \'$enddate 23:59:59\'" );
		}
		delete( $fieldlist{$ff} );
	}

	# sql assembly for record_id lists
	if ( $q->param('record_id') ne '' )
	{
		&log( "ConstructQuery: assembling sql for record_id", 5 );
		my $bug_col_name;
		
		if ( $q->param('bug_id_type') eq "exclude" )
		{
			$bug_col_name = "rec.record_id not";    # becomes "rec.record_id not in (" in ConvertMultiples
		}
		else
		{
			$bug_col_name = "rec.record_id";
		}
		my ($recid) = $q->param('record_id');
		$recid =~ s/[BbTt]//g;
		$recid=~s/\s$//;

		my ($validcheck) = $recid;
		$validcheck =~ s/[,\s]//g;
		if ( $validcheck =~ /\D/ )
		{
			&doError('Invalid Record ID!');
		}
		if ( $recid =~ /\s/ && $recid !~ /,/ )
		{
			$recid =~ s/\s/,/g;
		}
		push( @clauses, "$bug_col_name in ($recid)" );
		delete( $fieldlist{record_id} );
	}

	# fields that are left are assumed to be basic string fields for query
	foreach $dd ( keys(%fieldlist) )
	{
		delete( $fieldlist{$dd} );
		if ( $q->param($dd) ne '' )
		{
			&log( "ConstructQuery: assembling sql for $dd", 5 );
			my ($like) = $q->param($dd);

			#my ($like) = &escapeQuotes($q->param($dd));
			if ( $q->param( $dd . '_type' ) eq "substring" )
			{
				push( @clauses, "rec.$dd like \'\%$like\%\'" );
			}
			elsif ( $q->param( $dd . '_type' ) eq "casesubstring" )
			{
				push( @clauses, "rec.$dd like \'\%$like\%\'" );
			}
			elsif ( $q->param( $dd . '_type' ) eq "regexp" )
			{
				push( @clauses, "rec.$dd regexp \'$like\'" );
			}
			elsif ( $q->param( $dd . '_type' ) eq "notregexp" )
			{
				push( @clauses, "rec.$dd not regexp \'$like\'" );
			}
			elsif ( $q->param( $dd . '_type' ) eq "allwords" )
			{
				push( @clauses, &AllWords( "rec.$dd", $like ) );
			}
			elsif ( $q->param( $dd . '_type' ) eq "anywords" )
			{
				push( @clauses, &AnyWords( "rec.$dd", $like ) );
			}
			else
			{
				push( @clauses, "rec.$dd like \'\%$like\%\'" );
			}

		}
	}
### Finished basic field query sql assembly

# assemble field changes sql
    my($changecheck)=0;
    if ( $q->param('chfield') ne '' )
    {
        my ($chfield) = $q->param('chfield');
        push( @clauses, "act.fieldname = \'$chfield\'" );
        $changecheck++;
    }
    if ( $q->param('chfield_from') ne '' )
    {
        my ($chfield) = $q->param('chfield_from');
        push( @clauses, "act.date >= \'$chfield 00:00:01 \'" );
        $changecheck++;
    }
    if ( $q->param('chfield_to') ne '' )
    {
        my ($chfield) = $q->param('chfield_to');
        push( @clauses, "act.date <= \'$chfield 23:59:59 \'" );
        $changecheck++;
    }
    if ( $q->param('changedin') ne '' )
    {
        my ($chfield) = $q->param('changedin');
        push( @clauses, "to_days(now()) - to_days(act.date) <= $chfield" );
        $changecheck++;
    }
    if ( $q->param('changeto') ne '' )
    {
        $q->param( 'changeto', &getSmartField( $q->param('chfield'), $q->param('changeto') ) );
        my ($chfield) = $q->param('changeto');
        push( @clauses, "act.newvalue=\"$chfield\"" );
        $changecheck++;
    }
    if ( $q->param('changefrom') ne '' )
    {
        $q->param( 'changefrom', &getSmartField( $q->param('chfield'), $q->param('changefrom') ) );
        my ($chfield) = $q->param('changefrom');
        push( @clauses, "act.oldvalue=\"$chfield\"" );
        $changecheck++;
    }
    if ( $q->param('changeby') ne '' )
    {
        my ($chfield) = $q->param('changeby');
        push( @clauses, "act.who=\"$chfield\"" );
        $changecheck++;
    }
    if($changecheck)
    {
        push( @clauses, "act.record_id = rec.record_id" );
        $from_clause .= ", traq_activity act";
    }

	#-----------------------------------------------------------------------------
	#	$q->param( 'from_clause', $from_clause );
	my ( $from_again, $boolean_clause ) = &ProcessBooleans($q);

	if ( $from_again ne '' )
	{
		$from_clause .= $from_again;
	}
	if ( $boolean_clause ne '' )
	{
		push( @clauses, $boolean_clause );
	}

	#-----------------------------------------------------------------------------
	# add join for boolean: 'was last changed by assigned_to /  up2date'
	$from_clause.= " left join traq_activity lastup  on (lastup.record_id=rec.record_id and lastup.date=rec.delta_ts)";
	$sql.= ", 	CASE WHEN lastup.who=rec.assigned_to THEN 1 ELSE 0 END as assignedmodified ";
	#-----------------------------------------------------------------------------
	$sql .= $from_clause;
	my $clause;
	unless(scalar(@clauses))
	{
		&doError("No search terms defined");
	}
	$where_clause .= join( " and ", @clauses );
	$sql          .= $where_clause;

	#-----------------------------------------------------------------------------
	# add the sort clause
	$sql .= " group by rec.record_id order by $orderby";

	#-----------------------------------------------------------------------------
	return $sql;

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  ProcessBooleans()  -- INTERNAL FUNCTION ONLY
#
#  Usage: ($from, $sql) = &ProcessBooleans(*paramhash);
#
#  Takes in an associative array and generates parts of the where clause
#  for each of the boolean fields that have been filled in
##############################################################################
sub ProcessBooleans
{
	my ($q) = @_;

	my $from         = $q->param('from_clause');
	my $sql          = "";
	my $where_clause = "(";
	my $hashref      = &ReadConfig();
	my $limit        = $$hashref{'num_of_booleans'};
	my $clause;
	my $from_clause;
	my $field;
	my $operator;
	my $value;
	my $type;

	my $i;
	for ( $i = 1 ; $i <= $limit ; $i++ )
	{
		$field    = $q->param("bool_field$i");
		$operator = $q->param("bool_operator$i");
		$value    = $q->param("bool_value$i");
		$type     = $q->param("bool_type$i");

		if ( ( $field ne 'none' ) && ( $operator ne 'none' ) && ( $value ne '' ) )
		{
			( $from_clause, $clause ) = &ProcessBoolean( $from, $field, $operator, $value );
			$where_clause .= $clause;
			$where_clause .= " $type ";
		}
	}
	$where_clause =~ s/ $type \Z//;    # remove extra bool_type at the end
	$where_clause =~ s/ or \)/\)/g;
	$where_clause =~ s/ and \)/\)/g;
	$where_clause .= ")";
	if ( $where_clause eq "()" )
	{                                  # if no booleans are present
		$where_clause = "";
	}

	return ( $from_clause, $where_clause );

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  ProcessBoolean()  -- INTERNAL FUNCTION ONLY
#
#  Usage: ($from_clause, $clause) = &ProcessBoolean($from_clause, $field, $operator, $value);
#
#  Takes in strings which represent a user's selection in the boolean section
#  of the query page.
##############################################################################
sub ProcessBoolean
{
	my ( $from_clause, $field, $operator, $value ) = @_;
	my $sql_operator;
	my $separator;
#TODO need to abstract out this field list into config somehow
	my @nums = (
		"groupset", "record_id", "projectid", "traq_dependencies.blocked", "traq_dependencies.dependson", "componentid", "priority", "assigned_to", "reporter",
		"target_milestone", "qa_contact", "tech_contact", "traq_attachments.ispatch"
	);
	my @is_field_num = grep( /$field/, @nums );
	my $is_field_num_res = @is_field_num;
	&log("TEST: $field:  $value = $is_field_num_res");
	if ( $is_field_num_res > 0 && $value !~ /\D/ )
	{
		$separator = "";
	}
	else
	{
		$separator = "'";
	}
	my $fieldname;
	if ( $field =~ /\./ || $field eq "target_milestone" )
	{
		$fieldname = $field;
	}
	else
	{
		$fieldname = "rec.$field";
	}
	$value = &getSmartValue( $fieldname, $value );
	my $clause;
	if ( $field eq "bug_depends" )
	{
		if ( !( $from_clause =~ /traq_dependencies/ ) )
		{
			$from_clause .= ", traq_dependencies dpnd";
		}
		$clause = "dpnd.dependson in ($value) and dpnd.blocked = rec.record_id";
	}
	elsif ( $field eq "lng.thetext" )
	{
		if ( !( $from_clause =~ /traq_longdescs lng/ ) )
		{
			$from_clause .= ", traq_longdescs lng";
		}
		$clause = "lng.thetext like \"%$value%\" and lng.record_id=rec.record_id";
	}
	elsif ( $field eq "bug_blocked" )
	{
		if ( !( $from_clause =~ /traq_dependencies/ ) )
		{
			$from_clause .= ", traq_dependencies dpnd";
		}
		$clause = "dpnd.blocked in ($value) and dpnd.dependson = rec.record_id";
	}
	elsif ( $operator eq "equals" )
	{
		$clause = "$fieldname = " . $separator . "$value" . $separator;
	}
	elsif ( $operator eq "notequals" )
	{
		$clause = "$fieldname <> " . $separator . "$value" . $separator;
	}
	elsif ( $operator eq "casesubstring" )
	{
		$clause = "$fieldname like \'\%$value\%\'";
	}
	elsif ( $operator eq "substring" )
	{
		$clause = "$fieldname like \'\%$value\%\'";
	}
	elsif ( $operator eq "notsubstring" )
	{
		$clause = "$fieldname not like \'\%$value\%\'";
	}
	elsif ( $operator eq "regexp" )
	{
		$clause = "$fieldname regexp \'$value\'";
	}
	elsif ( $operator eq "notregexp" )
	{
		$clause = "$fieldname not regexp \'$value\'";
	}
	elsif ( $operator eq "lessthan" )
	{
		$clause = "$fieldname < $separator$value$separator";
	}
	elsif ( $operator eq "greaterthan" )
	{
		$clause = "$fieldname > $separator$value$separator";
	}
	elsif ( $operator eq "anywords" )
	{
		$clause = &AnyWords( $fieldname, $value );
	}
	elsif ( $operator eq "allwords" )
	{
		$clause = &AllWords( $fieldname, $value );
	}
	elsif ( $operator eq "nowords" )
	{
		$clause = &NoWords( $fieldname, $value );
	}
	elsif ( $operator eq "changedbefore" )
	{
		if ( $from_clause =~ /traq_activity/ )
		{
			$clause = "act.fieldname = $field and act.date < '$value'";
		}
		else
		{
			$from_clause .= ", traq_activity act";
			$clause = "act.fieldname = $field and act.date < '$value' and act.record_id = rec.record_id";
		}
	}
	elsif ( $operator eq "changedafter" )
	{
		if ( $from_clause =~ /traq_activity/ )
		{
			$clause = "act.fieldname = $field and act.date > '$value'";
		}
		else
		{
			$from_clause .= ", traq_activity act";
			$clause = "act.fieldname = $field and act.date > '$value' and act.record_id = rec.record_id";
		}
	}
	elsif ( $operator eq "changedto" )
	{
		if ( $from_clause =~ /traq_activity/ )
		{
			$clause = "act.fieldname = $field and act.newvalue = '$value'";
		}
		else
		{
			$from_clause .= ", traq_activity act";
			$clause = "act.fieldname = $field and act.newvalue = '$value' and act.record_id = rec.record_id";
		}
	}
	elsif ( $operator eq "changedby" )
	{
		if ( $from_clause =~ /traq_activity/ )
		{
			$clause = "act.fieldname = $field and act.who = $value";
		}
		else
		{
			$from_clause .= ", traq_activity act";
			$clause = "act.fieldname = $field and act.who = $value and act.record_id = rec.record_id";
		}
	}
	if ( $field eq "target_milestone" )
	{
		if ($value)
		{
			if ( !( $from_clause =~ /traq_milestones/ ) )
			{
				$from_clause .= ", traq_milestones mil";
			}
			$clause =~ s/\w+ (.+)/mil\.milestone $1/;
			$clause .= " and mil.milestoneid=rec.target_milestone ";
		}
		else
		{
			$clause = " target_milestone=''";
		}
	}

	return ( $from_clause, $clause );
}

#----------------------------------------------------------------------------------

##############################################################################
#
#  AnyWords()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $sql_clause = &AnyWords($column, $string);
#
#  creates a sub-clause wherein any word in $string are matched
#
##############################################################################
sub AnyWords
{
	my ( $column, $search_string ) = @_;

	my @words = split( /\W+/, $search_string );

	my $sql = "";
	my $word;
	foreach $word (@words)
	{
		$sql .= "$column like '%$word%' or ";
	}
	$sql =~ s/ or \Z//;    # remove extra " or "

	return "($sql)";

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  NoWords()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $sql_clause = &NoWords($column, $string);
#
#  creates a sub-clause wherein no words in $string are matched
#
##############################################################################
sub NoWords
{
	my ( $column, $search_string ) = @_;

	my @words = split( /\W+/, $search_string );

	my $sql = "";
	my $word;
	foreach $word (@words)
	{
		$sql .= "$column not like '%$word%' and ";
	}
	$sql =~ s/ and \Z//;    # remove extra " and "

	return "($sql)";

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  AllNumbers()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $sql_clause = &AllNumbers($column, $string);
#
#  creates a sub-clause wherein all words in $string are matched
#
##############################################################################
sub AllNumbers
{
	my ( $column, @search_string ) = @_;

	my @nums = @search_string;

	my $sql = "";
	my $num;
	foreach $num (@nums)
	{
		$sql .= "$column = $num and ";
	}
	$sql =~ s/ and \Z//;    # remove extra " and "

	return "($sql)";

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  AllWords()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $sql_clause = &AllWords($column, $string);
#
#  creates a sub-clause wherein all words in $string are matched
#
##############################################################################
sub AllWords
{
	my ( $column, $search_string ) = @_;

	my @words = split( /\s/, $search_string );

	my $sql = "";
	my $word;
	foreach $word (@words)
	{
		$sql .= "$column like '%$word%' and ";
	}
	$sql =~ s/ and \Z//;    # remove extra " and "

	return "($sql)";

}

#----------------------------------------------------------------------------------

##############################################################################
#
#  SeparateMenus()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $hashref = &SeparateMenus(\%results, $db_ref);
#
#  Takes in a reference to an associative array and a DB handle
#  and get all rows from MENUS table
#
##############################################################################
sub SeparateMenus
{
	my (%localhash) = @_;
	my $max_num = 0;
	my %newhash;

	# find out how many rows we have - I am being extra sure here...
	#-------------------------------------------------
	my $column;
	foreach $column ( keys(%localhash) )
	{
		my $num_of_columns = @{ $localhash{$column} };
		if ( $num_of_columns > $max_num )
		{
			$max_num = $num_of_columns;
		}
	}
	my $x;
	for ( $x = 0 ; $x < $max_num ; $x++ )
	{
		my $disname = $localhash{'menuname'}[$x] . "_display";
		my $valname = $localhash{'menuname'}[$x] . "_value";
		push( @{ $newhash{$disname} }, $localhash{'display_value'}[$x] );
		push( @{ $newhash{$valname} }, $localhash{'value'}[$x] );
	}

	return %newhash;
}

#----------------------------------------------------------------------------------

##############################################################################
#
#  GetMenus()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $hashref = &GetMenus(\%results, $db_ref);
#
#  Takes in a reference to an associative array and a DB handle
#  and get all rows from MENUS table
#
##############################################################################
sub GetMenus
{
	my ( $sql_string, $x );
	if ( $main::TASKS || $c{cache}{currenttype} eq 'task' )
	{
		$x          = "task";
		$sql_string = "select distinct menuname,display_value,value from traq_menus where rec_type like \"%task%\" order by value";
	}
	else
	{
		$x          = "bug";
		$sql_string = "select distinct menuname,display_value,value from traq_menus where rec_type like \"%bug%\" order by value";
	}
	my (%pres) = &doSql("select distinct menuname,display_value, value from traq_menus where menuname=\"status\" and rec_type like \"%$x%\"");
	my ( %pres2, $value, $i );
	my (@values) = @{ $pres{'value'} };
	@values = sort { $a <=> $b } @values;
	$i = 0;
	foreach $value (@values)
	{
		$pres2{'value'}[$i]    = $value;
		$pres2{'menuname'}[$i] = "status";
		for ( my ($ii) = 0 ; $i < scalar( @{ $pres{'value'} } ) ; $ii++ )
		{
			if ( $pres{'value'}[$ii] == $value )
			{
				$pres2{'display_value'}[$i] = $pres{'display_value'}[$ii];
				last;
			}
		}
		$i++;
	}
	my (%res) = &doSql($sql_string);
	%res = &SeparateMenus(%res);
	my (%res2) = &SeparateMenus(%pres2);
	%res = &mergeHashes( %res, %res2 );
	return %res;
}

#----------------------------------------------------------------------------------
##############################################################################
sub GetEmployeeList
{
	my ($full)     = @_;
	my ($complete) = " and userid > 1 ";
	$complete = "" if $full;
	my ($sql) =
"select $c{db}{logintablekey},first_name,last_name from $c{db}{logintable} where active=\"Yes\" and last_name like \"%_%\" $complete order by $c{useraccount}{sortname}";
	my (%res) = &doSql($sql);
	my (%newhash);
	my ($hashref) = \%newhash;
	my ( $first, $last, $id, $num );

	for ( $num = 0 ; $num < scalar( @{ $res{'last_name'} } ) ; $num++ )
	{
		if ( $c{useraccount}{sortname} eq 'last_name' )
		{
			$$hashref{'EMP_NAME'}[$num] = $res{'last_name'}[$num] . ", " . $res{'first_name'}[$num];
		}
		else
		{
			$$hashref{'EMP_NAME'}[$num] = $res{'first_name'}[$num] . ' ' . $res{'last_name'}[$num];
		}
		$$hashref{'EMP_ID'}[$num] = $res{ $c{db}{logintablekey} }[$num];
	}
	return %newhash;
}
##############################################################################

##############################################################################
#
#  GetUserProjects()
#
#  Usage: $hashref = &GetUserProjects(\%results, $db_ref, @groups);
#
#  Takes in a user's groups and gets all records with those groups in acl_traq_components
#
##############################################################################
sub GetUserProjects
{
	my ( $hashref, $dbref, @groups ) = @_;
	return getAuthorizedProjects( '', \@groups );
}

#----------------------------------------------------------------------------------
##############################################################################
#
#  GetJustUserRecords()  -- INTERNAL FUNCTION ONLY
#
#  Usage: @records = &GetJustUserRecords(\%results, $db_ref, @groups);
#
#  Takes in a user's groups and gets all records with those groups in acl_traq_records
#
##############################################################################
sub GetJustUserRecords
{
	my ( $hashref, $dbref, @groups ) = @_;
	my $sql_string = "select record_id from acl_traq_records where groupid in (";
	my $grp;
	foreach $grp (@groups)
	{
		$sql_string .= "$grp,";
	}
	$sql_string =~ s/\,\Z//;    # always one more comma than we need
	$sql_string .= ")";

	my (%res) = &doSql( $sql_string, "PRO" );

	my @records = @{ $res{'record_id'} };
	return @records;
}

##############################################################################
#
#  GetUserGroups()  -- INTERNAL FUNCTION ONLY
#
#  Usage: @groups = &GetUserGroups($userid, \%results, $db_ref);
#
#  gets all of the groups this user is associated with
#
##############################################################################
# NEED TO DEPRECATE
sub GetUserGroups
{
	my ( $user, $hashref, $dbref ) = @_;
	return &getGroupsFromEmployeeId($user);
}

#----------------------------------------------------------------------------------
sub GetProjectComponents
{
	my ( $project, $type, @groups ) = @_;
	my ($sql_string);
	$sql_string = "select distinct cmp.* from traq_project prj,traq_components cmp, acl_traq_components xrf";
	if ( $type eq 'task' )
	{
		$sql_string .= " where cmp.projectid=$project and prj.rec_types like \"%task%\" and cmp.rec_type like \"%task%\"";
	}
	elsif ( $type eq 'bug' )
	{
		$sql_string .= " where prj.projectid=cmp.projectid and prj.rec_types like \"%bug%\" and cmp.rec_type like \"%bug%\"";
	}
	else
	{
		$sql_string .= " where prj.projectid=cmp.projectid ";
	}

	$sql_string .= " and cmp.projectid=$project";
	$sql_string .= " and cmp.componentid = xrf.componentid and cmp.projectid=$project and xrf.groupid in (";
	my $grp;
	foreach $grp (@groups)
	{
		$sql_string .= "$grp,";
	}
	$sql_string =~ s/\,\Z//;    # always one more comma than we need
	$sql_string .= ") order by component";
	my (%res) = &doSql($sql_string);
	return %res;
}

##############################################################################
#
#  GetUserComponents()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $hashref = &GetUserComponents(\%results, $db_ref, @groups);
#
#  Takes in a user's groups and gets all records with those groups in acl_traq_components
#
##############################################################################
sub GetUserComponents
{
	my ( $groupref, $projectid, $rec_type ) = @_;
	my (@groups) = @{$groupref};
	my $sql_string = "select distinct cmp.* from traq_components cmp, acl_traq_components xrf";
	if ($projectid)
	{
		$sql_string .= " where cmp.componentid = xrf.componentid and cmp.projectid=$projectid xrf.groupid in (";
	}
	else
	{
		$sql_string .= " where cmp.componentid = xrf.componentid and xrf.groupid in (";
	}
	my $grp;
	foreach $grp (@groups)
	{
		$sql_string .= "$grp,";
	}
	$sql_string =~ s/\,\Z//;    # always one more comma than we need
	$sql_string .= ") and rec_type like \"%" . $rec_type . "%\" order by component";
	my (%res) = &doSql($sql_string);
	&log("SQL: $sql_string",7);

	return %res;
}

#----------------------------------------------------------------------------------

##############################################################################
#
#  GetVersions()  -- INTERNAL FUNCTION ONLY
#
#  Usage: $hashref = &GetVersions(\%results, $db_ref);
#
#  Takes in a reference to an associative array and a DB handle
#  and get all rows from PROJECTS table
#
##############################################################################
sub GetVersions
{
	my ( $hashref, $dbref ) = @_;
	my $sql_string = "select distinct(version) from traq_records";

	my (%res) = &doSql($sql_string);

	return %res;
}

#----------------------------------------------------------------------------------
sub getSmartValue
{
	my ( $fieldname, $value ) = @_;
	&log( "getting smart value for $fieldname value: $value", 6 );

	#	if($fieldname =~ /component/i) {
	#		return &
	#	getComponentFromValue($value);
	#	}
	my ($tmp);
	my (@roles) = split( ',', $c{general}{rolemenu} );
	push( @roles, 'cc' );
	if ( grep( /^$fieldname$/, @roles ) )
	{
		return &getEmployeeIdFromUnixName($value);
	}
	if ( $fieldname =~ /^projectid$/ )
	{
		return &getProjectIdFromName($value);
	}
	my (@menus) = split( ',', $c{general}{systemmenu} );
	push( @menus, split( ',', $c{general}{projectmenu} ) );
	$fieldname =~ s/^rec\.//g;
	if ( grep( /^$fieldname$/, @menus ) )
	{
		if ( $value =~ /\w+/ )
		{
			$value = &getMenuValue( "0", $fieldname, $value );
		}
	}
	return $value;
}

sub getComponentFromValue
{
	&log("PRO: getComponentFromValue") if $c{profile};
	my ($val,$projectid) = @_;
	my($sql)="select componentid from traq_components where component = \"$val\"";
	if($projectid)
	{
	   $sql.=" and projectid=$projectid";
	}
	my (%res) = &doSql($sql);
	return $res{'componentid'}[0];
}

sub getComponentNameFromId
{
	my ($id,$err) = @_;
	my($value);
	unless ($id)
	{
	   if($err)
	   {
	    return "Error: invalid componentid";
	   }
	   else
	   {
		return '';
	   }
	}
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "component=$id=name";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "component-$c{session}{key}" } );
		$value  = $cache->get($lookup);
		if ( not defined $value )
		{
			&log( "DEBUG: cache lookup failed for $lookup, will repopulate cache", 7 );
			&populateComponentCache();
			$value = $cache->get($lookup);
		}
	}
	else
	{
		my (%res) = &doSql("select component from traq_components where componentid = \"$id\"");
		$value= $res{'component'}[0];
	}
    if($err && !$value)
    {
        return "Error: invalid componentid";
    }
    else
    {
        return $value;
    }

}

sub getProjectIdFromName
{
	my ($name) = @_;
	my (%res)  = &doSql("select projectid from traq_project where project =\"$name\"");
	return $res{'projectid'}[0];
}

sub isProjectOwner
{
	my ( $userid, $projectid ) = @_;
	my ($projectownergroup) = &getProjectOwnerGroup($projectid);
	my (@groups)            = &getGroupsFromEmployeeId($userid);
	unless ( grep( /$projectownergroup/, @groups ) )
	{
		return 0;
	}
	return 1;
}

sub getProjectOwnerGroup
{
	my ($project)     = @_;
	my ($projectname) = &getProjectNameFromId($project);
	my ($groupname)   = $projectname . "-owners";
	my (%res)         = &doSql("select groupid from groups where groupname=\"$groupname\"");
	&log( "owner group for $project is $res{'groupid'}[0]", 5 );
	return $res{'groupid'}[0];
}

sub getServices
{
	my (@groups) = @_;
	my ($sql)    =
"select distinct prj.project as svc_project, prj.projectid as svc_projectid, prj.description as svc_description from traq_project prj, acl_traq_projects xrf where prj.projectid=xrf.projectid and prj.type=\"service\" and (prj.archive is null or prj.archive=0) and xrf.groupid in (0";
	my $grp;
	foreach $grp (@groups)
	{
		$sql .= ",$grp";
	}

	#$sql =~ s/\,\Z//;  # always one more comma than we need
	$sql .= ") order by project";
	&log("SQL: $sql",7) ;
	my (%res) = doSql($sql);

	return %res;
}

sub getAuthorizedProjects
{
	my ( $type, $groupref, $rec_type, $admin ) = @_;
	my (@groups) = @{$groupref};
	my $sql_string = "select distinct prj.* from traq_project prj, acl_traq_projects xrf";
	$sql_string .= " where prj.projectid = xrf.projectid";
	if ($type)
	{
		$sql_string .= " and prj.type=\"$type\"";
	}
	if ($rec_type)
	{
		$sql_string .= " and prj.rec_types like \"%" . $rec_type . "%\"";
	}
	unless ($admin)
	{
		$sql_string .= " and (prj.archive is null or prj.archive=0)";
	}
	$sql_string .= "  and xrf.groupid in (0 ";
	my $grp;
	foreach $grp (@groups)
	{
		$sql_string .= ",$grp";
	}

	#$sql_string =~ s/\,\Z//;  # always one more comma than we need
	$sql_string .= ") order by project";
	&log("SQL: $sql_string",7);

	my (%res) = &doSql($sql_string);

	return %res;
}

sub getEmail
{
	my ($userid) = @_;
	my ( $item, $i );
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "user=$userid=email";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "user-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&log( "DEBUG: cache lookup failed for $lookup.  will repopulate cache", 7 );
			&populateUserCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my (%res) = &doSql("select email from logins where userid=$userid");
		if(%res)
		{
			return $res{'email'}[0];
		}
		else
		{
				return;
		}
	}
}

sub getUserDetails
{
	my ($userid) = @_;
	my (%res)    = &doSql("select * from logins where userid=$userid");
	$res{'USERNAME'}[0] = $res{'last_name'}[0] . ", " . $res{'first_name'}[0];
	if ( $res{'active'}[0] eq "Yes" )
	{
		$res{'yes'}[0] = "checked";
	}
	else
	{
		$res{'no'}[0] = "checked";
	}
	return %res;
}
sub getUserIDfromUsername
{
    my($username)=@_;
    unless($username)
    {
        return 'Error - invalid username';
    }
	my (%res)    = &doSql("select userid from logins where username='$username'");
    unless($res{userid}[0])
    {
        return 'Error - invalid username';
    }
    return $res{userid}[0];
}

sub isAdministrator
{
	my ( $uid, $cgi ) = @_;
	my (@groups) = &getGroupsFromEmployeeId($uid);
	unless ( grep( /^1$/, @groups ) )
	{
		return 0;
	}
	return 1;

}

sub canEditField
{
	my ( $userid, $field, $recordref ) = @_;
	my ( $item, %rehash, $i, $value );
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "user=$userid=recordeditprivs";
		my ($cache) = new Cache::FileCache( { 'namespace' => "user-$c{session}{key}" } );
		$value = $cache->get($lookup);
		if ( !$value )
		{
			&log( "DEBUG: cache lookup failed for $lookup.  will repopulate cache", 7 );
			&populateUserCache();
			$value = $cache->get($lookup);
		}
	}
	else
	{
		my (%res) = &doSql("select recordeditprivs from logins where userid=\"$userid\"");
		$value = $res{'recordeditprivs'}[0];
	}
	my (@fields) = split( / /, $value );
#	&log( "DEBUG: receditprivs - $value - " . join( '*', @fields ) );
	if ( grep( /^$field$/, @fields ) || grep( /all/, @fields ) )
	{
		return 1;
	}
	else
	{
		&log( "user $userid not authorized to edit field $field", 5 );
		return 0;
	}
}
##############################################################
sub mergeHashes
{
	my ( %one, %two ) = @_;
	return %one;
}

sub isValidRecord
{
	my ($rec) = shift;
	my (%res) = &doSql("select * from traq_records where record_id=$rec");
	unless ( $res{'record_id'}[0] )
	{
		return 0;
	}
	return 1;
}

sub isGroupAdmin
{
	my ( $userid, $group, $q ) = @_;
	if ( &isAdministrator( $userid, $q ) ) { return 1; }

	my (%groupname)  = &doSql("select groupname from groups where groupid=$group");
	my ($groupname)  = $groupname{groupname}[0];
	my (@usergroups) = &getGroupsFromEmployeeId($userid);
	if ( $groupname =~ /owners/ )
	{
		if ( grep( /$group/, @usergroups ) )
		{
			return 1;
		}
	}
	else
	{
		my ($ownergroupname) = $groupname . "-owners";
		my (%res)            = &doSql("select groupid from groups where groupname=\"$ownergroupname\"");
		my ($ownergroupid)   = $res{groupid}[0];
		if ( grep( /$ownergroupid/, @usergroups ) )
		{
			return 1;
		}

	}
	return 0;
}

sub isProjectAdmin
{
	my ( $user, $pid ) = @_;
	if ( &isAdministrator($user) ) { return 1; }
	my ($ownergroupid) = &getProjectOwnerGroup($pid);
	my (@groups)       = &getGroupsFromEmployeeId($user);
	if ( grep( /^$ownergroupid$/, @groups ) ) { return 1; }
	else { return 0; }
}

sub getProjectName
{
	my ($id)  = shift;
	my (%res) = &doSql("select project from traq_project where projectid=$id");
	return $res{'project'}[0];
}

sub getProjectGroups
{
	my ($p)   = shift;
	my (%res) = &doSql("select groupid from acl_traq_projects where projectid=$p");
	return @{ $res{groupid} };
}

sub getNewQueryId
{
	my ($uid) = shift;
	my (%res) = doSql('select queryid from traq_queries order by queryid desc limit 1');
	return ( $res{queryid}[0] + 1 );
}

sub getQuery
{
	my ( $queryid, $userid ) = @_;
	&log("QUERY: looking for previous query for queryid: $queryid") if $c{debug};
	my ($sql) = "select * from traq_queries where queryid=$queryid";
	my (%res) = &doSql($sql);
	if ( $res{queryid}[0] )
	{
		&log("QUERY: found $res{query}[0]") if $c{debug};
		return ( $res{query}[0], $res{sortorder}[0], $res{url_string}[0] );
	}
}

# Saves a query into the traq_queries table to be accessed later by user in same session
sub saveQuery
{
	my ( $userid, $queryid, $sql, $orderby, $url_string ) = @_;
	$sql        =~ s/order by .+//;
	$sql        =~ s/'/\\'/g;
	$sql        =~ s/"/\\"/g;
	$url_string =~ s/'/\\'/g;
	$url_string =~ s/"/\\"/g;
	&doSql("delete from traq_queries where userid=$userid and queryid=$queryid");
	my ($do) = "insert into traq_queries set userid=$userid,queryid=$queryid,query=\'$sql\',expire=now(),sortorder=\"$orderby\",url_string=\"$url_string\"";
	&log("QUERY: inserting query $do") if $c{debug};
	&doSql($do);
}

sub getPreferredOrder
{
	my ($userid) = shift;
	my (%res)    = &doSql("select order1,order2,order3 from logins where userid=$userid");
	my ($ret);
	if ( $res{order1}[0] )
	{
		$ret .= "$res{order1}[0]";
	}
	if ( $res{order2}[0] )
	{
		$ret .= ",$res{order1}[0]";
	}
	if ( $res{order3}[0] )
	{
		$ret .= ",$res{order1}[0]";
	}
	return $ret;
}

sub getLastChangedBy
{
	my ($recordid) = shift;
	my (%res)      = &doSql("select * from traq_activity where record_id=$recordid order by date desc");
	return $res{who}[0];
}

sub isActive
{
	my ($id)  = shift;
	my (%res) = &doSql("select active from logins where userid=$id");
	if ( $res{active}[0] =~ /Yes/i )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

########################################################################
sub basicHashto64
{
	my ( $textblob, %hash, $key );
	%hash     = @_;
	$textblob = "";
	foreach $key ( keys %hash )
	{
		$textblob .= "$key:";
		$hash{$key} =~ s/\n//g;
		$hash{$key} =~ s/://g;
		$textblob .= $hash{$key} . "\n";
	}
	return encode_base64($textblob);
}
########################################################################
sub basicHashfrom64
{
	my ($textblob) = @_;
	my ( %hash, $key, @list1, @list2, $var );
	$textblob = decode_base64($textblob);
	@list1 = split( /\n/, $textblob );
	foreach $var (@list1)
	{
		@list2      = split( /:/, $var );
		$key        = $list2[0];
		$hash{$key} = $list2[1];
	}
	return %hash;
}

sub secureRecordGet
{
	my ( $sql, $userid ) = @_;
	my (@usergroups) = &getGroupsFromEmployeeId($userid);

	my ($secsql) = " and acl.record_id=rec.record_id and acl.groupid in ( ";
	my $grp;
	foreach $grp (@usergroups)
	{
		$secsql .= "$grp,";
	}
	$secsql =~ s/\,\Z//;    # always one more comma than we need
	$secsql .= ")";

	$sql =~ s/from (.+)/from acl_traq_records acl, $1/;
	if ( $sql =~ /group by/ )
	{
		$sql =~ s/group by/ $secsql group by/;
	}
	else
	{
		$sql =~ s/order by/ $secsql order by/;
	}
	my (%res) = &doSql($sql);
	&log("Secure query: $sql",5);
	return %res;
}

##############################################################################
#
#  emailConfirmation()
#
#  Usage: &emailConfirmation(\%emailSettings)
#
#  Send out an email confirmation.
#  %emailSettings is a hash of email attributes.
#
##############################################################################
sub emailConfirmation()
{
	my ($params) = @_;
	my (%params) = %{$params};

	# Set record date fields
	$params{record}{creation_ts} = $params{originalrecord}{creation_ts} || &time_now;
	$params{record}{delta_ts}    = &time_now;

	#return $params{record}{assigned_to};
	my ( @associates, %prefhash, $pref, $field, $role, @recipientlist, $email_address );

	my (%rolelookup);

	#	Get the email preferences of everyone in roles that might receive this email
	if ( $params{record}{cc} )
	{
		@associates = @{ $params{record}{cc} };
	}
	if ( $params{originalrecord}{cc} )
	{
		@associates = @{ $params{originalrecord}{cc} };
	}
	foreach $field ( split( ',', $c{general}{rolemenu} ) )
	{
		push( @associates, $params{record}{$field} );
		push( @associates, $params{originalrecord}{$field} ) if($params{originalrecord}{$field});
	}
	foreach $field ( keys(%params) )
	{
		$role .= $field . " ";
	}
	my (@projCC) = split( ',', &supportingFunctions::getProjectidCC( $params{record}{projectid} ) );
	my (@compCC) = split( ',', &supportingFunctions::getComponentidCC( $params{record}{componentid} ) );
	push( @associates, @projCC );
	push( @associates, @compCC );
	my ($associates) = join( ',', @associates );

	$associates =~ s/,+/,/g;
	$associates =~ s/^,//g;
	&log("DEBUG: userid list for email:  $associates",6);
	my (%emailprefs);
	my (%lkup);
	if ( $c{cache}{usecache} )
	{
		my ($cache) = new Cache::FileCache( { 'namespace' => "user-$c{session}{key}" } );
		my ($i) = 0;
		my ($item);
		foreach $item ( split( ',', $associates ) )
		{
			my ($value) = $cache->get("user=$item=first_name");
			if ( not defined $value )
			{
				&log( "DEBUG: cache lookup failed for user=$item=first_name. will repopulate cache", 7 );
				&populateUserCache();
			}

			# Check that item exists and only move forward if we haven't already processed
			# (sql string in 'else' uses 'where in' to take care of duplicate $item's
			if ( $item && !$lkup{$item} )
			{
				$emailprefs{userid}[$i]       = $cache->get("user=$item=userid");
				$emailprefs{email}[$i]        = $cache->get("user=$item=email");
				$emailprefs{first_name}[$i]   = $cache->get("user=$item=first_name");
				$emailprefs{last_name}[$i]    = $cache->get("user=$item=last_name");
				$emailprefs{username}[$i]     = $cache->get("user=$item=username");
				$emailprefs{bugtraqprefs}[$i] = $cache->get("user=$item=bugtraqprefs");
				$emailprefs{active}[$i]       = $cache->get("user=$item=active");
				$i++;
				$lkup{$item}++;
			}
		}
	}
	else
	{
		%emailprefs = &doSql("select username,first_name,last_name,userid,email,bugtraqprefs,active from logins where userid in ($associates)");
	}

	# do activity filters notification emails
	my ( $key, $match );

	my (%activity_filters);
	if ( $c{email}{notification} )    # if there are notifications defined in the config file
	{
		%activity_filters = %{ $c{email}{notification} };

		# loop through special email notification settings
		foreach $key ( keys %activity_filters )
		{
			$match = 0;
			my (@filters) = values( %{ $activity_filters{$key} } );
			for ( my ($i) = 0 ; $i < scalar(@filters) ; $i++ )
			{                         # check each filter for match
				if (
					$c{ $params{record}{recordtype} . 'traq' }{label}{ $filters[$i][0] }
					&& (
						( $params{originalrecord}{ $filters[$i][0] } ne $params{record}{ $filters[$i][0] } && $params{change_type} ne 'created' )
						|| (   $params{change_type} eq 'created'
							&& $params{record}{ $filters[$i][0] } )
					)
					&& (
						$filters[$i][1] eq '*'
						|| (   $filters[$i][1] eq '+'
							&& $params{record}{ $filters[$i][0] } eq $filters[$i][2] )
						|| (   $filters[$i][1] eq '-'
							&& $params{originalrecord}{ $filters[$i][0] } eq $filters[$i][2] )
					)
				  )
				{
					$match++;
					&log( "DEBUG: special notification match for $key : " . join( ',', @{ $filters[$i] } ), 7 );
				}
			}    # check each filter for match
			if ( $match eq scalar(@filters) )
			{
				push( @recipientlist, $key );
				$rolelookup{$key} = 'Notify';
			}
		}    # loop through special email notification settings
	}    # if there are notifications in the config file.

	#	Ensure that the change_type parameter has been set
	if ( $params{change_type} )
	{

		#	Loop through the list of possible email recipients
		for ( my ($i) = 0 ; $i < scalar( @{ $emailprefs{userid} } ) ; $i++ )
		{
			my (@preflist) = split( " ", $emailprefs{bugtraqprefs}[$i] );

			#	Bail if this user asked not to be notifed of their own changes
			if ( $emailprefs{userid}[$i] eq $params{change_userid} && grep( /noselfmail/, @preflist ) )
			{
				next;
			}

			my (@notifylist) = ();    # List of email recipients

			# check for and add project and component CC's
			if ( grep( /^$emailprefs{userid}[$i]?/, @projCC ) )
			{
				push( @notifylist, ( $c{ $params{record}{recordtype} . 'traq' }{label}{projectid} . ' CC' ) );
				$rolelookup{ $emailprefs{email}[$i] } = $c{ $params{record}{recordtype} . 'traq' }{label}{projectid} . ' CC';
			}
			if ( grep( /^$emailprefs{userid}[$i]?/, @compCC ) )
			{
				push( @notifylist, ( $c{ $params{record}{recordtype} . 'traq' }{label}{componentid} . ' CC' ) );
				$rolelookup{ $emailprefs{email}[$i] } = $c{ $params{record}{recordtype} . 'traq' }{label}{componentid} . ' CC';
			}

			if ( $params{record}{cc} )    # Handle the email CC's
			{
				my @ccroles =@{$params{record}{cc}};
				if($params{orginalrecord}{cc})  #  Add CC's from original record
				{
					push(@ccroles,@{$params{originalrecord}{cc}});
				}
				foreach $role ( @ccroles )    # For each CC
				{
					my ($x) = 0;
					foreach $field ( keys %{ $params{changes} } )
					{
						my ($prefcheck) = "email_CC_" . $field;
						if ( grep( /$prefcheck/, @preflist ) )
						{
							$x++;
						}
					}
					my ($prefcheck) = "email_CC_Other";
					if ( grep( /$prefcheck/, @preflist ) && scalar( keys( %{ $params{changes} } ) ) )
					{
						$x++;
					}
					if ($x)
					{
						push( @notifylist, ( $c{ $params{record}{recordtype} . 'traq' }{label}{'cc'} ) );
					}
					$rolelookup{ $emailprefs{email}[$i] } = 'CC';
				}    #	For each CC
			}    #	If there are CC's

			#	Loop through the roles
			foreach $role ( split( ',', $c{general}{rolemenu} ) )
			{
				my ($x) = 0;
				foreach $field ( keys %{ $params{changes} } )
				{
					my ($prefcheck) = "email_" . $role . "_" . $field;
					if ( grep( /$prefcheck/, @preflist ) && ($emailprefs{userid}[$i] eq $params{record}{$role} || $emailprefs{userid}[$i] eq $params{originalrecord}{$role} ) )
					{
						$x++;
					}
				}
				my ($prefcheck) = "email_" . $role . "_Other";
				if ( grep( /$prefcheck/, @preflist ) && scalar( keys( %{ $params{changes} } ) ) && ($emailprefs{userid}[$i] eq $params{record}{$role} || $emailprefs{userid}[$i] eq $params{originalrecord}{$role}) )
				{
					$x++;
				}
				if ($x)
				{
					push( @notifylist, ( $c{ $params{record}{recordtype} . 'traq' }{label}{$role} ) );
				}
				if ( $emailprefs{userid}[$i] eq $params{record}{$role}  || $emailprefs{userid}[$i] eq $params{originalrecord}{$role})
				{
					$rolelookup{ $emailprefs{email}[$i] } = $c{ $params{record}{recordtype} . 'traq' }{label}{$role};
				}
			}    # For each role

			# add this user to the recipient list if they matched or the force notify was set and they are still active
			if ( ( scalar(@notifylist) || $params{force} ) && $emailprefs{active}[$i] =~ /Yes/i )    # If there are email recipients
			{
				push( @recipientlist, $emailprefs{email}[$i] );
			}                                                                                        # If there are email recipients
		}    # Loop through the possible email recipients
		foreach $email_address (@recipientlist)
		{
			$params{action} =
			    ucfirst( $params{record}{recordtype} ) . ": "
			  . $params{record}{record_id}
			  . " has been "
			  . $params{change_type} . " by: "
			  . &getNameFromId( $params{change_userid} );
			my ($subjectheader);    # Build the email subject line
			if ( $c{email}{subject} eq 'summary' )
			{
				$subjectheader .= ucfirst( $params{record}{recordtype} ) . ": " . $params{record}{record_id};
				$subjectheader .= unEscapeQuotes( " " . $params{record}{short_desc} );
			}
			else
			{
				$subjectheader .= $params{action};
			}
			$subjectheader = "($rolelookup{$email_address}) $subjectheader";
			my(%xheaders);
			foreach my $rr ('type','record_id','projectid','status','priority','severity','componentid','assigned_to','reporter','target_milestone')
			{
				$xheaders{"X-ProjectTraq-$rr"}=$params{record}{$rr};
			}
                        $xheaders{"X-ProjectTraq-Site"}="$c{url}{method}://$c{url}{server}$c{url}{base}";
			my ($msgcontents) = &buildMsgContents( \%params );
			&sendMail( $email_address, $c{email}{ $params{record}{recordtype} . "email" }, $subjectheader, $msgcontents, $params{change_userid},\%xheaders );
			&log( "MAIL: force ($params{force}) message sent to $email_address subject: $subjectheader", 5 );
		}    # if recipient list
	}    # If the change_type parameter has been set
	return;
}

##############################################################################
#
#  buildMsgContents()
#
#  Usage: &buildMsgContents($field, \%params)
#
#  Build the contents of an email confirmation notice.
#
##############################################################################
sub buildMsgContents()
{
	my ($params) = @_;
	my (%params) = %{$params};

	my ( %valueHash, $field );
	my ($msgcontents);
	my ($changesMade);
	my ($unadornedTemplateFileName);

	my ($recordType) = $params{record}{recordtype};
	my ($recordDesc) = $recordType . "traq";
	my (%labelHash)  = %{ $c{$recordDesc}{label} };

	#&log("&formatDataStructure(\%labelHash, 0, 'labelHash'));

	#	Set the bug/task URL in the email message
	$valueHash{url}[0] = "$c{url}{base}/redir.cgi?id=$params{record}{record_id}";
	$valueHash{PROTO}[0]=$c{url}{method};
	$valueHash{SERVER}[0]=$c{url}{server};
	$valueHash{PISSROOT}[0]=$c{url}{base};
	unless ( $c{email}{emaillevel} )    #	If emaillevel is zero or non-existent
	{
		$unadornedTemplateFileName = "email-smallconfirm.tmpl";

		if ( $params{change_type} eq "created" )
		{
			$valueHash{changesmade}[0] = "New $recordType";
		}
		else
		{
			$changesMade = "Changes made:\n";

			# 			foreach $field (keys(%{$params{changes}}))
			# 			{
			# 				$changesMade .= "\t" . $labelHash{$field} . "\n";
			# 			}
			for ( my ($ii) = 0 ; $ii < scalar( @{ $params{record}{changes} } ) ; $ii++ )
			{
				$changesMade .= "\t" . $labelHash{ $params{record}{changes}[$ii][1] } . "\n";
			}
			$valueHash{changesmade}[0] = $changesMade;
		}

	}
	else    # emaillevel _is_ set
	{

		#	First level of email detail
		if ( $c{email}{emaillevel} eq '1' )
		{
			$unadornedTemplateFileName = "email-confirm.tmpl";
			if ( $params{change_type} eq 'created' )
			{
				$valueHash{note}[0] = $labelHash{long_desc} . ": \n$params{record}{note}";
			}
			else
			{
				$valueHash{note}[0] = $labelHash{note} . ": \n$params{record}{note}";
				$changesMade = "\nChanges made:\n";
				my (@roles) = split( ',', $c{general}{rolemenu} );
				push( @roles, 'cc' );
				for ( my ($ii) = 0 ; $ii < scalar( @{ $params{record}{changes} } ) ; $ii++ )
				{
					if ( grep( /$params{record}{changes}[$ii][1]/, @roles ) )
					{
						$changesMade .=
						    "\t$c{$params{record}{recordtype} . 'traq'}{label}{$params{record}{changes}[$ii][1]} from: '"
						  . &getNameFromId( $params{record}{changes}[$ii][2] )
						  . "' to: '"
						  . &getNameFromId( $params{record}{changes}[$ii][3] ) . "'\n";
					}
					else
					{
						$changesMade .=
						    "\t$c{$params{record}{recordtype} . 'traq'}{label}{$params{record}{changes}[$ii][1]} from: '"
						  . &Traqfields::getFieldDisplayValue( $params{record}{changes}[$ii][1], \%{ $params{originalrecord} }, $params{change_userid} )
						  . "' to: '"
						  . &Traqfields::getFieldDisplayValue( $params{record}{changes}[$ii][1], \%{ $params{record} }, $params{change_userid} ) . "'\n";
					}
					if ( $c{email}{mime} ne 'text/plain' && $c{email}{mime} )
					{
						$changesMade .= "<br>";
					}
					else
					{
						$changesMade = unescapeHtml($changesMade);
					}

				}
				$valueHash{changesmade}[0] = $changesMade;
			}
			if ( $c{email}{mime} ne 'text/plain' && $c{email}{mime} )
			{
				$valueHash{note}[0] =~ s/\n/<br>\n/g;
			}
			my ($fieldName);
			foreach $fieldName ( keys( %{ $params{record} } ) )
			{
				my ($templateval) = uc($fieldName) . '_DISP';
				$valueHash{$templateval}[0] = &Traqfields::getFieldDisplayValue( $fieldName, \%{ $params{record} }, $params{change_userid} );
				my ($templatedisp) = uc($fieldName) . '_VAL';
				$valueHash{$templatedisp}[0] = &Traqfields::getFieldValue( $fieldName, \%{ $params{record} }, $params{change_userid} );
			}
		}
		else    #	All other levels of email detail
		{
			$unadornedTemplateFileName = "email-smallconfirm.tmpl";
			$valueHash{changesmade}[0] = "SYSTEM ERROR: Email Level of $c{email}{emaillevel} is not supported - set config file value of emaillevel to 1 or 0";
		}
	}    # emailevel is set
	%valueHash = &populateLabels( \%valueHash, $params{record}{recordtype} );
	$valueHash{action}[0] = $params{action};
	my $completeTemplateFileName = &getTemplateFile($c{dir}{topLevelTemplates},"$unadornedTemplateFileName");
	$msgcontents = &Process( \%valueHash, $completeTemplateFileName );
	$msgcontents = &unEscapeQuotes($msgcontents);
	$msgcontents =~ s/&nbsp;/\ /g;

	return $msgcontents;
}
##############################################################
sub getFieldLabel
{
	my ( $field, $area ) = @_;

	return $c{$area}{label}{$field};
}

#################################################################
sub printDataStructure
{
	print &formatDataStructure(@_);
}

#################################################################
sub formatDataStructure
{
	my ( $ptr, $level, $name ) = @_;

	my $output = "";
	my $prefix = "\t" x $level;

	if ( ref($ptr) eq "HASH" )
	{
		$output .= $prefix . "$name is a hash reference:\n" unless ($level);
		my $key;
		foreach $key ( sort keys %{$ptr} )
		{
			my $value = $$ptr{$key};
			$output .= $prefix . "$key => ";
			if ( ref($value) )
			{
				$output .= "\n";
				$output .= &formatDataStructure( $value, ( $level + 1 ) );
			}
			else
			{
				$output .= "$value\n";
			}
		}
	}
	elsif ( ref($ptr) eq "ARRAY" )
	{
		$output .= $prefix . "$name is an array reference:\n" unless ($level);
		for ( my ($i) = 0 ; $i < scalar( @{$ptr} ) ; $i++ )
		{
			my ($value) = $$ptr[0];
			if ( ref($value) )
			{
				$output .= &formatDataStructure( $value, ( $level + 1 ) );
			}
			else
			{
				$output .= $prefix . "[$i] = $value\n";
			}
		}
	}
	else
	{
		$output .= $prefix . "$$ptr\n";
	}

	return $output;
}

sub validateId()
{
	my ($newid) = shift;
	my (%res)   = &doSql("select userid from logins where userid=$newid");
	if ( $res{'userid'}[0] )
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

sub validateUsername()
{
	my ($name) = shift;
	my (%res)  = &doSql("select username from logins where username=\"$name\"");
	if ( $res{'username'}[0] )
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

sub validateEmail()
{
	my ($email) = shift;
	my (%res)   = &doSql("select email from logins where email=\"$email\"");
	if ( $res{'email'}[0] )
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

sub makeOptionList
{
	my ( $valuelist, $displaylist, $value ) = @_;
	my (@valuelist)   = @{$valuelist};
	my (@displaylist) = @{$displaylist};
	my (@values);
	if(ref($value) eq 'ARRAY')
	{
		@values=@{$value};
		&log('DEBUG: checking ref:' . ref($value));
	}
	else
	{
		@values      = split( ',', $value );		
	}
	my ($html);
	for ( my ($x) ; $x < scalar(@valuelist) ; $x++ )
	{
		if ( grep( /^$valuelist[$x]$/, @values ) )
		{
			$html .= "<option value=\"$valuelist[$x]\" selected>$displaylist[$x]</option>\n";
		}
		else
		{
			$html .= "<option value=\"$valuelist[$x]\">$displaylist[$x]</option>\n";
		}
	}
	return $html;
}

sub getMenuOptionList
{
	my ( $menuName, $projectid, $type, $selected, $userid ) = @_;
	my ( $projectlist, @return, %pres, $html, $key, %hash, %pres, $project_clause, @selected );
	@selected = split( ',', $selected );
	my (@sysmenus)  = split( ',', $c{general}{systemmenu} );
	my (@projmenus) = split( ',', $c{general}{projectmenu} );

	# check for how we're being called by looking at
	if ( grep( /^$menuName$/, @sysmenus ) )    #if menu is system menu, override and only pull system menu values
	{
		$projectid = 0;
	}

	#	if($c{cache}{usecache})
	if (0)
	{
		my ( $item, $ii );
		my ($cache) = new Cache::FileCache( { 'namespace' => "menu-$c{session}{key}" } );
		my (@cachelist) = $cache->get_keys();
		unless ( scalar(@cachelist) )
		{
			&log( "DEBUG: lookup for menu cache keys failed, will repopulate cache", 7 );
			&populateMenuCache();
			@cachelist = $cache->get_keys();
		}
		my ($regex_proj) = $projectid;
		$regex_proj =~ s/,/|/g;
		foreach $item (@cachelist)
		{
			if ( $item =~ /menu=$menuName=($regex_proj)=$type=(.+)/ )
			{
				$hash{$2} = $cache->get($item);
			}
		}
	}
	else    #get project menus if there is no cache
	{
		&log("PRO: $menuName menu populated for project $projectid") if $c{profile};
		my ($sql) =
"select distinct menuname,display_value,value,project from traq_menus where menuname=\"$menuName\" and rec_type like \"\%$type\%\" and project in ($projectid) order by menuname,value";
		%pres = &doSql($sql);
		if (%pres)
		{

			# Put data returned from database into cache
			for ( my ($x) = 0 ; $x < scalar( @{ $pres{'value'} } ) ; $x++ )
			{
				$hash{ $pres{value}[$x] } = $pres{display_value}[$x];
			}
		}
		else
		{
			return "ERROR";
		}
	}
	foreach $key (
		sort {
			if ( $a =~ /^-?\d+$/ && $b =~ /^-?\d+$/ )
			{
				$a <=> $b;
			}
			else
			{
				lc($a) cmp lc($b);
			}
		}
		keys(%hash)
	  )
	{
		if ( grep( /^$key$/, @selected ) && $selected )
		{
			$html .= "<option value=\"$key\" selected>$hash{$key}</option>\n";
		}
		else
		{
			$html .= "<option value=\"$key\">$hash{$key}</option>\n";
		}
	}
	return $html;
}

sub getDisplayValue
{
	my ( $value, $field, $type, $projectid, $userid ) = @_;
	my (%rec);
	$rec{projectid} = $projectid;
	$rec{type}      = $type;
	$rec{$field}    = $value;
	return &Traqfields::getFieldDisplayValue( $field, \%rec, $userid );
}

sub populateLabels
{
	my ( $ref, $type ) = @_;
	my ($area) = $type . 'traq';
	unless ($type)
	{
		$area = 'general';
	}
	$$ref{'REPORTERLABEL'}[0]   = $c{$area}{label}{reporter};
	$$ref{'ASSIGNEDLABEL'}[0]   = $c{$area}{label}{assigned_to};
	$$ref{'PROJECTLABEL'}[0]    = $c{$area}{label}{projectid};
	$$ref{'TECHLABEL'}[0]       = $c{$area}{label}{tech_contact};
	$$ref{'QALABEL'}[0]         = $c{$area}{label}{qa_contact};
	$$ref{'COMPONENTLABEL'}[0]  = $c{$area}{label}{componentid};
	$$ref{'STATUSLABEL'}[0]     = $c{$area}{label}{status};
	$$ref{'WHITEBOARDLABEL'}[0] = $c{$area}{label}{status_whiteboard};
	$$ref{'REPROLABEL'}[0]      = $c{$area}{label}{reproducibility};
	$$ref{'VERSIONLABEL'}[0]    = $c{$area}{label}{version};
	$$ref{'SEVLABEL'}[0]        = $c{$area}{label}{severity};
	$$ref{'PRILABEL'}[0]        = $c{$area}{label}{priority};
	$$ref{'SHORTDESCLABEL'}[0]  = $c{$area}{label}{short_desc};
	$$ref{'KEYWORDSLABEL'}[0]   = $c{$area}{label}{keywords};
	$$ref{'TARGETLABEL'}[0]     = $c{$area}{label}{target_date};
	$$ref{'CCLABEL'}[0]         = $c{$area}{label}{cc};
	$$ref{'OSLABEL'}[0]         = $c{$area}{label}{bug_op_sys};
	$$ref{'PLATFORMLABEL'}[0]   = $c{$area}{label}{bug_platform};
	$$ref{'RESLABEL'}[0]        = $c{$area}{label}{resolution};
	$$ref{'MILESTONELABEL'}[0]  = $c{$area}{label}{target_milestone};
	$$ref{'CHANGELISTLABEL'}[0] = $c{$area}{label}{changelist};
	$$ref{'UNITLABEL'}[0]       = $c{$area}{label}{units_req};
	$$ref{'RECORDTYPE'}[0]      = $type;
	$$ref{'LONGDESCLABEL'}[0]   = $c{$area}{label}{thetext};
	my ($field);

	foreach $field ( keys( %{ $c{$area}{label} } ) )
	{
		my ($label) = uc($field) . "LABEL";
		$$ref{$label}[0] = $c{$area}{label}{$field};
	}
	return %$ref;
}

sub getCannedQuery()
{
	my ( $query_name, $orderby, $q, $userid ) = @_;
	my ($reverse) = $q->param('reverse');
	my ( $sql_statement, %res, $statusClause, $securityClause );
	my ($type) = $q->param('type');
	my ($key);
	if ($type)
	{
		$key = $type . "traq";
	}
	else
	{
		$key = "bugtraq";
	}
	if ( $q->param('status') )
	{
		if ( $q->param('status') eq "all" )
		{
		}
		elsif ( $q->param('status') eq "open" )
		{
			$statusClause = " and (rec.status < $c{$key}{resolved})";
		}
		elsif ( $q->param('status') eq "closed" )
		{
			$statusClause = " and (rec.status > $c{$key}{closethreshold})";
		}
		elsif ( $q->param('status') eq "resolved" )
		{
			$statusClause = " and (rec.status in ($c{$key}{resolved}) )";
		}
		else
		{
			$statusClause = " and (rec.status in (" . $q->param('status') . "))";
		}
	}
	else
	{
		$statusClause = " and (rec.status < $c{$key}{resolved} ) ";
	}
	if ($type) { $statusClause .= " and rec.type=\"$type\""; }
	if ( $query_name eq "user" )
	{
		my ($person);
		if ( $q->param('who') )
		{
			$person = $q->param('who');
		}
		else
		{
			$person = $userid;
		}

		$sql_statement =
"select distinct rec.*,log.last_name,dep.dependson as children from logins log,traq_records rec left join traq_dependencies dep on rec.record_id=dep.blocked  where assigned_to=$person and log.userid=rec.assigned_to";
		$sql_statement .= $statusClause;
	}
	elsif ( $query_name eq "userreported" )
	{
		my ($person);
		if ( $q->param('who') )
		{
			$person = $q->param('who');
		}
		else
		{
			$person = $userid;
		}

		$sql_statement = "select distinct rec.*,log.last_name from logins log,traq_records rec  where reporter=$person and log.userid=rec.reporter";
		$sql_statement .= $statusClause;
	}
	elsif ( $query_name eq "project" )
	{
		my ($project) = $q->param('project');
		$sql_statement = "select distinct rec.*,log.last_name from logins log,traq_records rec where projectid=$project and log.userid=rec.assigned_to";
		$sql_statement .= $statusClause;
	}
	elsif ( $query_name =~ /traq\_(.+)/ )
	{
		my ($q) = $1;
		$sql_statement = &getNamedQuery( $userid, $q );
		unless ($orderby)
		{
			$sql_statement =~ /order by (.+) ASC/;
			$sql_statement =~ /order by (.+) DESC/;
			$orderby = $1;
		}
	}
	else
	{
		&doError("Cannot find query: $query_name");
	}
	if ( $sql_statement =~ /order by .+/ )
	{
		if ( $sql_statement =~ /order by .+ASC/ && $reverse == 1 )
		{
			$orderby .= " DESC";
		}
		elsif ( $sql_statement =~ /order by .+DESC/ && $reverse == 1 )
		{
			$orderby .= " ASC";
		}
		$sql_statement =~ s/order by .+/order by $orderby/;
	}
	else
	{
		$orderby = $orderby || "rec.priority ASC";
		$sql_statement .= " order by $orderby";
	}
	&log( "got canned query: $query_name with sql: $sql_statement", 5 );
	my ( $dd, $from_clause );
	if ( $sql_statement !~ /left\sjoin\slogins\slkup/ )
	{
		foreach $dd ( split( ',', $c{general}{rolemenu} ) )
		{
			$from_clause .= " left join logins lkup$dd on lkup$dd.userid=rec.$dd";
		}
	}
	$sql_statement =~ s/where/$from_clause where/;
	return $sql_statement;
}

sub makeUserOptionList
{
	my (@projectid) = @_;
	my ( $sql, $return, %tmp, $projectid, $selected );
	if ( scalar(@projectid) )
	{
		$projectid = join( ",", @projectid );
		$sql =
"select distinct emp.first_name,emp.last_name,emp.$c{db}{logintablekey},usg.groupid,acl.groupid,acl.projectid from $c{db}{logintable} emp, user_groups usg, acl_traq_projects acl where active = \"Yes\"  and emp.$c{db}{logintablekey}=usg.userid and usg.groupid in (acl.groupid) and acl.projectid in ($projectid)  and emp.userid > 1  and emp.last_name like \"%_%\" order by $c{useraccount}{sortname}";
	}
	else
	{
		$sql =
"select distinct first_name,last_name,$c{db}{logintablekey} from $c{db}{logintable} where active = \"Yes\" and last_name like \"%_%\"  and userid > 1  order by $c{useraccount}{sortname}";
	}
	my (%res);
	%res = &doSql($sql);
	if ( !keys(%res) )
	{
		return "";
	}
	my ($name);
	for ( my ($i) = 0 ; $i < scalar( @{ $res{'last_name'} } ) ; $i++ )
	{

		#     	$c{cache}{user}{$res{$c{db}{logintablekey}}[$i]}{last_name}=$res{'last_name'}[$i];
		#     	$c{cache}{user}{$res{$c{db}{logintablekey}}[$i]}{first_name}=$res{'first_name'}[$i];
		$name = "$res{'last_name'}[$i], $res{'first_name'}[$i]" if ( $c{useraccount}{sortname} eq 'last_name' );
		$name = "$res{'first_name'}[$i] $res{'last_name'}[$i]"  if ( $c{useraccount}{sortname} eq 'first_name' );
		$return .= "<option value=$res{'userid'}[$i]>$name\n" unless $tmp{$name};
		$tmp{$name}++;
	}
	return $return;
}

sub db_GetUserHashforProject
{
	my ($projectid) = @_;
	my ( $sql, $return, %tmp, $selected );
	unless ( keys( %{ $c{cache}{$projectid}{user} } ) )
	{
		unless ( $projectid eq '0' )
		{
			$sql =
"select distinct emp.first_name,emp.last_name,emp.$c{db}{logintablekey},usg.groupid,acl.groupid,acl.projectid from $c{db}{logintable} emp, user_groups usg, acl_traq_projects acl where active = \"Yes\"  and emp.$c{db}{logintablekey}=usg.userid and usg.groupid in (acl.groupid) and acl.projectid in ($projectid)  and emp.userid > 1  and emp.last_name like \"%_%\" order by $c{useraccount}{sortname}";
		}
		else
		{
			$sql =
"select distinct first_name,last_name,$c{db}{logintablekey} from $c{db}{logintable} where active = \"Yes\" and last_name like \"%_%\"  and userid > 1  order by $c{useraccount}{sortname}";
		}
		my (%res);
		%res = &doSql($sql);
		if ( !keys(%res) )
		{
			return "";
		}
		for ( my ($i) = 0 ; $i < scalar( @{ $res{'last_name'} } ) ; $i++ )
		{
			$c{cache}{$projectid}{user}{ $res{ $c{db}{logintablekey} }[$i] }{last_name}  = $res{'last_name'}[$i];
			$c{cache}{$projectid}{user}{ $res{ $c{db}{logintablekey} }[$i] }{first_name} = $res{'first_name'}[$i];
			$c{cache}{$projectid}{user}{ $res{ $c{db}{logintablekey} }[$i] }{full_name}  = "$res{'last_name'}[$i], $res{'first_name'}[$i]"
			  if ( $c{useraccount}{sortname} eq 'last_name' );
			$c{cache}{$projectid}{user}{ $res{ $c{db}{logintablekey} }[$i] }{full_name} = "$res{'first_name'}[$i] $res{'last_name'}[$i]"
			  if ( $c{useraccount}{sortname} eq 'first_name' );
		}
	}
	return %{ $c{cache}{$projectid}{user} };
}

sub verifyDependencies
{
	my ($id)  = @_;
	my (%res) = &getChildren($id);
	my (@blockers);
	if (%res)
	{
		for ( my ($i) = 0 ; $i < scalar( @{ $res{'dependson'} } ) ; $i++ )
		{
			my ($area) = $res{type}[$i] . 'traq';
			if ( $res{'status'}[$i] < $c{$area}{closethreshold} )
			{
				push( @blockers, $res{record_id}[$i] );
			}
		}
		if (@blockers)
		{
			my ($errstr) = "Cannot close this record, it depends on record(s) <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
			my ($dep);
			my (@links);
			foreach $dep (@blockers)
			{
				push( @links, "<A HREF=\"$c{url}{base}/redir.cgi?id=$dep\">$dep</A>" );
			}
			$errstr .= join( ',', @links );
			&doError( $errstr, "", '', "Blocked:" );
		}
	}
}

sub mergeResults
{
	my ( %hash1, %hash2 ) = @_;
	my ( $key, $item );
	foreach $key ( keys(%hash2) )
	{
		foreach $item ( reverse( @{ $hash2{$key} } ) )
		{
			unshift( @{ $hash1{$key} }, $item );
		}
	}
	return %hash1;
}

sub isCreateAuthorized
{
	my ( $user, $compgroups ) = @_;
	my (@compgroups) = @{$compgroups};
	my (@usergroups) = &getGroupsFromEmployeeId($user);
	my ( $group, $g );
	foreach $group (@compgroups)
	{
		foreach $g (@usergroups)
		{
			if ( $group eq $g )
			{
				return 1;
			}
		}
	}

	return 0;
}

sub isSystemMenu
{
	my ($field) = @_;
	my (@sysmenus) = split( ',', $c{general}{systemmenu} );
	if ( grep /^$field$/, @sysmenus )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub isProjectMenu
{
	my ($field) = @_;
	my (@projectmenu) = split( ',', $c{general}{projectmenu} );
	if ( grep /^$field$/, @projectmenu )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub getAttachments()
{
	my ($id)  = @_;
	my ($sql) = "select * from traq_attachments where record_id=\"$id\" order by creation_ts";
	return &doSql($sql);
}

sub bogusChangeCheck()
{
	my ( $cref ) = @_;
	my ($check) = 0;
	&log("DEBUG: changeref:" . Dumper($cref));
	if(ref($cref) eq 'ARRAY')
	{
		my($x,$y)=($$cref[2],$$cref[3]);
		if (   $x ne $y
			&& ( $y =~ /0000-00-00/ || $y =~ /0000-00-00 00:00:00/ || $y eq '0' || $y eq ''  || !$y )
			&& ( $x =~ /0000-00-00/ || $x =~ /0000-00-00 00:00:00/ || $x eq ''  || $x eq '0' || !$x ) )
		{
			$check = 1;
		}
	}
	return $check;
}

sub time_now()
{
	my ( $y2, $m2, $d2, $h2, $min2, $s2 ) = Date::Calc::Today_and_Now();
	return "$y2-$m2-$d2 $h2:$min2:$s2";
}

sub date2time()
{
	my ($time1) = @_;
	unless ($time1)
	{
		return '';
	}
	my (@arr1) = split( ' ', $time1 );
	my ( $yy1, $mm1, $dd1 ) = split( '-', $arr1[0] );
	my ( $HH1, $MM1, $SS1 ) = split( ':', $arr1[1] );

	return Date::Calc::Date_to_Time( $yy1, $mm1, $dd1, $HH1, $MM1, $SS1 );

}

sub populateUserCache()
{
	my ( $key, $i, $item );
	my ($cache) = new Cache::FileCache( { 'namespace' => "user-$c{session}{key}" } );
	my (%res) = &doSql("select * from logins");
	for ( $i = 0 ; $i < scalar( @{ $res{userid} } ) ; $i++ )
	{
		foreach $key ( keys(%res) )
		{
			$item = "user=$res{userid}[$i]=$key";
			$cache->set( $item, $res{$key}[$i], $c{cache}{timeout} );
		}
	}
	&log("PRO: populated user cache") if $c{profile};
}

sub populateMenuCache()
{
	my ( $key, $i, $item );
	my ($cache) = new Cache::FileCache( { 'namespace' => "menu-$c{session}{key}" } );
	my (%res) = &doSql("select menuname,project,value,display_value,rec_type from traq_menus");
	for ( $i = 0 ; $i < scalar( @{ $res{menuname} } ) ; $i++ )
	{
		if ( $res{rec_type}[$i] =~ /task/ )
		{
			$item = "menu=$res{menuname}[$i]=$res{project}[$i]=task=$res{value}[$i]";
			$cache->set( $item, $res{display_value}[$i], $c{cache}{timeout} );
		}
		if ( $res{rec_type}[$i] =~ /bug/ )
		{
			$item = "menu=$res{menuname}[$i]=$res{project}[$i]=bug=$res{value}[$i]";
			$cache->set( $item, $res{display_value}[$i], $c{cache}{timeout} );
		}
	}
	&log("PRO: populated menu cache") if $c{profile};
}

sub populateMilestoneCache()
{
	my ( $key, $i, $item );
	my ($cache) = new Cache::FileCache( { 'namespace' => "milestone-$c{session}{key}" } );
	my ($sql) = "select milestone,milestoneid from traq_milestones";
	&log("SQL: $sql",7);
	my (%res3) = &doSql($sql);
	for ( $i = 0 ; $i < scalar( @{ $res3{milestoneid} } ) ; $i++ )
	{
		$item = "target_milestone=$res3{milestoneid}[$i]";
		$cache->set( $item, $res3{milestone}[$i], $c{cache}{timeout} );
	}
	&log("PRO: populated milestone cache") if $c{profile};
}

sub process_file_upload()
{
	my ( $q, $record_id, $userid,$fileref ) = @_;
    my($fname,$file,$description,$mime,$enc);
    if($fileref)
    {
        $file=$$fileref{file};
        $description=$$fileref{description};
        $mime=$$fileref{mime_type};
    }
    else
    {
        $fname       = $q->param('uploaded_file');
        $file        = $q->param('FILE');
        $description = &escapeQuotes( $q->param('description') ) || "None";
        $mime        = $q->param('type');
    }
	$fname = $file;
	if($description=~/\/{1,2}depot/)
	{
	   $fname=$description;
	   $enc=$description;
	   $description='P4 file';
    }
    else
    {
    	undef $/;
        my ($contents) = <$file>;
        $enc   = encode_base64($contents);    
    }
  	$fname =~ s/.*[\\\/](.+)$/$1/g;
	my ($sql)      = "insert into traq_attachments set record_id=\"$record_id\",creation_ts=now(),";
	$sql .= "description=\"$description\",filename=\"$fname\",thedata=\'$enc\',submitter_id=\"$userid\"";
	$sql .= ",mimetype=\"$mime\"";
	&doSql($sql);
	$sql = "insert into traq_activity set 
			   record_id=$record_id,
			   who=$userid,date=now(),
			   fieldname=\"create\",
			   oldvalue=\"\",
			   newvalue=\"filename: $fname\",
			   tablename=\"traq_attachments\"";
	&doSql($sql);
	return $fname;
}

sub populateProjectCache()
{
	my ( $key, $i, $item );
	my ($cache) = new Cache::FileCache( { 'namespace' => "project-$c{session}{key}" } );
	my ($sql)   = "select project,projectid,cc from traq_project";
	my (%res)   = &doSql($sql);
	for ( $i = 0 ; $i < scalar( @{ $res{projectid} } ) ; $i++ )
	{
		$item = "project=$res{projectid}[$i]=name";
		$cache->set( $item, $res{project}[$i], $c{cache}{timeout} );
		$item = "project=$res{projectid}[$i]=cc";
		$cache->set( $item, $res{cc}[$i], $c{cache}{timeout} );
	}
	&log("PRO: populated project cache") if $c{profile};
}

sub populateComponentCache()
{
	my ( $key, $i, $item );
	my ($cache) = new Cache::FileCache( { 'namespace' => "component-$c{session}{key}" } );
	my ($sql)   = "select * from traq_components";
	my (%res)   = &doSql($sql);
	for ( $i = 0 ; $i < scalar( @{ $res{componentid} } ) ; $i++ )
	{
		$item = "component=$res{componentid}[$i]=name";
		$cache->set( $item, $res{component}[$i], $c{cache}{timeout} );
		$item = "component=$res{componentid}[$i]=initialqacontact";
		$cache->set( $item, $res{initialqacontact}[$i], $c{cache}{timeout} );
		$item = "component=$res{componentid}[$i]=initialowner";
		$cache->set( $item, $res{initialowner}[$i], $c{cache}{timeout} );
		$item = "component=$res{componentid}[$i]=projectid";
		$cache->set( $item, $res{projectid}[$i], $c{cache}{timeout} );
		$item = "component=$res{componentid}[$i]=cc";
		$cache->set( $item, $res{cc}[$i], $c{cache}{timeout} );
	}
	&log("PRO: populated component cache") if $c{profile};
}

sub getUserOptionList()
{
	my ( $projectid, $value ) = @_;
	unless ($projectid)
	{
		$projectid = 0;
	}
	my (%userhash) = &supportingFunctions::db_GetUserHashforProject($projectid);
	my ( %rehash, $userid, $username, $i, $html, $found );
	$found = 0;
	foreach $userid ( keys(%userhash) )
	{
		$rehash{ $userhash{$userid}{full_name} } = $userid;
	}
	my (@usernames) = keys(%rehash);
	@usernames = sort @usernames;
	for ( $i = 0 ; $i < scalar(@usernames) ; $i++ )
	{
		if ( $rehash{ $usernames[$i] } eq $value )
		{
			$html .= "<option value=\"$rehash{$usernames[$i]}\" selected>$usernames[$i]</option>\n";
			$found = 1;
		}
		else
		{
			$html .= "<option value=\"$rehash{$usernames[$i]}\">$usernames[$i]</option>\n";
		}
	}
	if ( $value && !$found )
	{
		my ($name) = &supportingFunctions::getNameFromId($value);
		$html = "<option value=\"$value\" selected>$name</option>\n" . $html;
	}
	else
	{
		$html = "<option value=\"\"></option>\n" . $html;
	}
	return $html;
}

sub getProjectidCC()
{
	my ($id) = @_;
	unless ($id)
	{
		return '';
	}
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "project=$id=cc";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "project-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&populateProjectCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my ($sql) = "select cc from traq_project where projectid=$id";
		my (%res) = &doSql($sql);
		unless (%res)
		{
			&doError( "Error getting project name for $id", $sql );
		}
		return ${ $res{'cc'} }[0];
	}
}

sub getComponentidCC()
{
	my ($id) = @_;
	unless ($id)
	{
		return '';
	}
	if ( $c{cache}{usecache} )
	{
		my ($lookup) = "component=$id=cc";
		my ($cache)  = new Cache::FileCache( { 'namespace' => "component-$c{session}{key}" } );
		my ($value)  = $cache->get($lookup);
		if ( not defined $value )
		{
			&log( "DEBUG: cache lookup failed for $lookup, will repopulate cache", 7 );
			&populateComponentCache();
			$value = $cache->get($lookup);
		}
		return $value;
	}
	else
	{
		my (%res) = &doSql("select cc from traq_components where componentid = \"$id\"");
		return $res{'cc'}[0];
	}
}

sub makeDate()
{
	my ($string) = @_;
	my ($date);

	if ( $string =~ /\d\d\d\d-\d{1,2}-\d{1,2}/ )
	{
		return $string;
	}

	$date = ParseDateString($string);

	if ($date)
	{
		$date =~ s/(\d\d\d\d)(\d\d)(\d\d).*/$1-$2-$3/;
		return $date;
	}
}

sub db_UpdateRecord
{
	my ( $recordref, $olddataref, $userid, $DEBUG ) = @_;
	my ($sql) = "update traq_records set delta_ts=now()";
	my ( $field, %changes,$autonote );
	my ($area) = $$recordref{type} . 'traq';

	# Step through fields to create update sql
	foreach $field ( keys( %{ $c{$area}{label} } ) )
	{
		my ($newfieldvalue) = &saveField( $field, $olddataref, $recordref, $userid );
		unless ( $newfieldvalue eq &escapeQuotes( $$olddataref{$field} )
			|| grep( /^$field$/, split( ',', $c{general}{externalfields} ) )
			|| grep( /^$field$/, split( ',', $c{general}{virtualfields} ) ) )
		{
			if ( &canEditField( $userid, $field, $recordref ) )
			{
				$sql .= ", $field=\"$newfieldvalue\"";
				$changes{$field} = $newfieldvalue;
				@{ $$recordref{changes}[ $#{ $$recordref{changes} } + 1 ] } = ( 'traq_records', $field, $$olddataref{$field}, $newfieldvalue );
			}
		}
	}
	$sql .= " where record_id=$$recordref{record_id}";
	&doSql($sql);
	if($$recordref{attachment})
	{
	   my($newfile)=&process_file_upload('',$$recordref{record_id},$userid,\%{$$recordref{attachment}});
	   @{ $$recordref{changes}[ $#{ $$recordref{changes} } + 1 ] } = ( 'traq_attachments', "Attachment", "", $newfile );
	}
    if ( $$recordref{'delete_attach'} )
    {
        my (@rm_attachlist) = $$recordref{'delete_attach'};
        my ($attid);
        foreach $attid (@rm_attachlist)
        {
        
            $sql = "delete from traq_attachments where attach_id=\"$attid\"";
            &doSql($sql);
            $sql = "insert into traq_activity set 
                       record_id=$$recordref{record_id},
                       who=$userid,date=now(),
                       fieldname=\"delete\",
                       oldvalue=\"\",
                       newvalue=\"filename: \",
                       tablename=\"traq_attachments\"";
            &doSql($sql);
    	   @{ $$recordref{changes}[ $#{ $$recordref{changes} } + 1 ] } = ( 'traq_attachments', "Attachment", $attid, "" );
        }    
    }
    if ($$recordref{note})
    {
        if ( &canEditField( $userid, "addnote",$recordref ) )
        {
            &addRecordNote( $$recordref{'record_id'}, $$recordref{note}, $userid );
            @{ $$recordref{changes}[ $#{ $$recordref{changes} } + 1 ] } = ( 'traq_longdescs', "note", "", "Added" );
        }
    }
    # Dependency handling
    if ( $$recordref{'child'} )
    {
        if ( $c{$area}{requirecomment} && !$$recordref{note} )
        {
            if ( $c{$area}{requirecomment} eq 'auto' )
            {
                $autonote = "Dependency added\n";
            }
            else
            {
                &doError( "PleaseCommentOnChange", "", "", "AddChild" );
            }
        }
        my ($children) = $$recordref{'child'};
        $children =~ s/[BbtT]//g;
        $children =~ s/\s/,/g;
        my (@children) = split( /,/, $children );
        my ($child);
        foreach $child (@children)
        {
            if ($child)
            {
                unless ( &isEditAuthorized( $userid, $child ) )
                {
                    &doError( "AccessDenied", "", "", "AddChild" );
                }
                &db_addChild( $$recordref{'record_id'}, $child );
                @{$$recordref{changes}[$#{$$recordref{changes}}+1]}= ( 'traq_dependencies', 'dependson', '', $child);
            }
        }
    }
    if ( $$recordref{'parent'} )
    {
        if ( $c{$area}{requirecomment} && !$$recordref{note} )
        {
            if ( $c{$area}{requirecomment} eq 'auto' )
            {
                $autonote = "Dependency added\n";
            }
            else
            {
                &doError( "PleaseCommentOnChange", "", "", "AddParent" );
            }
        }
        my ($parents) = $$recordref{'parent'};
        $parents =~ s/[BbtT]//g;
        $parents =~ s/\s/,/g;
        my (@parents) = split( /,/, $parents );
        my ($parent);
        foreach $parent (@parents)
        {
            if($parent)
            {
                unless ( &isEditAuthorized( $userid, $parent ) )
                {
                    &doError( "AccessDenied", "", "", "AddParent" );
                }
                &db_addChild( $parent, $$recordref{'record_id'} );
                @{$$recordref{changes}[$#{$$recordref{changes}}+1]}= ( 'traq_dependencies', 'blocked', '', $parent);
            }
        }
    }
    if ( $$recordref{'removechild'} )
    {
        if ( $c{$area}{requirecomment} && !$$recordref{note} )
        {
            if ( $c{$area}{requirecomment} eq 'auto' )
            {
                $autonote = "Dependency removed\n";
            }
            else
            {
                &doError( "PleaseCommentOnChange", "", "", "RemoveChild" );
            }
        }
        my (@delchildren) = $$recordref{'removechild'};
        my ($delchild);
        foreach $delchild (@delchildren)
        {
            unless ( &isEditAuthorized( $userid, $delchild ) )
            {
                &doError( "AccessDenied", "", "", "RemoveChild" );
            }
            &removeChild( $$recordref{'record_id'}, $delchild );
            @{$$recordref{changes}[$#{$$recordref{changes}}+1]}= ( 'traq_dependencies', 'dependson', $delchild, '');
        }
    }
    if ( $$recordref{'removeparent'} )
    {
        if ( $c{$area}{requirecomment} && !$$recordref{note} )
        {
            if ( $c{$area}{requirecomment} eq 'auto' )
            {
                $autonote = "Dependency removed\n";
            }
            else
            {
                &doError( "PleaseCommentOnChange", "", "", "RemoveParent" );
            }
        }
        my (@delparents) =$$recordref{'removeparent'};
        my ($delparent);
        foreach $delparent (@delparents)
        {
            unless ( &isEditAuthorized( $userid, $delparent ) )
            {
                &doError( "AccessDenied", "", "", "RemoveParent" );
            }
            &removeChild( $delparent, $$recordref{'record_id'} );
            @{$$recordref{changes}[$#{$$recordref{changes}}+1]}= ( 'traq_dependencies', 'blocked', $delparent, '');
        }
    }	return %{$$recordref{changes}};
}

sub db_CreateRecord()
{
	my ( $recordref, $userid, $DEBUG ) = @_;
	my ( $field, $newRecordId, $group ,$ff);
	my (%olddataref);
	my ($area) = $$recordref{type} . 'traq';
	my ($sql)  = "insert into traq_records set ";
	$sql .= "creation_ts=now() ";
	# do plain english conversion on date fields
	my (@dates) = split( ',', $c{general}{datefields} );
	foreach $ff (@dates)
	{
		$$recordref{$ff} = &makeDate($$recordref{$ff});
    }
    # end date conversion
    
    # process each field for addition to sql statement
	foreach $field ( keys( %{ $c{$area}{label} } ) )
	{

		unless ( grep( /^$field$/, split( ',', $c{general}{externalfields} ) )
			|| grep( /^$field$/, split( ',', $c{general}{virtualfields} ) ) )
		{
			if ( &canEditField( $userid, $field,$recordref ) )
			{
				$$recordref{$field} = &saveField( $field, \%olddataref, $recordref, $userid );
				$sql .= ",$field=\"$$recordref{$field}\"\n";
			}
		}
	}
	print "\n<br><b>$sql<br>\n" if $DEBUG;
    # end sql construction

    #execute sql
	$newRecordId = &doSql( $sql, '', '1' );
	$$recordref{record_id} = $newRecordId;

    # add related table based fields
	&saveField( 'keywords', \%olddataref, $recordref, $userid );
	&saveField( 'cc',       \%olddataref, $recordref, $userid );
	my ($sql) = "insert into traq_longdescs set record_id=$newRecordId,who=$userid,date=now(),thetext=\"$$recordref{long_desc}\"";
	my ($ret) = &doSql($sql);

    # add activity record for record creation   
	my ($sql) = "insert into traq_activity set 
		   record_id=$$recordref{record_id},
		   who=$userid,date=now(),
		   fieldname=\"record_id\",
		   oldvalue=\"New Record\",
		   newvalue=\"$newRecordId\",
		   tablename=\"traq_records\"";
	&doSql($sql);

    # process acl creation
	my (@compgroups) = &getComponentGroups( $$recordref{'componentid'} );
	foreach $group (@compgroups)
	{
		my ($sql) = "insert into acl_traq_records set groupid=$group,record_id=$newRecordId";
		print "acl: ", $sql, "<BR>" if $DEBUG;
		my ($ret) = &doSql($sql);
	}

    ### Process dependencies
	# If record was created as a child of an existing record, create dependacy.
	if ( $$recordref{parent} )
	{
		my ($parents) = $$recordref{parent};
		$parents =~ s/[BbtT]//g;
		$parents =~ s/\s/,/g;
		my (@parents) = split( /,/, $parents );
		my ($parent);
		foreach $parent (@parents)
		{
			if ($parent)
			{
				unless ( &isEditAuthorized( $userid, $parent ) )
				{
					&doError( "AccessDenied", "", '', "AddParent" );
				}
				&db_addChild( $parent, $$recordref{'record_id'} );
			}
		}
	}

	# If record was created as a parent of an existing record, create dependacy.
	if ( $$recordref{child} )
	{
		my ($children) = $$recordref{child};
		$children =~ s/[BbtT]//g;
		$children =~ s/\s/,/g;
		my (@children) = split( /,/, $children );
		my ($child);
		foreach $child (@children)
		{
			if ($child)
			{
				unless ( &isEditAuthorized( $userid, $child ) )
				{
					&doError( "AccessDenied", "", '', "AddChild" );
				}
				&db_addChild( $$recordref{'record_id'}, $child );
			}
		}
	}
	if($$recordref{attachment})
	{
	   my($newfile)=&process_file_upload('',$$recordref{record_id},$userid,\%{$$recordref{attachment}});
	   @{ $$recordref{changes}[ $#{ $$recordref{changes} } + 1 ] } = ( 'traq_attachments', "Attachment", "", $newfile );
	}

	return $newRecordId;
}
sub db_addChild
{
	my ( $parent, $child ) = @_;
	if($parent eq $child)
	{
	   return;
	}
	&log("adding relationship: parent:$parent, chid:$child") if $c{debug};
	$parent =~ s/[BbtT](\d+)/$1/;
	$child  =~ s/[BbtT](\d+)/$1/;
    my ($sql) = "insert into traq_dependencies set blocked=$parent,dependson=$child";
    &doSql($sql);
}
sub getGroupIdFromName
{
	my ($group) = @_;
	my ($sql) = "select groupid from groups where groupname='$group'";
	my (%res) = &doSql($sql);
	if (%res)
	{
        return $res{groupid}[0];
	}
}
sub getTemplateFile
{
    my($path,$filename,$userid,$recref)=@_;
    my($templatepath);
    if($filename)
    {
        $templatepath= $path . '/' .  $filename;
    }
    else
    {
        $templatepath =$path;
    }
    &log("DEBUG: using template file $templatepath",7);
    return $templatepath;
}
END { }

1;

