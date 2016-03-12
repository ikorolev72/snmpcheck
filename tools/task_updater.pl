#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin','/home/nems/client_persist/htdocs/bulktool3/html/cgi-bin', '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/' , '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/x86_64-linux-thread-multi/'; } 
use COMMON_ENV;
use File::Basename;
use Getopt::Long;


GetOptions ( "help|h|?"  => \$help );
if( $help ) {
	show_help();
	exit 1;
}


######## check if there do not finished porcess
my $basename=basename($0);
my $pid_file="$Paths->{PID_DIR}/$basename.pid";
my $process_timeout=600;
if( -f $pid_file ) {
	my ($pid,$pid_dt)=split( ',',ReadFile( $pid_file ));
	$pid=~s/\s//gm;
	# check if previrous process do not finished yet
	my $cmd="ps -p $pid -o comm= | grep $basename";
	if( 0==system($cmd) ) {
		w2log( "Previrous $0 process do not finished yet" );
			if( $pid_dt+$timeout < time() ){
				# try to kill the timeouted process
				if( kill('-KILL', $pid ) ) {
					w2log( "Kill the process $basename with pid $pis by timeout reasone" );					
					unlink ( $pid_file );
				} else {
					w2log( "Cannot to kill the process $basename with pid $pis by timeout reasone." );
					exit (1);
				}
			}
		exit 0;
	}
	# we do not found the process. the pid may be do not removed by any reasones
	# we will go 
}





		
		
$dbh=db_connect() ;

update_tasks( $dbh );

db_disconnect( $dbh );

exit 0;


  
sub show_help {
print STDOUT "Task status updater. Can be start from command line or from cron
Usage: $0 [ --help ]
";
}