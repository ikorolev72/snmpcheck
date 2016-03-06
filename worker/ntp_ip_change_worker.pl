#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;

use Getopt::Long;



GetOptions (
        'json=s' => \$json_file,
        "help|h|?"  => \$help ) or show_help();



unless( -f $json_file ) {
	show_help();
	exit 1;
}


$json_text=ReadFile( $json_file );

$Param =JSON->new->utf8->decode($json_text);

my $json_out="$Paths->{JSON}/$Param->{id}.out.json";
my $row;
my $timenow=time();
$count_max=9;
foreach $count ( 0..$count_max )  {
	if( time() - $timenow  > 15 ) {
		$timenow=time();
		$row->{sdt}=time();
		$row->{status}=3; # running
		$row->{id}=$Param->{id};
		$row->{mess}='Task running. All ok.';
		$row->{progress}=int( $count*100/$count_max ) ;
		unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
				w2log ("Cannot write file $json_file: $!");
		}
	}
	sleep 10;
	$|=1;
	print $count;
}

$row->{sdt}=time();
$row->{status}=4; # finished
$row->{id}=$Param->{id};
$row->{mess}='Finished successfully';
$row->{progress}=100 ;

unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
	w2log ("Cannot write file $json_file: $!");
}

exit 0;
 
  
  
sub show_help {
print STDOUT "Usage: $0  --json='JSON_FILE' [ --help ]
Sample:
$0  --json='/tmp/123.json'
";
}