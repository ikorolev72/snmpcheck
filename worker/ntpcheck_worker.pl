#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;

use Getopt::Long;

GetOptions (
        'task=i' => \$id,
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

foreach( 0..9 )  {
	WriteFile("C:/GIT/tmp/$_.txt", Dumper( $Param ) );  
	sleep 20;
}

  
  
  
sub show_help {
print STDOUT "Usage: $0 --id=TASK_ID --json=JSON_PARAMETERS_FILE [ --help ]
Sample:
$0 --id=12345 --json=/dir1/dir2/12345.param.json
";
}