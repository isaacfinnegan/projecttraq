#!/usr/bin/perl
###############################################################
#    Copyright (C) 2001-2003 Isaac Finnegan
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
# All fields in templates use the following conventions:
# FIELDNAME_VAL = will be the form value
# FIELDNAME_DISP = will be the display valuek,
# FIELDNAME_SEL = will be the selected value (for option lists)
#
# For fields that have an option list (menu selects) the [[FIELDNAME_LIST]]
# if a field does not have a separate value/display value then use the FIELDNAME_DISP for templates
#
#
#
#
#
#
#
#
#
#############################################################r
use lib "./";
##############################################################
package Traqfields;

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
  &getFieldDisplayValue
  &getFieldValue
  &getFieldOptionList
  &saveField
);
our %EXPORT_TAGS = ( ALL => [ @EXPORT, @EXPORT_OK ] );
use TraqConfig;
use Date::Calc;
use supportingFunctions;
use vars qw(%c);
*c = \%TraqConfig::c;

####################################################################
# generic funcs
sub getFieldDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	$field =~ s/\b([_\w]+)\b/$1/;
	no strict 'refs';
	my ($value) = ${$recordref}{$field};
	my ($func) = $field . 'DisplayValue';
	my(@menus);
	push(@menus,split(',',$c{general}{projectmenu}));
	push(@menus,split(',',$c{general}{systemmenu}));
	my(@roles)=split(',',$c{general}{rolemenu});
	if ( exists &$func )
	{
		$value = &$func( $field, $recordref, $userid );
	}
	elsif(grep /^$field$/, @menus)
	{
		$value= &genericmenuDisplayValue( $field, $recordref, $userid );
	}
	else
	{
		$value = &supportingFunctions::escapeHtml($value);
	}
	unless ($value)
	{
		$value = "";
	}
	return $value;
}

sub getFieldOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	$field =~ s/\b([_\w]+)\b/$1/;
	my ($value) = $$recordref{$field};
	no strict 'refs';
	my ($func) = $field . 'OptionList';
	my(@roles)=split(',',$c{general}{rolemenu});
	if ( exists &$func )
	{
		$value = &$func( $field, $recordref, $userid );
	}
	elsif(&supportingFunctions::isSystemMenu($field) || &supportingFunctions::isProjectMenu($field))
	{
		$value=&genericmenuOptionList($field,$recordref,$userid);
	}
	elsif(grep /^$field$/, @roles)
	{
		$value= &genericUserOptionList( $field, $recordref, $userid );
	}
	else
	{
		return;
	}
	return $value;
}

sub saveField
{
	my ( $field, $olddataref, $newdataref, $userid ) = @_;
	$field =~ s/\b([_\w]+)\b/$1/;
	my ($value)=$$newdataref{$field};
	no strict 'refs';

	my ($func) = $field . 'Save';
	if ( exists &$func )
	{
		$value = &$func( $field, $olddataref, $newdataref, $userid );
	}
	elsif(	grep(/^$field$/ , split(',',$c{general}{datefields})) )
	{
		if ( $value=~/^\s+$/ || ord($value) eq 160 || $value eq '' )
		{
			$value = '0000-00-00';
		}
	}
	return $value;
}

sub getFieldValue
{
	my ( $field, $recordref, $userid ) = @_;
	my($value)= $$recordref{$field};
	no strict 'refs';
	
	my ($func) = $field . 'Value';
	if ( exists &$func )
	{
		$value = &$func( $field, $recordref, $userid );
	}
	return $value;
}
sub genericmenuDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	if(&supportingFunctions::isSystemMenu($field)) 
	{
		$projectid=0;
	}
	$value = &supportingFunctions::getMenuDisplayValue( $projectid, $field, $value, $type );
	return $value;
}
sub genericmenuOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( $field, $projectid, $type, $value ,$userid );
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}
sub genericUserOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	my (%userhash)  = &supportingFunctions::db_GetUserHashforProject($projectid);
	my ( %rehash, $user, $username, $i, $html, $found );
	$found=0;
	my(@value)=split(',',$value);
	foreach $user ( keys(%userhash) )
	{
		$rehash{ $userhash{$user}{full_name} } = $user;
	}
	my (@usernames) = keys(%rehash);
	@usernames = sort @usernames;
	for ( $i = 0 ; $i < scalar(@usernames) ; $i++ )
	{
		if ( grep(/^$rehash{$usernames[$i]}$/ , @value) )
		{
			$html .= "<option value=\"$rehash{$usernames[$i]}\" selected>$usernames[$i]</option>\n";
			$found=1;
		}
		else
		{
			$html .= "<option value=\"$rehash{$usernames[$i]}\">$usernames[$i]</option>\n";
		}
	}
	if($value && !$found)
	{
		my($name)=&supportingFunctions::getNameFromId($value);
		$html="<option value=\"$value\" selected>$name</option>\n".$html;
	}
	else
	{
		$html="<option value=\"\"></option>\n".$html;
	}
	return $html;
}


###########################################################################
# Individual field funcs

# Save funcs
# Save functions do not save data, but return the data to be saved
# these functions should be used mostly for workflow implementation, 
# i.e. when fields should change automatically based on some criteria

# keywordSave is unique, as it actually does the save since the data is in another table
sub keywordsSave
{
	my ( $field, $origref,$recordref,$userid ) = @_;
	my(@originalkw,@newkw,$key,%hashsort);
	my($note)=$$recordref{note};
	my($area)=$$origref{type}.'traq';
	my (%record)   = %$recordref;
	if($record{record_id})
	{
		my (%keywords) = &supportingFunctions::doSql("select * from traq_keywordref where record_id=$record{record_id}");
		if(%keywords)
		{
			@originalkw=@{$keywords{keywordid}};
		}
	}
	if($$recordref{keywords})
	{
        @newkw=@{$$recordref{keywords}};
    
        #setup lookup hash
        foreach $key (@newkw) { $hashsort{$key}=1 }
        #find keywords that have been removed
        foreach $key (@originalkw)
        {
            unless($hashsort{$key})
            {
                if (   $c{$area}{requirecomment}
                    && !$note
                    && $c{$area}{requirecomment} ne 'auto' )
                {
                    &supportingFunctions::doError( "PleaseCommentOnChange", "", '', "NoNote:" );
                }
                &supportingFunctions::log("Deleting keyword: $key",6);
                &supportingFunctions::doSql("delete from traq_keywordref where record_id=$record{record_id} and keywordid=$key");	
                &supportingFunctions::makeActivityEntry($userid,$record{record_id},'traq_keywordref','keywordid',$key,'');
            }
        }
        %hashsort=();
        #setup lookup hash
        foreach $key (@originalkw) { $hashsort{$key}=1 }
        #find keywords that have been added
        foreach $key (@newkw)
        {
            unless($hashsort{$key})
            {
                if (   $c{$area}{requirecomment}
                    && !$note
                    && $c{$area}{requirecomment} ne 'auto' )
                {
                    &supportingFunctions::doError( "PleaseCommentOnChange", "", '', "NoNote:" );
                }
                &supportingFunctions::log("Adding keyword: $key",6);
                &supportingFunctions::doSql("insert into traq_keywordref set record_id=$record{record_id} , keywordid=$key");	
                &supportingFunctions::makeActivityEntry($userid,$record{record_id},'traq_keywordref','keywordid','',$key);
            }
        }
        return @$recordref{keywords};
    }
    else
    {
	   return $$recordref{keywords};
    }
}
sub signoffSave {
 my ( $field, $origref,$recordref,$userid ) = @_;
 my $who =&supportingFunctions::getNameFromId($userid);
 my $time = &supportingFunctions::makeMysqlTimestamp(time());
	$time=~s/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/$1-$2-$3 $4:$5:$6/;
 my $newsignoff;
 if($$recordref{signoff})
 {
     $newsignoff= "$$origref{signoff}$who - $time\n";
 }
 else
 {
     $newsignoff= "$$origref{signoff}";
 }
 return $newsignoff;
}

# ccSave also does the save, data resides in another table from the record
sub ccSave
{
	my ( $field, $origref,$recordref,$userid ) = @_;
	my($cc,%hashsort,@originalCCs);
	my(%record)=%$recordref;
	my($note)=$$recordref{note};
	my($area)=$$origref{type}.'traq';
###
#TODO not sure why but sometime excel import causes a space to make it in here instead of empty field.
	$$recordref{cc}=~s/^\s//g;
###
	if($$recordref{cc})
	{
        my(@newCCs)=@{$$recordref{cc}};
        if($record{record_id})
        {
            @originalCCs = &supportingFunctions::getRecordCcs( $record{'record_id'} );
        }
        #setup lookup hash
        foreach $cc (@newCCs) { $hashsort{$cc}=1 }
        #find cc's that have been removed
        foreach $cc (@originalCCs)
        {
            unless($hashsort{$cc} || $cc eq '0')
            {
                if (   $c{$area}{requirecomment}
                    && !$note
                    && $c{$area}{requirecomment} ne 'auto' )
                {
                    &supportingFunctions::doError( "PleaseCommentOnChange", "", '', "NoNote:" );
                }
                &supportingFunctions::log("Deleting old CC: $cc",6);
                &supportingFunctions::deleteCc( $record{'record_id'}, $cc, $userid );
                @{$$recordref{changes}[$#{$$recordref{changes}}+1]} = ( ('traq_cc','cc',$cc,'') );
            }
        }
        #setup lookup hash
        %hashsort=();
        foreach $cc (@originalCCs) { $hashsort{$cc}=1 }
        #find cc's that have been added
        foreach $cc (@newCCs)
        {
            unless($hashsort{$cc})
            {
                if (   $c{$area}{requirecomment}
                    && !$note
                    && $c{$area}{requirecomment} ne 'auto' )
                {
                    &supportingFunctions::doError( "PleaseCommentOnChange", "", '', "NoNote:" );
                }
                &supportingFunctions::log("Inserting new CC: $cc",6);
                &supportingFunctions::insertNewCc( $record{'record_id'}, $cc, $userid );
                @{$$recordref{changes}[$#{$$recordref{changes}}+1]} = ('traq_cc','cc','',$cc);
            }
        }
	}
	return $$recordref{cc};
}


sub componentidSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value)          = $$recordref{$field};
	my ($note)           = $$recordref{note};
	my (%record)         = %$recordref;
	my (%originalRecord) = %$origref;
	my ($area)=$$origref{type}.'traq';
	if($originalRecord{componentid} ne $record{componentid})
	{
		if($record{record_id})
		{
			&supportingFunctions::doSql("delete from acl_traq_records where record_id=$record{record_id}");
			my (@compgroups) = &supportingFunctions::getComponentGroups( $record{'componentid'} );
			# Create security ACL's for record
			my($group);
			foreach $group (@compgroups)
			{
				my ($sql) = "insert into acl_traq_records set groupid=$group,record_id=$record{record_id}";
				my ($ret) = &supportingFunctions::doSql($sql);
			}
		}
	}
	return $value
}
sub statusSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value)          = $$recordref{status};
	my ($note)           = $$recordref{note};
	my (%record)         = %$recordref;
	my (%originalRecord) = %$origref;
	my ($area)=$$recordref{type}.'traq';
	# has status changed?

	#bug
	if ( $$origref{type} eq 'bug' )
	{
		unless ( $record{'status'} eq $originalRecord{'status'} )
		{
			if (   $c{bugtraq}{requirecomment}
				&& !$note
				&& $c{bugtraq}{requirecomment} ne 'auto' )
			{
				&supportingFunctions::doError( "PleaseCommentOnChange", "", "", "NoNote:" );
			}
			if (   
				$record{'status'} > $c{bugtraq}{resolved}
				&& 
				$originalRecord{'status'} < $c{bugtraq}{resolved} 
			   )
			{
				# make sure record is resolved before marking closed
				unless ( $$origref{'resolution'} )
				{
					&supportingFunctions::doError( "This bug was not in a resolved state, please resolve before trying to close.", "", "", "NoResolution" );
				}
			}
		}
		# set to resolved if resolution changed and status didn't
		if ( 
				$area eq 'bugtraq' 
				&& 
				!$$origref{resolution} 
				&& 
				$$recordref{resolution} 
				&& 
				$$origref{status} eq $$recordref{status} 
				&&
				$c{bugtraq}{autoresolve}
			)

		{
			$value=$c{bugtraq}{resolved};
		}
	}
	#auto change record status if not changed and config says to change the record $c{area}{autostatusfromedit}
	if(%originalRecord)
	{
		if(	
			$c{$area}{autostatusfromedit} eq $record{status} 
			&& 
			$value eq $originalRecord{status}
		  )
		{
			$value=$c{$area}{autostatustoedit};
		}
	}
	
	&supportingFunctions::log("TEST: $value - $c{$area}{'new'}");
	unless($value)
	{
		$value=$c{$area}{'new'};
	&supportingFunctions::log("TEST: inside unless $area - $value - $c{$area}{'new'}");
	}
	if($value >= $c{$area}{closethreshold} && $c{$area}{enforcedependency})
	{
		&supportingFunctions::verifyDependencies( $record{'record_id'} );
	}
	return $value;
}
sub resolutionSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value)          = $$recordref{resolution};
	my ($note)           = $$recordref{note};
	my (%record)         = %$recordref;
	my (%originalRecord) = %$origref;
	my ($area)=$$origref{type}.'traq';
	# clear resolution when setting to reopened.
	if($$origref{type} eq 'bug')
	{
		if(
			(
				$$recordref{status} eq $c{bugtraq}{reopened}
		  		&&
		  		$$recordref{status} ne $$origref{status}
		  	)
		  	||
		  	(
		  		$originalRecord{status} >= $c{bugtraq}{resolved}
		  		&&
		  		$record{status} < $c{bugtraq}{resolved} 
		  	)
		  	&&
		  	$c{bugtraq}{autoclearresolution}
		  )
		{
			$value="";
		}
		if($record{resolution} eq $c{bugtraq}{resolutionduplicate} && $record{resolution} ne $originalRecord{resolution})
		{
			$note=~/---Marked\ duplicated\ of\ [bBtT](\d+)\ ---/;
			if($1 && $1=~/\d+/)
			{
				my(@tmp)=split('',$record{type});
				my($tmprec)=uc($tmp[0]) . $record{record_id};
				my($text)="--- $tmprec marked duplicate of this record ---\n";
				&supportingFunctions::doSql("insert into traq_longdescs set who=\"$userid\", thetext=\"$text\",date=now(),record_id=$1");
			}
		}
	}
	return $value;
}
sub assigned_toSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value) = $$recordref{assigned_to};

	# bug
	if ( $$origref{type} eq 'bug' )
	{
		# assign back to tech_contact for reopen
		if (   $$recordref{'status'} == $c{bugtraq}{reopened}  # if status is reopen
			&& $$origref{'status'} != $c{bugtraq}{reopened}  # and orginal status wasn't reopen
			&& $$recordref{'assigned_to'} == $$origref{'assigned_to'} # and assigned_to wasn't changed
			)
		{
			$value = $$recordref{tech_contact};   # assign to tech
		}

		# assign to qa_contact if resolved
		if ( $$recordref{resolution} ne $$origref{resolution}   # if resolution is set when it wasn't
				&& $$recordref{resolution}  # and there's a value for resolution
				&& $$recordref{'assigned_to'} eq $$origref{'assigned_to'}  # and assigned_to hasn't been changed
			)
		{
			$value = $$recordref{qa_contact};   # assign to qa
		}

	}

	# assign to tech_contact if null
	if ( $$recordref{assigned_to} eq '' )
	{
		if ( $$recordref{tech_contact} eq '' )
		{
			$value = &supportingFunctions::getDefaultTech( $$recordref{'componentid'} );
		}
		else
		{
			$value = $$recordref{tech_contact};
		}
	}
	return $value;
}
sub tech_contactSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value) = $$recordref{tech_contact};
	#added by bsharma
	if ($$recordref{'status'} == $c{bugtraq}{reopened}
			&& $$origref{'status'} != $c{bugtraq}{reopened}
			&& $$recordref{'tech_contact'} == $$origref{'tech_contact'} )
	{
			$value = $$recordref{tech_contact};
	}
	#end
	unless($value)
	{
		$value = &supportingFunctions::getDefaultTech( $$recordref{'componentid'} );
	}
	return $value;
}
sub qa_contactSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value) = $$recordref{qa_contact};
	unless($value)
	{
		$value = &supportingFunctions::getDefaultQa( $$recordref{'componentid'} );
	}
	return $value;
}
sub target_milestoneSave
{
	my ( $field, $origref, $recordref, $userid ) = @_;
	my ($value) = $$recordref{target_milestone};
# 	unless($value)
# 	{
# 		my(%lookup)=&supportingFunctions::doSql("select * from traq_milestones where milestone='TBD' and projectid=$$recordref{projectid}");
# 		if(%lookup)
# 		{
# 			$value = $lookup{milestoneid}[0];
# 		}
# 	}

	if($$origref{target_milestone}==0 && $value eq '')
	{
		$value=0;
	}
	return $value;
}


#Optionlist funcs

sub ccOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	my (%userhash)  = &supportingFunctions::db_GetUserHashforProject($projectid);
	my ( %rehash, $user, $username, $i, $html );
	my(%usercheck);
	my (@recordcc);
	if($$recordref{record_id})
	{
		@recordcc= &supportingFunctions::getRecordCcs( $$recordref{record_id} );
	}
	elsif($$recordref{cc})
	{	
		if(ref($$recordref{cc}) eq 'ARRAY')
		{
			@recordcc=@{$$recordref{cc}};
		}
		else
		{
			@recordcc=split('\0',$$recordref{cc});
		}
	}
# If record has CC's already spit them out
	if ( scalar(@recordcc) )
	{

		foreach $user (@recordcc)
		{
			my($displayname)=$userhash{$user}{full_name} || &supportingFunctions::getNameFromId($user);
			if($user) 
			{
				$html .= "<li><label><input type=checkbox name=cc value=\"$user\" checked>$displayname</label></li>\n";
			}
			$usercheck{$user}=1;
		}
	}
	foreach $user ( keys(%userhash) )
	{
		$rehash{ $userhash{$user}{full_name} } = $user;
	}

# Setup user list, minus the users that are already set as CC
	my (@usernames) = sort(keys(%rehash));
	for ( $i = 0 ; $i < scalar(@usernames) ; $i++ )
	{
		unless($usercheck{$rehash{$usernames[$i]}})
		{
			unless($i)
			{
				$html .= "<li style=\"border-top:1px dotted grey\"><label><input type=checkbox name=cc value=\"$rehash{$usernames[$i]}\">$usernames[$i]</label></li>\n";
			}
			else
			{
				$html .= "<li><label><input type=checkbox name=cc value=\"$rehash{$usernames[$i]}\">$usernames[$i]</label></li>\n";
			}
		}
	}
	return $html;
}

sub keywordsOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ( $html,  %rehash,    $key ,%hashsort,@recordkeywords);

	my (%keywords) = &supportingFunctions::getKeywords();
	if(%keywords)
	{
		if($$recordref{record_id})
		{
			@recordkeywords = split( ',', &supportingFunctions::getRecordKeywords( $$recordref{record_id} ) );
		}
		elsif($$recordref{keywords})
		{
			@recordkeywords = split('\0',$$recordref{keywords});
		}
		# sort keywords by name so we can display them
		my (@sortedkeywords) = sort(@{ $keywords{name} });
		# rehash the system keyword list into a lookup hash
		for ( my ($i) = 0 ; $i < scalar( @{$keywords{name}} ) ; $i++ )
		{
			$rehash{ $keywords{name}[$i] } = $keywords{keywordid}[$i];
		}
		# put record keywords into a lookup hash
		foreach $key (@recordkeywords) { $hashsort{$key}=1 }
		foreach $key (@sortedkeywords)
		{
			if ( $hashsort{$key} || $hashsort{$rehash{$key}})
			{
				$html .= "<input type=checkbox name=keywords checked value=$rehash{$key}>$key ";
			}
			else
			{
				$html .= "<input type=checkbox name=keywords value=$rehash{$key}>$key ";
			}
		}
	}
	return $html;
}

sub projectidOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{projectid};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	my ( @groups,$item, $html );
	my($found)=0;
	my(@value)=split(',',$value);
	@groups = &supportingFunctions::GetUserGroups($userid);
	my (%projects) = &supportingFunctions::getAuthorizedProjects( '', \@groups, $type );
	if(%projects)
	{
        for ( my ($i) = 0 ; $i < scalar( @{ $projects{'project'} } ) ; $i++ )
        {
    
            if ( grep(/^$projects{projectid}[$i]$/ ,@value ))
            {
                $html .= "<option value=\"$projects{projectid}[$i]\" selected>$projects{project}[$i]</option>\n";
                $found=1;
            }
            else
            {
                $html .= "<option value=\"$projects{projectid}[$i]\">$projects{project}[$i]</option>\n";
            }
        }
    }
	if(@value && !$found)
	{
		foreach $item (@value)
		{
			$html="<option value=\"$item\">" . & getFieldDisplayValue($field,$recordref,$userid) . "</option>\n" . $html;
		}
	}
	
	return $html;
}

sub componentidOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($area) 	=$type.'traq';
	my ($projectid) = $$recordref{projectid};
	my (%compmenu)  = &supportingFunctions::getComponents( $projectid, '', $type );
	my ( %rehash, $comp, $username, $i, $html );
	unless(%compmenu)
	{
		&supportingFunctions::doError("This project has no $c{$area}{label}{componentid}(s) defined");
	}
	for ( $i = 0 ; $i < scalar( @{ $compmenu{component} } ) ; $i++ )
	{
		if($rehash{ $compmenu{component}[$i] })
		{
			$rehash{ $compmenu{component}[$i] } .= ','.$compmenu{componentid}[$i];
		}
		else
		{
			$rehash{ $compmenu{component}[$i] } = $compmenu{componentid}[$i];
		}
	}
	my (@components) = keys(%rehash);
	unless ($value)
	{
		$html.="<option value=''>\n";
	}
	@components = sort {lc($a) cmp lc($b)} @components;
	for ( $i = 0 ; $i < scalar(@components) ; $i++ )
	{
		if ( $rehash{ $components[$i] } eq $value )
		{
			$html .= "<option value=\"$rehash{$components[$i]}\" selected>$components[$i]</option>\n";
		}
		else
		{
			$html .= "<option value=\"$rehash{$components[$i]}\">$components[$i]</option>\n";
		}
	}
	return $html;

}

sub target_milestoneOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	my ( $i, $html, %rehash,$item, $selected);
	my (%milestones) = &supportingFunctions::getMilestones($projectid);
	if (%milestones)
	{

		for ( $i = 0 ; $i < scalar( @{ $milestones{'milestone'} } ) ; $i++ )
		{
			if($rehash{ $milestones{milestone}[$i] })
			{
				$rehash{ $milestones{milestone}[$i] } .= ','.$milestones{milestoneid}[$i];
			}
			else
			{
				$rehash{ $milestones{milestone}[$i] } = $milestones{milestoneid}[$i];
			}
		}
		my (@milestones) = keys(%rehash);
		@milestones = sort @milestones;
		for ( $i = 0 ; $i < scalar( @milestones) ; $i++ )
		{
			foreach $item (split(',',$rehash{ $milestones[$i] }))
			{
				if ( $value=~/(^|,)$item(,|$)/ )
				{
					$selected=1;
				}
			}
		
			if( $selected ||
				( !$value && $milestones{sortkey}[$i])
			)
			{
				$html .= "<option value=\"$rehash{$milestones[$i]}\" selected>$milestones[$i]</option>\n";
			}
			else
			{
				$html .= "<option value=\"$rehash{$milestones[$i]}\">$milestones[$i]</option>\n";
			}
			$selected=0;
		}
	}
	$html="<option value=\"\"></option>\n".$html;
	return $html;

}

sub statusOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "status", $projectid, $type, $value  ,$userid);
}

sub resolutionOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "resolution", $projectid, $type, $value ,$userid );
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub reproducibilityOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "reproducibility", $projectid, $type, $value  ,$userid);
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub versionOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "version", $projectid, $type, $value  ,$userid);
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub bug_op_sysOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "bug_op_sys", $projectid, $type, $value ,$userid );
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub bug_platformOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "bug_platform", $projectid, $type, $value  ,$userid);
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub severityOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "severity", $projectid, $type, $value ,$userid );
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

sub priorityOptionList
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	my ($type)  = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuOptionList( "priority", $projectid, $type, $value ,$userid);
	$value="<option value=\"\"></option>\n".$value;
	return $value;
}

# Display Value funcs
sub signoffDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{signoff};
	$value=~s/\n/<br>/g;
	return $value;
}
sub target_dateDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{target_date};
	if ( $value eq '0000-00-00' )
	{
		$value = '';
	}
	elsif(lc($value) eq 'today')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	elsif(lc($value) eq 'yesterday')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		($year,$month,$day) = &Date::Calc::Add_Delta_Days($year,$month,$day,-1);
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	elsif(lc($value) eq 'tomorrow')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		($year,$month,$day) = &Date::Calc::Add_Delta_Days($year,$month,$day,1);
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	return $value;
}

sub start_dateDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{start_date};
	if ( $value eq '0000-00-00' )
	{
		$value = '';
	}
	elsif(lc($value) eq 'today')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	elsif(lc($value) eq 'yesterday')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		($year,$month,$day) = &Date::Calc::Add_Delta_Days($year,$month,$day,-1);
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	elsif(lc($value) eq 'tomorrow')
	{
		my($year,$month,$day) = &Date::Calc::Today();
		($year,$month,$day) = &Date::Calc::Add_Delta_Days($year,$month,$day,1);
		$value=sprintf("%04d-%02d-%02d",$year,$month,$day);
	}
	return $value;
}

sub changedbyDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}

sub statusDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuDisplayValue( $projectid, $field, $value, $type );
	return $value;
}

sub severityDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuDisplayValue( $projectid, $field, $value, $type );
	return $value;
}

sub resolutionDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($type)      = $$recordref{type};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMenuDisplayValue( $projectid, $field, $value, $type );
	return $value;
}

sub target_milestoneDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value)     = $$recordref{$field};
	my ($projectid) = $$recordref{projectid};
	$value = &supportingFunctions::getMilestoneDisplayValue( $projectid, $value );
	return $value;
}

sub projectidDisplayValue
{
	no strict 'refs';
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	my ($type)  = $$recordref{type};
	$value = &supportingFunctions::getProjectNameFromId($value);
	return $value;
}

sub componentidDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	my ($type)  = $$recordref{type};
	$value = &supportingFunctions::getComponentNameFromId($value);
	return $value;
}

sub record_idDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	my ($type)  = $$recordref{type};
	$value = uc( substr( $type, 0, 1 ) ) . $value;
	return $value;
}

sub assigned_toDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}

sub tech_contactDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}

sub qa_contactDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}

sub reporterDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}


sub whoDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = $$recordref{$field};
	$value = &supportingFunctions::getNameFromId($value);
	return $value;
}
sub days_remDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = '';
	my($area)=$$recordref{type} . 'traq';
	if($$recordref{target_date}=~/-/ && $$recordref{status} < $c{$area}{closethreshold} && $$recordref{target_date} ne '0000-00-00')
	{
		my($YY,$MM,$DD)=split('-',$$recordref{target_date});
		my($y2,$m2,$d2);
		$DD=~s/0(\d)/$1/;
		$MM=~s/0(\d)/$1/;
		($y2,$m2,$d2)=Date::Calc::Today();
		my($Dd)=eval("Date::Calc::Delta_Days($y2,$m2,$d2,$YY,$MM,$DD)");
		$value=$Dd;
		if($value < 2)
		{
			$value="<font color=red><b>$value</b></font>";
		}
	}
	return $value;
}

# brian!!!
sub resolved_dateDisplayValue 
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = '-';
	
#	my ($value)     = $$recordref{status};
#	my ($type)      = $$recordref{type};
#	my ($projectid) = $$recordref{projectid};
	
	if($$recordref{status} >= $c{bugtraq}{resolved})
	{
		# the most recent update gets returned
		my(%return_set) = &supportingFunctions::doSql("select date from traq_activity where record_id=$$recordref{record_id} and fieldname='status' and newvalue = $c{bugtraq}{resolved} order by date desc limit 1");
		
		$value=@{$return_set{date}}[0];
	}
	
	return $value;
}

sub closed_completed_dateDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($value) = '-';
	
	if($$recordref{status} >= $c{bugtraq}{closethreshold})
	{
		# the most recent update gets returned
		my(%return_set) = &supportingFunctions::doSql("select date from traq_activity where record_id=$$recordref{record_id} and fieldname='status' and newvalue >= $c{bugtraq}{closethreshold} order by date desc limit 1");

		$value=@{$return_set{date}}[0];
	}
		
	return $value;
}

sub long_descDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	if($$recordref{long_desc})
	{
		return $$recordref{long_desc};
	}
	my($value)=&supportingFunctions::getLongDesc($$recordref{record_id},'','',$recordref,$userid);
	my $urls = '(http|https|telnet|gopher|file|wais|ftp|mailto)';
	my $ltrs = '\w';
	my $gunk = '/#~;:.?+=&%@!\-';
	my $punc = '.:?\-';
	my $any = "${ltrs}${gunk}${punc}";
	my $url = "$c{url}{base}/redir.cgi?id=";
	my $urlbase="$c{url}{base}/";

	$value =~ s{\b($urls:[$any] +?)(?=[$punc]* [^$any]|$) }{<a href="$1">$1</a>}igox;
	$value =~ s/([\s\(\[,\.-pP])([bBtT]\d+)([\s\)\],\.-?])/$1<a href="$url$2" qtip="$urlbase\/getRec.cgi?label=1&mode=getfields&fieldlist=record_id,short_desc,status,assigned_to&delimiter=<br>&id=$2">$2<\/a>$3/g;
	return $value;
}
sub long_descValue
{
	my ( $field, $recordref, $userid ) = @_;
	if($$recordref{long_desc})
	{
		return $$recordref{long_desc};
	}
	my($value)=&supportingFunctions::getLongDesc($$recordref{record_id},'plain');
	return $value;
}
sub keywordsDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my(@recordkeywords);
	if( $$recordref{record_id})
	{
		return &supportingFunctions::getRecordKeywords( $$recordref{record_id} );
	}
	else
	{
		return;
	}
}
sub ccDisplayValue
{
	my ( $field, $recordref, $userid ) = @_;
	my (@recordcc,$cc,@ccnames);
	if($$recordref{record_id})
	{
		@recordcc= &supportingFunctions::getRecordCcs( $$recordref{record_id} );
	}
	foreach $cc (@recordcc)
	{
		push(@ccnames,&supportingFunctions::getNameFromId($cc));
	}
	return join('<br>',sort(@ccnames));
}
# Field value funcs
# ccValue and keywordsValue are unique in that they return the html for the field values.
sub ccValue
{
	my ( $field, $recordref, $userid ) = @_;
	my ($html,@recordcc,$cc,@ccnames);
	if($$recordref{record_id})
	{
		@recordcc= &supportingFunctions::getRecordCcs( $$recordref{record_id} );
	}
	else
	#if(ref($$recordref{cc}) eq "ARRAY" )
	{
		@recordcc=split('\0',$$recordref{cc});
	}
	
	return join(',',@recordcc);
}
sub keywordsValue
{	
	my ( $field, $recordref, $userid ) = @_;
    my($key,$html,@keywords);
    my($rec)=$$recordref{recordid};
    if($rec)
    {
		my(%res) = &supportingFunctions::doSql("select keywordid from traq_keywordref ref where ref.record_id=$rec");
		if(%res)
		{	
			@keywords=@{$res{keywordid}};
		}
	}
	else
    #if(ref($$recordref{keywords}) eq "ARRAY")
    {
		@keywords=split('\0',$$recordref{keywords});
    }
	return join(',',@keywords);
}

END { }
1;

