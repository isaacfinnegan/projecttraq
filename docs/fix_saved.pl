#!/usr/bin/perl
use MIME::Base64;

$host=$ARGV[0];
$user=$ARGV[1];
$passwd=$ARGV[2];
$db=$ARGV[3];

$cmd=$ARGV[4];

unless($host && $user && $passwd && $db && $cmd)
{
	print "Usage: fix_saved.pl <db host> <db user> <db pass> <db> <cmd: list|showfix|fix>\n";
	exit;
}
if($passwd eq 'nopass')
{
    $passwd='';
}
use DBI;
$dbh = DBI->connect("DBI:mysql:host=$host;database=$db", $user, $passwd) or die 'connect';

$sth = $dbh->prepare("select l.username,q.name,q.query,q.userid from traq_namedqueries q,logins l where l.userid=q.userid") or die 'prepare'; # get ready to run this statement
$sth->execute or die 'execute'; # execute the statement

while (@data = $sth->fetchrow_array) 
{ 
	$decoded=decode_base64($data[2]);
	if($decoded=~/,\ traq_cc\ cc/ )
	{
		if($cmd eq 'showfix' || $cmd eq 'fix')
		{
			$decoded=~s/,\ traq_cc\ cc/\ left\ join\ traq_cc\ on\ cc\.record_id=rec\.record_id/;
			$decoded=~s/\((cc\.who\ =\ \d+)\ and\ cc\.record_id\ =\ rec\.record_id\)/$1/;
		}
		if($cmd eq 'list' || $cmd eq 'showfix')
		{
			print "$data[0] - $data[1]\n$decoded";
			print "---------------------------\n";
		}
		if($cmd eq 'fix')
		{
			print "Fixing $data[0] - $data[1]\n";
			$encoded=encode_base64($decoded);
			$update_sql="update traq_namedqueries set query='$encoded' where userid=$data[4] and name='$data[1]'";
			$dbh->do($update_sql);

		}
	}
}
$sth->finish; # finish up.
$dbh->disconnect; # disconnect

