# !/usr/bin/perl -w

#This script gets the user stats about using internet trafic from MySQL Database and send report to this user if a trafic volume is over 90% of limit.

use DBD::mysql;
use DBI;
use Net::SMTP;
use MIME::Lite;
use MIME::Base64;
use DateTime;

my $host = "localhost";
my $database = "squidctrl";
my $tablename = "squidusers";
my $user = "root";
my $pw = "password";

$dt = DateTime -> now -> set_time_zone('Asia/Novosibirsk');
$day = $dt -> day;
$hour = $dt -> hour;
$minute = $dt -> minute;

$filename = "/usr/scripts/sendMessage/alreadySent.txt";

if($day == 1 && $hour == 0 && $minute == 0){
	unlink('alreadySent.txt');
}

open(FILE, $filename);
@lines = <FILE>;
close(FILE);


$alreadySent = 0;

my $connect = DBI->connect("DBI:mysql:$database;host=$host",$user,$pw) || die "Could not connect to database";
my $query = $connect -> prepare("SELECT nick,quotes,size,hit,name,soname FROM squidctrl.squidusers") || die "$DBI::errstr";
$query->execute();

open(FILE, '>>' . $filename);

while(my $result = $query->fetchrow_hashref)
{
$usernick = $result->{nick};
$quota = $result->{quotes};
$name = $result->{name};
$soname = $result->{soname};
my $size = $result->{size};
my $hit = $result->{hit};
$sizeMB = int(($size/1048576)-($hit/1048576));
$left = $quota - $sizeMB;
$userAddress = $usernick . "\@ntzmk.ru";


foreach $item(@lines){
    if($item =~ $usernick){
    $alreadySent = 1;
    last;
    }
    else{
    $alreadySent = 0;
    }
}

if($quota>0 && $sizeMB>0 && $left>0)
{    
	if(($sizeMB/$quota)>0.9)
	{
#	print "$usernick $quota $sizeMB $userAddress $alreadySent\n";
		if($alreadySent == 0){
		 &send;
				    }
	}
}
}

    
sub send {
	
	my $msg = MIME::Lite -> new(
	From	=>	'monitoring@somedomain.ru',
	To	=>	$userAddress,

	Type	=>	'multipart/related',
	Encoding	=>	'8bit',
	Subject	=>	'Статистика работы в Интернет'
	);
	$msg -> attach(
			Type	=>	'text/html',
			Data	=>	qq{<html><body><H3>$name $soname Вы использовали более 90% выделенного вам трафика.</H3> Использовано: $sizeMB мегабайт, лимит: $quota мегабайт.<br>Подробную информацию об использовании Интернет вы можете посмотреть на <a href=http://gw.ntzmk.ru>сайте статистики</a></body></html>},);
	$msg->send('smtp','192.168.4.1');
	
	print FILE $usernick . "\n";
		}
close (FILE);
