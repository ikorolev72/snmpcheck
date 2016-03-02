#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;

use Getopt::Long;

GetOptions (
        'sname=s' => \$sname,
        'desc=s' => \$desc,
        'ip=s' => \$ip,
        "time=i" => \$time,
        "output=s" => \$output,
        "param=s" => \@Param,
        "help|h|?"  => \$help ) or show_help();

		
		
if($help) {
	show_help() ;
	exit 0;
}

$dbh=db_connect() ;

unless( check_arguments() ) {
	$MSG=~s/\<br\>/\n/g;
	w2log( "Cannot add task. Incorrect arguments $0:\n $MSG\n" )  ;
	exit 1;
}

my $row;
$row->{ sname } =$sname;
$row->{ desc } =$desc;
$row->{ desc } =$desc;

sub InsertRecord {
	my $dbh=shift;
	my $id=shift; # do not used
	my $table=shift;
	my $row=shift;




db_disconnect( $dbh );


sub show_help {
print STDOUT "Usage: $0 --sname=NAME --ip='IP,IP...' --time=TIME --output='OUTPUT_FILE' [ --desc='DESCRIPTION' ] [ --param='PARAM=SOMETING' ... ]
# * sname - worker from table snmpworker ( --sname=ntpcheck ) 
#   desc - description of task ( --desc='NTP check task' )
# * ip - list of ip joined by ',' ( --ip='1.1.1.1,2.2.2.2,3.3.3.3' )
#   time - zero if you will start task immediatly, or time when you will start task. now only 0  ( --time=0 )
# * output - output report file  in $Paths->{OUTPUT} directory ( --output=ntpcheck_20160303.csv )
#   param - addiditional parameters ( --param='color=red' --param='dname=blabla' )
Sample:
$0 --sname=ntpcheck  --desc='NTP check task'  --ip='1.1.1.1,2.2.2.2,3.3.3.3' --time=0 --output=ntpcheck_20160303.csv --param='color=red' 
";
}


sub check_arguments {
	$retval=1;
	unless( CheckField ( $desc ,'text', "Fields 'desc' ") ){
			$retval=0 ;
	}	
	unless( CheckField ( $sname ,'login', "Fields 'sname' ") ){
			$retval=0 ;
	} else {
		my $table='snmpworker';
		my $row=GetRecordByField ( $dbh,  $table, 'sname', $sname );
		unless( $row ) {
				message2( "Not found worker with name $sname" );			
				$retval=0 ;
		}		
	}
	foreach ( split(/,/, $ip ) ) {
		unless( CheckField ( $_ ,'ip', "option 'ip' ") ){
			$retval=0 ;
		}
	}
	unless( CheckField ( $output ,'filename', "option 'output' ") ){
		$retval=0 ;
	}
	return $retval;
}
	


