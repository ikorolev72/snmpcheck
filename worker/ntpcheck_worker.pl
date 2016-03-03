#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;

use Getopt::Long;


GetOptions (
        'id=i' => \$id,
        'json=s' => \$json_file,
        "help|h|?"  => \$help ) or show_help();


		
unless( $id ) {
	show_help();
	exit 1;
}

unless( -f $json_file ) {
	show_help();
	exit 1;
}


  local $/;
  open( my $fh, '<', $json_file );
  my $json_text   = <$fh>;
  $Param = decode_json( $json_text );

  
my $json_out="$Paths->{JSON}/$id.out.json";
my $row;
my $timenow=time();
$count_max=9;
foreach $count ( 0..$count_max )  {
	if( time() - $timenow  > 10 ) {
		$timenow=time();
		$row->{dt}=time();
		$row->{status}=3; # running
		$row->{id}=$id;
		$row->{mess}='All ok';
		$row->{progress}=int( $count*100/$count_max ) ;
		unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
				w2log ("Cannot write file $json_file: $!");
		}
	}
	sleep 5;
	$|=1;
	print $count;
}

$timenow=time();
$row->{dt}=time();
$row->{status}=4; # finished
$row->{id}=$id;
$row->{mess}='Finished successfully';
$row->{progress}=100 ;
unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
		w2log ("Cannot write file $json_file: $!");
}

exit 0;
 
  
  
sub show_help {
print STDOUT "Usage: $0 --id=TASK_ID --json=JSON_PARAMETERS_FILE [ --help ]
Sample:
$0 --id=12345 --json=/dir1/dir2/12345.param.json
";
}