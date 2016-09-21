#!/usr/bin/perl

use DBI;
use DBD::mysql;

# Database Handle information and setup
# Set to values you have configured your MySQL Database for
$host = "";					# MySQL Server hostname
$db = "";					# Database name
$user = "";					# Database user with modification privledges
$pw = "";					# Database user password

die "usage: ./config.pl [configuration file]\nFor more options use -h or --help" if(@ARGV != 1);

if($ARGV[0] eq "-h" or $ARGV[0] eq "--help")
{
	print <<END;
This script is for uploading a configuration file to the configured
database. Please make sure this script has been modified with the
appropriate values for the database hostname, username, and password.\n
usage: ./config.pl [configuration file]\n
The file format must be as follows:
1\tFull Comic Title
2\tFolder name to store images in
3\tFull URL (including http://) of the index page for the comic
4\tFull URL of the first archive page or the archive page to start from
5\tRegular expression pattern to search for the 'Next' link in the
\tarchive pages
6\tRegular expression pattern to search for the comic images on each
\tarchive page
7\tDescription of the comic for display on the 'Comics' page of the
\tarchive. This can be left blank, but there must be at least seven
\tlines in the configuration file.
END
}
else
{
	$dbh = DBI->connect("DBI:mysql:database=$db:host=$host", $user, $pass);

	#read data from the cfg file for the comic
	open(CFG, "<$ARGV[0]") or die "Could not open file $ARGV[0]: $!\n";
	chomp (my $name = <CFG>);
	chomp (my $folder = <CFG>);
	chomp (my $indexURL = <CFG>);
	chomp (my $firstURL = <CFG>);
	chomp (my $nextPattern = <CFG>);
	chomp (my $imgPattern = <CFG>);
	chomp (my $desc = <CFG>);
	close(CFG);

	my $query = "INSERT INTO comics (cName, folder, firstPage, nextSearch, comicSearch, baseURL, description) VALUES (?, ?, ?, ?, ?, ?, ?)";
	#print "$query\n$name, $folder, $indexURL, $firstURL, $nextPattern, $imgPattern, $desc\n";
	my $sth = $dbh->prepare($query);
	$sth->execute($name, $folder, $firstURL, $nextPattern, $imgPattern, $indexURL, $desc);
}
