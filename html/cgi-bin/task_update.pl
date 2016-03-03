#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;

use Getopt::Long;


GetOptions (
        'json=s' => \$json_text,
        "help|h|?"  => \$help ) or show_help();



unless(  $json ) {
	show_help();
	exit 1;
}



$dbh=db_connect() ;

update_status( $dbh, $json_text );

db_disconnect( $dbh );


  

exit 0;
 


sub update_status {
	my $dbh=shift;
	my $json_text=shift;
	my $table='tasks';			
	my $row = decode_json( $json_text );	
	UpdateRecord ( $dbh, $row->{id}, $table, $row ) ;				
	return 1;
}


 
  
sub show_help {
print STDOUT "Usage: $0  --json='JSON_PARAMETERS' [ --help ]
Sample:
$0  --json='{\"progress\":100,\"status\":4,\"dt\":1457033722,\"mess\":\"Finished successfully\",\"id\":\"39\"}'
";
}