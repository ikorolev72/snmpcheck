#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin','/home/nems/client_persist/htdocs/bulktool3/html/cgi-bin', '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/' , '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/x86_64-linux-thread-multi/'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$sname="qosegress";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'qosegress.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );
$title="iPasolink QoS egress port set tool";

#$sname="clkread";
#$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
#$template = HTML::Template->new(filename => 'clkread.htm', die_on_bad_params=>0 );
#$template->param( SNAME=> $sname  );
#$title="Syncronization (clock) report tool";


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
		$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
		$template->param( TITLE=>$title );
		$template->param( MESSAGES=> $message );

		print "Content-type: text/html\n\n" ;
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


#SHOWFORM_EXPANDED

if( !$Param->{save_first} && !$Param->{save_second} ) {
		$template->param( SHOWFORM_EXPANDED=>0 );
		$template->param( SHOWFORM=>1 );
		$template->param( SHOWFORM_TO_TASK_=> 0 );
		$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
		$template->param( TITLE=> $title );
}

if( $Param->{save_first} ) {
	if( check_record()  ) {
		$template->param( SHOWFORM_EXPANDED=>1 );
		$template->param( SHOWFORM=>0 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
		$template->param( TITLE=> $title );
	} else{
		$template->param( SHOWFORM_EXPANDED=>0 );
		$template->param( SHOWFORM=>1 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
		$template->param( TITLE=> $title );
	}
}
if( $Param->{save_second} ) {
		$template->param( SHOWFORM_EXPANDED=>0 );
		$template->param( SHOWFORM=>0 );
		$template->param( SHOWFORM_TO_TASK=> 1 );
		$template->param( LOGIN=>$Param->{login} );
		$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
		$template->param( ACTION_TASK_ADD=>  $Url->{ACTION_TASK_ADD} );
		$template->param( TITLE=>"$title. Ready to add task" );
}


	my $grp=get_groups(  $Cfg->{iplistdb} );
	foreach $group ( sort keys( %{$grp} ) ) {
		my %row_data;   
		$row_data{ GROUP }=$group;
		$row_data{ GROUP_NAME }=$grp->{$group};		
		push(@loop_data, \%row_data);
	}
	$template->param(GROUP_LIST_LOOP => \@loop_data);	
	$template->param( DESC=> $Param->{desc} || "$sname task ".get_date() );
	$template->param( IP=> $Param->{ip} );
	$template->param( GROUP=> $Param->{group} );
	$template->param( SUBGROUP=> $Param->{subgroup} );
	$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );
	$template->param( INOP=> $Param->{inop} );
	$template->param( UCON=> $Param->{ucon} );
	$template->param( UMNG=> $Param->{umng} );

	
if( $Param->{Que_num}==1 ) {
	$template->param( QUE_TXT=> 4 );
}
if( $Param->{Que_num}==2 ) {
	$template->param( QUE_TXT=> 8 );
}	
$template->param( QUE_NUM=> $Param->{Que_num} );
$template->param( QUESET=> $Param->{queset} );
$template->param( MODEMPORT=> $Param->{modemport} );
$template->param( MODEMSET=> $Param->{modemset} );
$template->param( MODEMSCHEDULER=> $Param->{modemscheduler} );
$template->param( MODEMDROPMODE=> $Param->{modemdropmode} );
$template->param( MINTERPRIOALLOW=> $Param->{minterprioallow} );
$template->param( FAKENAME0=> $Param->{fakename0} );
$template->param( FAKENAME1=> $Param->{fakename1} );
$template->param( FAKENAME2=> $Param->{fakename2} );
$template->param( FAKENAME3=> $Param->{fakename3} );
$template->param( FAKENAME4=> $Param->{fakename4} );
$template->param( FAKENAME5=> $Param->{fakename5} );
$template->param( FAKENAME6=> $Param->{fakename6} );
$template->param( FAKENAME7=> $Param->{fakename7} );
$template->param( MODEMINTERNALPRI0=> $Param->{modeminternalpri0} );
$template->param( MODEMINTERNALPRI1=> $Param->{modeminternalpri1} );
$template->param( MODEMINTERNALPRI2=> $Param->{modeminternalpri2} );
$template->param( MODEMINTERNALPRI3=> $Param->{modeminternalpri3} );
$template->param( MODEMINTERNALPRI4=> $Param->{modeminternalpri4} );
$template->param( MODEMINTERNALPRI5=> $Param->{modeminternalpri5} );
$template->param( MODEMINTERNALPRI6=> $Param->{modeminternalpri6} );
$template->param( MODEMINTERNALPRI7=> $Param->{modeminternalpri7} );
$template->param( MDWRRALLOW=> $Param->{mdwrrallow} );
$template->param( MDWRR0=> $Param->{mdwrr0} );
$template->param( MQL0=> $Param->{mql0} );
$template->param( MQS0=> $Param->{mqs0} );
$template->param( MDWRR1=> $Param->{mdwrr1} );
$template->param( MQL1=> $Param->{mql1} );
$template->param( MQS1=> $Param->{mqs1} );
$template->param( MDWRR2=> $Param->{mdwrr2} );
$template->param( MQL2=> $Param->{mql2} );
$template->param( MQS2=> $Param->{mqs2} );
$template->param( MDWRR3=> $Param->{mdwrr3} );
$template->param( MQL3=> $Param->{mql3} );
$template->param( MQS3=> $Param->{mqs3} );
$template->param( MWTDALLOW=> $Param->{mwtdallow} );
$template->param( MWTDY0=> $Param->{mwtdy0} );
$template->param( MWREDG0=> $Param->{mwredg0} );
$template->param( MWREDY0=> $Param->{mwredy0} );
$template->param( MWTDY1=> $Param->{mwtdy1} );
$template->param( MWREDG1=> $Param->{mwredg1} );
$template->param( MWREDY1=> $Param->{mwredy1} );
$template->param( MWTDY2=> $Param->{mwtdy2} );
$template->param( MWREDG2=> $Param->{mwredg2} );
$template->param( MWREDY2=> $Param->{mwredy2} );
$template->param( MWTDY3=> $Param->{mwtdy3} );
$template->param( MWREDG3=> $Param->{mwredg3} );
$template->param( MWREDY3=> $Param->{mwredy3} );
$template->param( ETHERNETSET=> $Param->{ethernetset} );
$template->param( ETHERNETSCHEDULER=> $Param->{ethernetscheduler} );
$template->param( ESPS0=> $Param->{esps0} );
$template->param( ETHERNETDROPMODE=> $Param->{ethernetdropmode} );
$template->param( EINTERPRIOALLOW=> $Param->{einterprioallow} );
$template->param( FAKENAME0=> $Param->{fakename0} );
$template->param( FAKENAME1=> $Param->{fakename1} );
$template->param( FAKENAME2=> $Param->{fakename2} );
$template->param( FAKENAME3=> $Param->{fakename3} );
$template->param( FAKENAME4=> $Param->{fakename4} );
$template->param( FAKENAME5=> $Param->{fakename5} );
$template->param( FAKENAME6=> $Param->{fakename6} );
$template->param( FAKENAME7=> $Param->{fakename7} );
$template->param( ETHERNETINTERNALPRI0=> $Param->{ethernetinternalpri0} );
$template->param( ETHERNETINTERNALPRI1=> $Param->{ethernetinternalpri1} );
$template->param( ETHERNETINTERNALPRI2=> $Param->{ethernetinternalpri2} );
$template->param( ETHERNETINTERNALPRI3=> $Param->{ethernetinternalpri3} );
$template->param( ETHERNETINTERNALPRI4=> $Param->{ethernetinternalpri4} );
$template->param( ETHERNETINTERNALPRI5=> $Param->{ethernetinternalpri5} );
$template->param( ETHERNETINTERNALPRI6=> $Param->{ethernetinternalpri6} );
$template->param( ETHERNETINTERNALPRI7=> $Param->{ethernetinternalpri7} );
$template->param( EDWRRALLOW=> $Param->{edwrrallow} );
$template->param( EDWRR0=> $Param->{edwrr0} );
$template->param( EQL0=> $Param->{eql0} );
$template->param( EQS0=> $Param->{eqs0} );
$template->param( EDWRR1=> $Param->{edwrr1} );
$template->param( EQL1=> $Param->{eql1} );
$template->param( EQS1=> $Param->{eqs1} );
$template->param( EDWRR2=> $Param->{edwrr2} );
$template->param( EQL2=> $Param->{eql2} );
$template->param( EQS2=> $Param->{eqs2} );
$template->param( EDWRR3=> $Param->{edwrr3} );
$template->param( EQL3=> $Param->{eql3} );
$template->param( EQS3=> $Param->{eqs3} );
$template->param( EWTDALLOW=> $Param->{ewtdallow} );
$template->param( EWTDY0=> $Param->{ewtdy0} );
$template->param( EWREDG0=> $Param->{ewredg0} );
$template->param( EWREDY0=> $Param->{ewredy0} );
$template->param( EWTDY1=> $Param->{ewtdy1} );
$template->param( EWREDG1=> $Param->{ewredg1} );
$template->param( EWREDY1=> $Param->{ewredy1} );
$template->param( EWTDY2=> $Param->{ewtdy2} );
$template->param( EWREDG2=> $Param->{ewredg2} );
$template->param( EWREDY2=> $Param->{ewredy2} );
$template->param( EWTDY3=> $Param->{ewtdy3} );
$template->param( EWREDG3=> $Param->{ewredg3} );
$template->param( EWREDY3=> $Param->{ewredy3} );


	 

# print the template output
$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################



sub check_record {
	my $retval=1;
	unless( CheckField ( $Param->{Que_num} ,'int', "Field 'Number of queues' " )) {
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