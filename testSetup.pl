use strict;
use CPAN;

print "\nChecking Perl setup:\n\n";

my ($config,$os, $prereq, $dbi, $dbDrivers,$force);
$prereq = 1;

if ($^O =~ /^Win/i) {
	$os = "Windows";
} else {
	$os = "Linux";
}

if($ARGV[0] eq 'forceinstall')
{
	$force=1;
}



print "Operating System ......................... ".$os."\n";

print <<MODULE;

###################################
    Checking Perl Module Setup
###################################

MODULE

print "Perl Interpreter ........................ ";
if ($] >= 5.006) {
	print "OK\n";
} else {
	print "Please upgrade to 5.6 or later!\n";
	exit;
}


my(@reqmodules)=(
'CGI'
,'DBI'
,'MIME::Base64'
,'Date::Calc'
,'Mail::Sendmail'
,'Crypt::Blowfish'
,'Crypt::CBC'
,'Storable'
,'Date::Manip'
,'JSON'
);
my(@optmodules)=(
'Apache::DBI'
,'Net::LDAP'
,'Sys::Syslog'
,'Spreadsheet::ParseExcel'
,'Spreadsheet::WriteExcel'
,'Cache::FileCache'
,'Cache::Memcached'
,'GD'
,'Time::Stopwatch'
,'Time::HiRes'
);
my $dbi;
my $dots=33;
foreach (@reqmodules)
{
	$dots=33;
	$dots=$dots-length($_);
	print "$_ module ";
	for(my $ii=0;$ii<$dots;$ii++) { print '.'; }
	if (eval "require $_;") {
		print " OK\n";
		$dbi = 1;
	} else {
		if ($< == 0 && $os eq "Linux") {
				print " Attempting to install...\n";
					CPAN::Shell->install($_);
			eval {require $_};
			$dbi = 1;
			} else {
					print " Please install.\n";
			$prereq = 0;
			$dbi = 0;
			}
	}

}
foreach (@optmodules)
{
	$dots=33;
	$dots=$dots-length($_);
	print "$_ module ";
	for(my $ii=0;$ii<$dots;$ii++) { print '.'; }
	if (eval  "require $_;") {
			print " OK\n";
	} else {

                if ($< == 0 && $os eq "Linux" && $force) {
                                print " Attempting to install...\n";
                                        CPAN::Shell->install($_);
                        eval {require $_};
                        $dbi = 1;
                        } 
		else
		{
			print " Optional\n";
		}
	}

}




print <<CONFCHECK;

###################################
   Checking configuration file 
###################################

CONFCHECK

print "Parsing Config file ...................... ";

open(CFG, '/usr/local/etc/traq.cfg') ||
open(CFG, '/etc/traq.cfg') ||
open(CFG, "$ENV{HOME}" . '/traq.cfg') ||
die "ERROR: Cannot open configuration file $!\n";
my(%c);
my(@conf) = <CFG>;
eval "@conf";

if($@)
{
	print "Error: $@";
}
else
{
	print "OK\n";
}

my (@files, $file, $dir, $error);
my($user, $password, $server, $database) = 
($c{db}{user}, $c{db}{password}, $c{db}{host}, $c{db}{database});
my($driver)= $c{db}{driver};
my($dsn) = "DBI:$driver:database=$database;host=$server";


###################################
# Checking for database driver 
###################################

print <<DBCHECK;

###################################
   Checking for database setup 
###################################

DBCHECK

print "Avalable database drivers ................ ";
if ($dbi) {
	print join(", ",DBI->available_drivers);
	$dbDrivers = join(", ",DBI->available_drivers);
} else {
	print "None";
	$prereq = 0;
}
print "\n";

print "Database driver .......................... ";
my (@driver);
@driver = split(/:/,$dsn);
                if ($dbDrivers =~ m/$driver[1]/) {
                        print "OK\n";
                } else {
                        print "Not installed!\n";
                }

###################################
# Checking database
###################################

print "Database connection ...................... ";
my ($dbh, $test);
unless (eval {$dbh = DBI->connect($dsn,$user,$password)}) {
	print "Can't connect with info provided!\n";
} else {
	print "OK\n";
	$dbh->disconnect();
}

print "\n";
