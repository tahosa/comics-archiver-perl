#!/usr/bin/perl

# Using the LWP and DBI modules
use LWP::Simple;
use LWP::UserAgent;
use DBI;
use DBD::mysql;

#Database Handle information and setup
$host = ""; # Set to your mysql hostname
$db = ""; # Set to your mysql db name
$user = ""; # Set to your mysql db user
$pw = ""; # Set to your mysql db password

$dbh = DBI->connect("DBI:mysql:database=$db:host=$host", $user, $pw);

# Queries
$insertQuery = "INSERT INTO files (cName, number, filename) VALUES (?, ?, ?)";
$comicsQuery = "SELECT * FROM comics ORDER BY cName";
$singleComicQuery = "SELECT * FROM comics WHERE folder=?";
$duplicateCheckQuery = "SELECT filename FROM files WHERE cName=? AND filename=?";
$comicUpdateQuery = "UPDATE comics SET number=?, lastPage=?, updated=NOW() WHERE cName=?";

if($dbh eq undef) {	die "Could not open connection to database: ".$DBI::errstr."\n"; }

# User agent setup
$ua = LWP::UserAgent->new();

# Returns the URL to the next page given a starting URL and a regex search
# args are (string url, regex searchPattern)
sub getNext($$)
{
	# URL of page to search for link
	my $url = shift @_;
	# Regular expression to match html from $url to
	my $searchTerm = shift @_;
	# HTML of $url
	my $response = $ua->get($url);
	my $page = $response->content;
	
	#print "In GetNext - \$url: $url, search: $searchTerm\n";
	
	# Look for a link containing the searchterm in between the <a> tags
	if($page =~ /<a[^>]+?href\s*=\s*[\"\']([^\"\']+?)[\"\'].*$searchTerm.*?<\/a>/is)
	{
		#print "GetNext - first search: $1\nMatch was: $&\n";
		# Store the url result so future matches work
		my $fs = $1;
		
		# Check to see if it is a fully qualified (non-relative) url, if so, return it
		if($fs =~ /^http:/)
		{
			return $fs;
		}
		
		# See if it starts with at /
		elsif($fs =~ m%^/%)
		{
			#If it does, strip down $url to the base and concatenate
			my $first = $fs;
			$url =~ m%(http://[^/]*)%;
			return $1 . $first;
		}
		# Otherwise strip $url to the last / and concatenate
		else
		{
			my $first = $fs;
			$url =~ m%(http://.*)/.*$%;
			return "$1/$first";
		}
	}
}

# If the comics need to be renumberd, this is the tracking variable
my $num = 1;

# Downloads a file based on a passed in regex search
# args are (string url, regex searchPattern, string saveFolder, string comicName, int number)
sub Download($$$$$)
{
	# URL of page to search for comics to download
	my $url = shift @_;
	# Regex search pattern for comics
	my $search = shift @_;
	# What folder to save the comics into
	my $save = shift @_;
	my $name = shift @_;
	# Number to save in the db as
	my $num = shift @_;

	# Get HTML of $url to search
	my $r1 = $ua->get($url);
	my $page = $r1->content;
	# Search for results and store them
	my @results = $page =~/$search/g;
	
	# Check to make sure there are no duplicates on the page
	my $prev;
	my $dl = 0;
	# Iterate through results and save them
	foreach (@results)
	{
		# Skip if it is an icon file
		next if /.ico$/;
		#print "in download matches - \$_: $_\n";
		
		# Check if the comic is unique
		if($_ ne $prev)
		{
			# Set break
			$prev = $_;
			# URL of comic to download
			my $dlurl;
			# If the URL is fully qualified (non-relative) set it to $dlurl
			if(/^http:/) { $dlurl = $_; }
			
			# If it starts with / capture all chars but the first /
			elsif (m%^/([^/]+)%)
			{
				# Strip URL to the base domain with a trailing /, eg http://example.com/
				# and concat with first match
				$url =~ m%^(http://[^/]+)/.*%;
				$dlurl = $1 . $_;
			}
			# Else, strip $url to the last / and concat with the search url
			else
			{
				my $save = $1;
				$url =~ m%^(http://.*/)[^/]*$%;
				$dlurl = $1 . $_;
			}
			
			# Get the filename to save it as
			m%/?([^/]+)$%;
			my $saveNm;
			
			# Check to see if on Windows and set the folder deliniator
			if ($^O eq "MSWin32"){ $saveNm = $save ."\\". $1; }
			else { $saveNm = $save . "/" . $1; }
			
			# Check for duplicates in the database and skip if the entry exists
			my $sth = $dbh->prepare($duplicateCheckQuery);
			$sth->execute($name, $1);
			@res = $sth->fetchrow_array;
			if(@res > 0) { next; }
			
			# If there is no duplicate, save the comic and insert it into the database
			#print "url: $dlurl, name: $saveNm\n";
			getstore($dlurl, $saveNm);
			$sth = $dbh->prepare($insertQuery);
			$sth->execute($name, $num + $dl, $1);
			$dl += 1;
		}
	}
	
	return $dl;
}

#Cycle through the archive starting at the URL passed in
# arguments are (string starting url, string indexURL, string next search pattern, string image search pattern, string comic name, string folder, int starting number)
sub TrawlArchive($$$$$$$)
{
	#print "@_\n";
	# read in from the arguments
	my $start = shift @_;
	my $indexURL = shift @_;
	my $nextPattern = shift @_;
	my $imgPattern = shift @_;
	my $name = shift @_;
	my $folder = shift @_;
	my $num = shift @_;
	
	# Set current to first as passed in
	my $currentURL = $start;
	# Last URL searched - will be searched again when script is rerun
	my $last;
	
	# Get the next URL to check
	my $nextURL = getNext($currentURL, $nextPattern);
	# print "trawl lead in - current: $currentURL, next: $nextURL, nextsearch: $nextPattern\n";
	$flag = 0;
	
	# Trawl the archives while current is not equal to next
	while(($currentURL ne $nextURL || $flag == 0) and not $currentURL =~ /#$/ and $currentURL ne NULL and $currentURL ne "")
	{	
		if($currentURL eq $nextURL or $last eq $indexURL) { $flag = 1; }
		#print "in trawl loop - current: $currentURL, next: $nextURL, nextsearch: $nextPattern\n";
		# Download from the current page
		my $dlRes = &Download($currentURL, $imgPattern, $folder, $name, $num+1);
		
		# Reset last, current and next and increment count
		$last = $currentURL;
		$currentURL = $nextURL;
		$nextURL = getNext($currentURL, $nextPattern);
		$num += $dlRes;
		
		#print "in trawl loop - settings for next: $currentURL, $nextURL, $last\n";
	}
	
	# Update the comics table with the latest number and download time
	my $update = $dbh->prepare($comicUpdateQuery);
	$update->execute($num, $last, $name);
}

# Tracking variable for comic query
$comicInfo;

# If no particular comic was specified, do all of them, otherwise only do the specified folder
if(@ARGV == 0)
{
	$comicInfo = $dbh->prepare($comicsQuery);
	$comicInfo->execute();
}
elsif(@ARGV == 1 and not $ARGV[0] =~ /^-/)
{
	$comicInfo = $dbh->prepare($singleComicQuery);
	$comicInfo->execute($ARGV[0]);
}
else
{
	print "Usage: download.pl [folder]\n";
	exit(0);
}

# iterate through the query results
while (my @row = $comicInfo->fetchrow_array)
{
	# Skip download if the comics is completed.
	next if($row[10] > 0);
	
	# Initialize values from query
	my $name = $row[0];
	my $folder = $row[2];
	my $indexURL = $row[8];
	my $firstURL = $row[5];
	my $nextPattern = $row[6];
	my $imgPattern = $row[7];
	my $lastDL = $row[3];
	my $lastURL = $row[4];
	my $num = $row[1];
	
	# if the folder doesn't exist, create it
	mkdir $folder, 0711 if(not -e -d $folder);
	
	# Start from the beginning if there are no comics, or the current position if there are
	if($num == 0)
	{
		print "Comics for $name not downloaded before.\n";
		TrawlArchive($firstURL, $indexURL, $nextPattern, $imgPattern, $name, $folder, $num);
	}
	else
	{
		TrawlArchive($lastURL, $indexURL, $nextPattern, $imgPattern, $name, $folder, $num);
	}
	
	opendir($dh, $folder) or die "Could not open folder $folder: $!\n";
	chmod 644, grep(/^[^\.]/, readdir($dh));
}
