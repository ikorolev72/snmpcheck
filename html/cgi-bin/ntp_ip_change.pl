#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$sname="ntp_ip_change";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'ntp_ip_change.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );



$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

my $dbh, $stmt, $sth, $rv;
$message='';

$title="iPasolink NTP server IP change";

$template->param( AUTHORISED=>1 );
unless (  require_authorisation( 1, 0 ) ) { # we require any authorised user
	message2( "Only authorised user can add this task" );
	$template->param( AUTHORISED=>0 );
	$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
	$template->param( TITLE=>$title );
	$template->param( MESSAGES=> $message );

	print "Content-type: text/html\n\n" ;
	print  $template->output;
exit 0;
}




$dbh=db_connect() ;

my $show_form=1;
my $table='users';


$Param->{all_ipasolink}=$Param->{all_ipasolink}?1:0;
$Param->{subgroup}=$Param->{subgroup}?1:0;

if(  Action() ==0 ) {
	$show_form=1;
	$template->param( SHOWFORM=>1 );
	$template->param( SHOWFORM_TO_TASK_=> 0 );
	$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
	$template->param( TITLE=> $title );
} else {
	$template->param( SHOWFORM=> 0 );
	$template->param( SHOWFORM_TO_TASK => 1 );
	$template->param( LOGIN=>$Param->{login} );
	$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
	$template->param( ACTION_TASK_ADD=>  "/cgi-bin/task_add.pl" );
	$template->param( TITLE=>"$title. Ready to add task" );
}


$template->param( DESC=> $Param->{desc} || "$sname task ".get_date() );
$template->param( IP=> $Param->{ip} );
$template->param( GROUP=> $Param->{group} );
$template->param( SUBGROUP=> $Param->{subgroup} );
$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );

$template->param( NTP1=> $Param->{ntp1} );
$template->param( NTP2=> $Param->{ntp2} );
$template->param( NTP3=> $Param->{ntp3} );
$template->param( NTP4=> $Param->{ntp4} );
$template->param( NTP1_POOL=> $Param->{ntp1_poll} );
$template->param( NTP2_POOL=> $Param->{ntp2_poll} );
$template->param( NTP3_POOL=> $Param->{ntp3_poll} );
$template->param( NTP4_POOL=> $Param->{ntp4_poll} );




foreach $group ( get_groups() ) {
	my %row_data;   
	$row_data{ GROUP }=$group;
	push(@loop_data, \%row_data);
}
$template->param(GROUP_LIST_LOOP => \@loop_data);
	 

# print the template output
$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	if( $Param->{save} ) {
		return( check_record()  );
	}	
return 0;
}



sub check_record {
	my $retval=1;
	unless( CheckField ( $Param->{ntp1} ,'ip', "Field 'NTP server1 IP address' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp2} ,'ip_op_empty', "Field 'NTP server2 IP address' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp3} ,'ip_op_empty', "Field 'NTP server3 IP address' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp4} ,'ip_op_empty', "Field 'NTP server4 IP address' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp1_poll} ,'int', "Field 'NTP server1 polling time' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp2_poll} ,'int', "Field 'NTP server2 polling time' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp3_poll} ,'int', "Field 'NTP server3 polling time' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{ntp4_poll} ,'int', "Field 'NTP server4 polling time' " )) {
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
	unless( CheckField ( $Param->{desc} ,'desc', "Field 'Description' ") ){
		$retval=0;
	}
	if( !$Param->{ip} && !$Param->{group} && !$Param->{all_ipasolink} ) {
		message2( "Must be set 'ip address' or 'group' or 'IP list for all iPasolink'" );
		$retval=0;
	}
	return $retval;
}