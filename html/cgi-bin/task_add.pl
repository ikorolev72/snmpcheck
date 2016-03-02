#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;
use HTML::Template;
use DBI;
use CGI::Carp qw ( fatalsToBrowser );
use CGI qw(param);
use Digest::SHA qw(sha1 sha1_hex );
#use Data::Dumper;

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'task_add.htm', die_on_bad_params=>0 );




$dbh=db_connect() ;


if(  Action() ==0 ) {
	$show_form=1;
	$template->param( SHOWFORM=>1 );
	$template->param( TITLE=>"Add the task" );
	$template->param( IP=> $Param->{ip} );
	$template->param( GROUP=> $Param->{group} );
	$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );
	
} else {
	message2( "Task '$param0>{desc}' added. Please, check it in <a href='/cgi-bin/task_list.pl'> Task list </a>" ) ;
	$template->param( SHOWFORM=> 0 );
	$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
	$template->param( ACTION_TASK_ADD=>  "/cgi-bin/task_add.pl" );
	$template->param( TITLE=>"Task added" );
	$template->param( MESSAGES=> $message );
}

$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( MESSAGES=> $message );

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
	unless( CheckField ( $Param->{desc} ,'text', "Fields 'desc' ") ){
			$retval=0 ;
	}	
	unless( CheckField ( $Param->{sname} ,'login', "Fields 'sname' ") ){
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
	


