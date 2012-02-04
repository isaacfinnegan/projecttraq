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
use Traqfields;
use DataProc qw(&Process);
use vars qw(%c);
use strict;
local (*c) = \%TraqConfig::c;
my ($headersent) = 0;
my (%clear);
%{ $c{cache} } = %clear;

&startLog();
my ($LOGGING) = 5;

my ( $field, %html, $html, $connection, $q, $userid, $i, $item, $key );
$q      = new CGI;
$userid = &getUserId($q);

my ($mode)       = $q->param('mode')      || "list";
my ($selectproj) = $q->param('projectid');
$html{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};

my ($pid) = $q->param('projectid');

&log("DEBUG: PID:  $pid");

if( $pid eq '0' ) {
    print $q->redirect("./editsystem.cgi");
    exit;
}

if ( $mode eq "list" ) {

    #    $html{MENUHTML}[0]=&drawList($selectproj);
    $html{MENUHTML}[0] = &drawList( $selectproj, '', $userid );
    &sendHeader( $headersent, $q );
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'project_edit.tmpl',$userid);
	$html{PISSROOT}[0] = $c{url}{base};
	$html{FOOTER}[0] = &getFooter($userid, 'traq');
	$html{HEADER}[0] = &getHeader($userid, 'traq');
    print &Process( \%html, $templatefile );
    exit;
}
foreach $field ( 'componentidlabel', 'techlabel', 'qalabel' ) {
    $html{$field}[0] = $c{general}{$field};
}
unless ( &isProjectAdmin( $userid, $pid ) ) {
    print $q->header;
    &doError("you must be a project admin to modify this project");
    exit;
}

if ( $mode eq "selectproject" ) {
    my ($selectproj) = $q->param('projectid');
    $html{MENUHTML}[0] = &drawList( $selectproj, '', $userid );
    &sendHeader( $headersent, $q );
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'project_edit.tmpl',$userid);
	$html{PISSROOT}[0] = $c{url}{base};
	$html{FOOTER}[0] = &getFooter($userid, 'traq');
	$html{HEADER}[0] = &getHeader($userid, 'traq');
    print &Process( \%html, $templatefile );
    exit;

}
if ( $mode eq "getproject" ) {

    #$html = "authorized to edit p";
    my ($editarea) = $q->param('editarea') || "general";

    if ( $editarea eq "general" ) {
        print $q->header;
        $html{MENUHTML}[0] = &drawList( $pid, "GENERAL", $userid );
        $html{MENU}[0]     = ucfirst($editarea);
        $html{CONTENT}[0]  = &drawGeneralForm( $pid, $userid );
    }
    elsif ( $editarea eq "groups" ) {
        $html{MENUHTML}[0] = &drawList( $pid, "GROUPS", $userid );
        $html{MENU}[0]     = ucfirst($editarea);
        $html{CONTENT}[0]  = &drawGroupsForm($pid);
    }
    elsif ( $editarea eq "components" ) {
        print $q->header;
        $html{MENUHTML}[0] = &drawList( $pid, "COMPONENTS", $userid );
        $html{MENU}[0]     = ucfirst($editarea);
        $html{CONTENT}[0]  = &drawComponents( $pid, $userid );
    }
    elsif ( $editarea eq "milestones" ) {
        print $q->header;
        $html{MENUHTML}[0] = &drawList( $pid, "MILESTONES", $userid );
        $html{MENU}[0]     = ucfirst($editarea);
        $html{CONTENT}[0]  = &drawMilestones($pid);
    }
    elsif ( $editarea eq "menus" ) {
        print $q->header;
        $html{MENUHTML}[0] = &drawList( $pid, "MENUS", $userid );
        $html{MENU}[0]     = ucfirst($editarea);
        $html{CONTENT}[0]  = &drawMenus($pid);
    }
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'project_edit.tmpl',$userid);
	$html{PISSROOT}[0] = $c{url}{base};
	$html{FOOTER}[0] = &getFooter($userid, 'traq');
	$html{HEADER}[0] = &getHeader($userid, 'traq');
    print &Process( \%html, $templatefile );
    exit;
}
elsif ( $mode eq "processgeneral" ) {
    my ($pid)         = $q->param('projectid');
    my ($projectname) = &getProjectName($pid);
    my ($newname)     = $q->param('projectname');
    my ($newdesc)     = $q->param('projectdesc');
    my ($newtech)     = $q->param('defaulttech');
    my ($newqa)       = $q->param('defaultqa');
    my ($active)      = $q->param('active');
    my ($url)      = $q->param('url');
    my ($newbugurl)      = $q->param('newbugurl');
    my ($newtaskurl)      = $q->param('newtaskurl');
    my ($cc)          = join( ",", $q->param('cc') );
    my ($archive)     = 1;

    if ($active) {
        $archive = 0;
    }
    my ($type) = join( " ", $q->param('rec_type') );
    &doSql(
"update traq_project set rec_types=\"$type\", default_dev = $newtech, default_qa=$newqa, project=\"$newname\", description=\"$newdesc\", archive=$archive, cc=\"$cc\" , url=\"$url\" , newbugurl=\"$newbugurl\" , newtaskurl=\"$newtaskurl\" where projectid=$pid"
    );

    # Update group names since project name has changed.
    &doSql(
"update groups set groupname=\"$newname\" where groupname=\"$projectname\""
    );
    my ($projectownergroup)    = $projectname . '-owners';
    my ($newprojectownergroup) = $newname . '-owners';
    &doSql(
"update groups set groupname=\"$newprojectownergroup\" where groupname=\"$projectownergroup\""
    );

    #&doSql("update traq_project set default_qa = $newqa where projectid=$pid");
    if ( $c{cache}{usecache} ) {
        my ($cache) =
          new Cache::FileCache( { 'namespace' => "project-$c{session}{key}" } );
        $cache->clear();
    }
    print $q->redirect(
        "./editproject.cgi?mode=getproject&projectid=$pid&editarea=general");
    exit;
}
elsif ( $mode eq "processgroupacl" ) {
    my ($action) = $q->param('action');
    my ($pid)    = $q->param('projectid');
    if ( $action eq "Add" ) {
        my (@newaddees) = $q->param('notingroup');
        my ($group);
        my (@components);
        my (%components) = &getComponents($pid);
        if (%components) {
            @components = @{ $components{componentid} };
        }
        foreach $group (@newaddees) {
            &doSql(
                "insert into acl_traq_projects (projectid, groupid) values
				($pid, $group)"
            );
            my ($comp);
            if (%components) {
                foreach $comp (@components) {
                    &doSql(
"insert into acl_traq_components (componentid, groupid) values
					($comp, $group)"
                    );
                }
            }
        }
    }
    elsif ( $action eq "Delete" ) {
        my (@removees) = $q->param('ingroup');
        my ($group);
        my (%components) = &getComponents($pid);
        my (@components);
        if (%components) {
            @components = @{ $components{componentid} };
        }
        foreach $group (@removees) {
            &doSql(
                "delete from acl_traq_projects where groupid=$group
			   and projectid=$pid"
            );
            my ($comp);
            if (%components) {
                foreach $comp (@components) {
                    &doSql(
"delete from acl_traq_components where componentid=$comp 
					and groupid=$group"
                    );
                }
            }
        }
    }
    print $q->redirect(
        "./editproject.cgi?mode=getproject&projectid=$pid&editarea=groups");
    exit;
}
elsif ( $mode eq "processcompedit" ) {
    my ($newowner)    = $q->param('initialowner');
    my ($newqa)       = $q->param('initialqacontact');
    my ($componentid) = $q->param('componentid');
    my ($pid)         = $q->param('projectid');
    my ($compname)    = $q->param('component');
    my ($compactive)  = $q->param('active');
    my ($description) = $q->param('description');
    my ($action)      = $q->param('action');
    my ($type)        = join( " ", $q->param('rec_type') );
    my ($cc)          = join( ",", $q->param('cc') );

    if ( $action eq "Delete" ) {
        my (%res) = &doSql(
            "select record_id from traq_records where 
				componentid=$componentid"
        );
        if ( $res{record_id}[0] ) {
            print $q->header;
            &doError("Cannot delete component until it has 0 records");
            exit;
        }
        &doSql("delete from traq_components where componentid=$componentid");
        &doSql(
            "delete from acl_traq_components where componentid=$componentid");
    }
    else {
        &doSql(
"update traq_components set initialowner=\"$newowner\",initialqacontact=\"$newqa\",
	    component=\"$compname\", active=\"$compactive\", description=\"$description\", rec_type=\"$type\"
	    , cc=\"$cc\" 
	    where componentid=$componentid"
        );
    }
    if ( $c{cache}{usecache} ) {
        my ($cache) =
          new Cache::FileCache(
            { 'namespace' => "component-$c{session}{key}" } );
        $cache->clear();
    }
    print $q->redirect(
        "./editproject.cgi?mode=getproject&editarea=components&projectid=$pid");
    exit;
}
elsif ( $mode eq "processnewcomp" ) {
    my ($component)   = $q->param('component');
    my ($description) = $q->param('description');
    my ($type)        = join( " ", $q->param('rec_type') );
    my ($tech)        = $q->param('initialowner');
    my ($qa)          = $q->param('initialqacontact');
    my ($compactive)  = $q->param('active');
    my ($cc)          = join( ",", $q->param('cc') );

    &doSql(
        "insert into traq_components set component=\"$component\",
	    description=\"$description\", rec_type=\"$type\", 
	    projectid=$pid,active=\"$compactive\",initialowner=$tech,
	    initialqacontact=$qa,cc=\"$cc\""
    );
    my (%res) = &doSql(
        "select componentid from traq_components where 
		component=\"$component\" and projectid=$pid"
    );
    unless ( $res{componentid}[0] ) {
        &doError( "Error creating component", $q );
    }
    my (%pgroups) =
      &doSql("select groupid from acl_traq_projects where projectid=$pid");
    my ($group);
    foreach $group ( @{ $pgroups{groupid} } ) {
        &doSql(
"insert into acl_traq_components set componentid=$res{componentid}[0],
		groupid=$group"
        );
    }
    if ( $c{cache}{usecache} ) {
        my ($cache) =
          new Cache::FileCache(
            { 'namespace' => "component-$c{session}{key}" } );
        $cache->clear();
    }
    print $q->redirect(
        "./editproject.cgi?mode=getproject&editarea=components&projectid=$pid");
    exit;
}

&sendHeader( $headersent, $q );
print $html;

exit;
#######################################################################

sub drawGeneralForm() {
    my ( $pid, $userid ) = @_;
    my (%projectdata) =
      &doSql("select * from traq_project where projectid=$pid");
    my (%results);
    my ($projecttech) = $projectdata{'default_dev'}[0];
    my ($projectqa)   = $projectdata{'default_qa'}[0];
    my ($techname)    = &getNameFromId($projecttech);
    my ($qaname)      = &getNameFromId($projectqa);
    my (%emps)        = &getEmployeeList( "Full", $pid );
    $i = 0;
    my ($key);

    foreach $key ( sort( keys(%emps) ) ) {
        $results{'EMPLOYEENAME'}[$i] = $key;
        $results{'EMPLOYEEID'}[$i]   = $emps{$key};
        $i++;
    }
    if ( grep( /bug/, split( " ", $projectdata{'rec_types'}[0] ) ) ) {
        $results{'bugcheck'}[0] = 'checked';
    }
    else {
        $results{'bugcheck'}[0] = '';
    }
    if ( grep( /task/, split( " ", $projectdata{'rec_types'}[0] ) ) ) {
        $results{'taskcheck'}[0] = 'checked';
    }
    else {
        $results{'taskcheck'}[0] = '';
    }
    unless ( $projectdata{'archive'}[0] ) {
        $results{activecheck}[0] = 'checked';
    }
    $results{techid}[0]      = $projecttech;
    $results{techname}[0]    = $techname;
    $results{qaid}[0]        = $projectqa;
    $results{qaname}[0]      = $qaname;
    $results{PROJECTNAME}[0] = $projectdata{'project'}[0];
    my (%tmp);
    $tmp{projectid} = $pid;
    @{ $tmp{cc} } = split( ',', $projectdata{cc}[0] );
    $results{'PROJECTIDCC_OPTIONLIST'}[0] =
      &getFieldOptionList( 'cc', \%tmp, $userid );

    foreach $field ( 'componentidlabel', 'techlabel', 'qalabel' ) {
        $results{$field}[0] = $c{general}{$field};
    }

    $results{tech_contact}[0]   = $c{general}{label}{tech_contact};
    $results{qa_contact}[0]     = $c{general}{label}{qa_contact};
    $results{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};
    $results{PROJECTDESC}[0]    = $projectdata{'description'}[0];
    $results{PROJECTURL}[0]    = $projectdata{'url'}[0];
    $results{PROJECTID}[0]      = $pid;
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'projectgeneral.tmpl',$userid);
    my($html)= &Process( \%results, $templatefile );
    return $html;
}

sub drawGroupsForm() {
    my ($html);
    my ($pid)     = shift;
    my (%pgroups) = &doSql(
"select grp.groupname,grp.groupid from acl_traq_projects acl, groups grp 
			where acl.projectid=$pid and grp.groupid=acl.groupid"
    );
    my (%groups) =
      &doSql(
"select groupid as gid, groupname as name from groups order by groupname"
      );
    my (%results) = &mergeHashes( %pgroups, %groups );
    $results{PROJECTNAME}[0]    = &getProjectNameFromId($pid);
    $results{PROJECTID}[0]      = $pid;
    $results{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};
    &sendHeader( $headersent, $q );
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'project_group.tmpl',$userid);
    my($html)= &Process( \%results, $templatefile );
    return $html;
}

sub drawList() {
    my ( $id, $area, $userid ) = @_;
    my ( $pid, $ii );
    $pid = shift;
    my ( $choice, $i );
    my (@groups) = &getGroupsFromEmployeeId($userid);
    my (%projects);
    if ( &isAdministrator($userid) ) {
        %projects =
          &doSql(
            "select distinct prj.* from traq_project prj order by prj.project");
    }
    else {
        %projects = &getAuthorizedProjects( "0", \@groups, '', 1 );
    }
if(%projects)
{
    for ( my ($ii) = 0 ; $ii < scalar( @{ $projects{'projectid'} } ) ; $ii++ ) {
        if ( $projects{'archive'}[$ii] eq '1' )
        {
            $projects{'project'}[$ii] = $projects{'project'}[$ii] . ' - INACTIVE';
        }
    }
}
    if ( $pid = $id ) {
        unshift( @{ $projects{'projectid'} }, $pid );
        unshift( @{ $projects{'project'} },   &getProjectName($pid) );
        if ( $pid == $id ) {
            $projects{SELECTED}[0] = "selected";
            $choice++;
        }
    }
    $projects{CURRPROJECT}[0] = $id;

    if ($id) {
        $projects{COMMENTOUT}[0] = "";
        $projects{COMMENTEND}[0] = "";
        $projects{ACTION}[0]     = "Editing";

    }
    else {
        $projects{COMMENTOUT}[0] = "<!--\n";
        $projects{COMMENTEND}[0] = "-->\n";
        $projects{ACTION}[0]     = "Choose a";
    }
    if ( !$choice ) {
        unshift( @{ $projects{'projectid'} }, "" );
        unshift( @{ $projects{'project'} },   "" );
        unshift( @{ $projects{'SELECTED'} },  "selected" );
    }
    $projects{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};
    $projects{COMPONENTLABEL}[0] = $c{general}{label}{componentid};
    $projects{MILESTONELABEL}[0] = $c{general}{label}{target_milestone};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'projectlist.tmpl',$userid);
    my($html)= &Process( \%projects, $templatefile );
    return $html;
}

sub drawComponents() {
    my ( $projectid, $userid ) = @_;
    my ($sql) =
"select distinct cmp.rec_type,cmp.description,cmp.componentid,cmp.component,cmp.initialowner,cmp.initialqacontact,cmp.projectid,cmp.active,cmp.cc from traq_components cmp, user_groups grp, acl_traq_components acl where cmp.projectid=$projectid and grp.userid=$userid and grp.groupid=acl.groupid and cmp.componentid=acl.componentid order by cmp.component";
    my (%res)  = &doSql($sql);
    my (%emps) = &GetEmployeeList("active");
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'employeemenu.tmpl',$userid);
    my($menu)= &Process( \%emps, $templatefile );
    if (%res) {
        for ( my ($i) = 0 ; $i < scalar( @{ $res{'componentid'} } ) ; $i++ ) {
            $res{PROJECTID}[$i] = $projectid;
            $res{EMP_MENU}[$i]  = $menu;
            if ( $res{'active'}[$i] ) {
                $res{'checked'}[$i] = 'checked';
            }
            if ( grep( /bug/, split( " ", $res{'rec_type'}[$i] ) ) ) {
                $res{'bugcheck'}[$i] = 'checked';
            }
            else {
                $res{'bugcheck'}[$i] = '';
            }
            if ( grep( /task/, split( " ", $res{'rec_type'}[$i] ) ) ) {
                $res{'taskcheck'}[$i] = 'checked';
            }
            else {
                $res{'taskcheck'}[$i] = '';
            }
            $res{'initialownerid'}[$i]     = $res{'initialowner'}[$i];
            $res{'initialqacontactid'}[$i] = $res{'initialqacontact'}[$i];
            $res{'initialowner'}[$i] =
              &getNameFromId( $res{'initialowner'}[$i] );
            $res{'initialqacontact'}[$i] =
              &getNameFromId( $res{'initialqacontact'}[$i] );
            my (%tmp);
            $tmp{projectid} = $projectid;
            @{ $tmp{cc} } = split( ',', $res{cc}[$i] );
            $res{'COMPONENTIDCC_OPTIONLIST'}[$i] =
              &getFieldOptionList( 'cc', \%tmp, $userid );

            foreach $field ( 'componentidlabel', 'techlabel', 'qalabel' ) {
                $res{$field}[$i] = $c{general}{$field};
            }
        }
        my (%tmp);
        $tmp{projectid} = $projectid;
        @{ $tmp{cc} } = ();
        $res{'COMPONENTIDCC0_OPTIONLIST'}[$i] =
          &getFieldOptionList( 'cc', \%tmp, $userid );
    }
    $res{'PROJECTNAME'}[0] = &getProjectNameFromId($projectid);
    $res{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};

    # get project info and default roles to project defaults
    my (%projectdata) =
      &doSql("select * from traq_project where projectid=$projectid");
    $res{DEFAULT_DEV_OPTIONLIST}[0] =
      &getUserOptionList( $projectid, $projectdata{'default_dev'}[0] );
    $res{DEFAULT_QA_OPTIONLIST}[0] =
      &getUserOptionList( $projectid, $projectdata{'default_qa'}[0] );
    $res{'PID'}[0] = $projectid;
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'viewcomponents.tmpl',$userid);
    my($html)= &Process( \%res, $templatefile );
    return $html;
}

sub drawMilestones() {
    my ($pid) = shift;
    my ($sql) = "select * from traq_milestones where projectid in ($pid)";
    my (%res) = &doSql($sql);
    $res{PID}[0]              = $pid;
    $res{'PROJECTNAME'}[0]    = &getProjectNameFromId($pid);
    $res{PROJECTIDLABEL}[0]   = $c{general}{label}{projectid};
    $res{'MILESTONELABEL'}[0] = $c{general}{label}{target_milestone};
	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'miles.tmpl',$userid);
    my($html)= &Process( \%res, $templatefile );
    return $html;
}

sub drawMenus() {
    my ($pid) = @_;
    my (%res);
    my ($item);
    my ($i) = 0;
    foreach $item ( split( ',', $c{general}{projectmenu} ) ) {
        $res{MENU}[$i]            = $item;
        $res{MENULABEL}[$i]       = $c{general}{label}{$item};
        $res{'PROJECTID_VAL'}[$i] = $pid;
        $i++;
    }
    $res{'PID'}[0]          = $pid;
    $res{'PID'}[0]          = $pid;
    $res{'PROJECTNAME'}[0]  = &getProjectNameFromId($pid);
    $res{PROJECTIDLABEL}[0] = $c{general}{label}{projectid};

	my($templatefile)=&getTemplateFile($c{dir}{generaltemplates},'menus.tmpl',$userid);
    my($html)= &Process( \%res, $templatefile );
    return $html;
}

sub sendHeader {
    my ( $headersent, $q ) = @_;
    unless ($headersent) {
        print $q->header;
        $headersent++;
    }
}


