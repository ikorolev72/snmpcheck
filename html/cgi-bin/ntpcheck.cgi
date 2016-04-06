#!/usr/bin/perl
# korolev-ia [at] yandex.ru
# version 1.0 2016.03.18
use lib "C:\GIT\snmpcheck\lib" ;
use lib "/opt/snmpcheck/lib" ;
use lib "../lib" ;
use lib "../../lib" ;

print "Content-type: text/html

" ;


use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$sname="ntpcheck";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'ntpcheck.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );
$title="iPasolink NTP status check tool";


$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

my $dbh, $stmt, $sth, $rv;
$message='';

my $Cfg=ReadConfig();
if( $Cfg->{iplistdb} eq 'ms5000' ) {
	$template->param( MS5000=>1 );
}

$template->param( AUTHORISED=>1 );
if(  grep {/^$sname$/ } split( /,/, $Cfg->{approved_application_for_authentication} ) ) {
	unless (  require_authorisation()  ) { # we require any authorised user
		message2( "Only authorised user can add this task" );
		$template->param( AUTHORISED=>0 );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME} );
		$template->param( TITLE=>$title );
		$template->param( MESSAGES=> $message );

		print  $template->output;
	exit 0;
 }
}


$dbh=db_connect() ;

my $show_form=1;


$Param->{all_ipasolink}=$Param->{all_ipasolink}?1:0;
$Param->{subgroup}=$Param->{subgroup}?1:0;
$Param->{inop}=$Param->{inop}?1:0;
$Param->{ucon}=$Param->{ucon}?1:0;
$Param->{umng}=$Param->{umng}?1:0;


$template->param( SHOWFORM_FIRST=> 1 );
$template->param( SHOWFORM_SECOND=> 0 );
$template->param( SHOWFORM_TO_TASK=> 0 );


if( $Param->{save_first} ) {
	if( check_record()  ) {
		$template->param( SHOWFORM_FIRST=> 0 );
		$template->param( SHOWFORM_SECOND=> 1 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME} );
		$template->param( TITLE=> $title );
		$template->param( DESC=> "$sname task " ) ; 	# .get_date() );
			if( 1 == $Param->{task_start_type} ) {
				$template->param( DESC=> "$sname crontab task " )
			}		
#message2( "<pre>".Dumper($Param)."</pre>");		
	} else{
		$template->param( SHOWFORM_EXPANDED=>0 );
		$template->param( SHOWFORM=>1 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME} );
		$template->param( TITLE=> $title );
	}
}

if( $Param->{save_second} ) {
	if( check_record2()  ) {
		$template->param( SHOWFORM_FIRST=> 0 );
		$template->param( SHOWFORM_SECOND=> 0 );
		$template->param( SHOWFORM_TO_TASK=> 1 );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME}  );
		$template->param( ACTION_TASK_ADD =>  $Url->{ACTION_TASK_ADD} );
		$template->param( TITLE=>"$title. Ready to add task" );
		
		if( 1 == $Param->{task_start_type} ) {
			$template->param( ACTION_TASK_ADD =>  $Url->{ACTION_TASK_ADD_CRONTAB} );
			$template->param( DESC=> $Param->{desc} );
		} else {
			$template->param( DESC=> $Param->{desc}.get_date() );
		}
		
	} else {
		$template->param( DESC=> $Param->{desc} );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME}  );	
		$template->param( ACTION_TASK_ADD=>  $Url->{ACTION_TASK_ADD}  );	
		$template->param( SHOWFORM_FIRST=> 0 );
		$template->param( SHOWFORM_SECOND=> 1 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
	}
}





	my $grp=get_groups(  $Cfg->{iplistdb} );
	foreach $group ( sort keys( %{$grp} ) ) {
		my %row_data;   
		$row_data{ GROUP }=$group;
		$row_data{ GROUP_NAME }=$grp->{$group};		
		push(@loop_data, \%row_data);
	}
	$template->param(GROUP_LIST_LOOP => \@loop_data);	
	$template->param( IP=> $Param->{ip} );
	$template->param( GROUP=> $Param->{group} );
	$template->param( SUBGROUP=> $Param->{subgroup} );
	$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );
	$template->param( INOP=> $Param->{inop} );
	$template->param( UCON=> $Param->{ucon} );
	$template->param( UMNG=> $Param->{umng} );
	$template->param( WORKER_THREADS=> $Param->{worker_threads} );
	$template->param( TASK_START_TYPE=> $Param->{task_start_type} );
	$template->param( TASK_START_TYPE_CRON=>1 ) if( 1 == $Param->{task_start_type} ) ;
	$template->param( CRON=> $Param->{cron} );

	 

# print the template output
$template->param( MESSAGES=> $message );
print  $template->output;

 
db_disconnect( $dbh );

##############################################




sub check_record {
	my $retval=1;
	if( 1 == $Param->{task_start_type} && !require_authorisation() ) { 
			message2( "Only authorised user can add crontab task" );
			$retval=0;
	}	
	unless( CheckField ( $Param->{ip} ,'ip_op_empty', "Field 'ip' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{group} ,'text', "Field 'group' ") ){
		$retval=0;
	}
	unless( CheckField ( $Param->{all_ipasolink} ,'boolean', "Field 'IP list for all iPasolink' ") ){
		$retval=0;
	}
#	unless( CheckField ( $Param->{desc} ,'desc', "Field 'Description' ") ){
#		$retval=0;
#	}
	if( !$Param->{ip} && !$Param->{group} && !$Param->{all_ipasolink} ) {
		message2( "Must be set 'ip address' or 'group' or 'IP list for all iPasolink'" );
		$retval=0;
	}
	return $retval;
}

sub check_record2 {
	my $retval=1;
	if( 1 == $Param->{task_start_type} && !require_authorisation() ) { 
			message2( "Only authorised user can add crontab task" );
			$retval=0;
	}
	unless( CheckField ( $Param->{desc} ,'desc', "Field 'Description' ") ){
		$retval=0;
	}
	unless( CheckField ( $Param->{cron} ,'cron', "Field 'Crontab' ") ){
		$retval=0;
	}
	return $retval;
}