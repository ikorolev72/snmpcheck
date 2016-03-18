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




$sname="qosequip";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'qosequip.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );
$title="iPasolink QoS set tool (equipment mode)";

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

		print  $template->output;
	exit 0;
 }
}


$dbh=db_connect() ;



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
$template->param( PROFNUM=> $Param->{profnum} );
$template->param( PROSELECT=> $Param->{proselect} );
$template->param( DELPRO=> $Param->{delpro} );
$template->param( ACTPRO=> $Param->{actpro} );
$template->param( ENT1CF=> $Param->{ent1cf} );
$template->param( ENT1CP=> $Param->{ent1cp} );
$template->param( ENT1CIP=> $Param->{ent1cip} );
$template->param( ENT2CF=> $Param->{ent2cf} );
$template->param( ENT2CP=> $Param->{ent2cp} );
$template->param( ENT2CIP=> $Param->{ent2cip} );
$template->param( ENT3CF=> $Param->{ent3cf} );
$template->param( ENT3CP=> $Param->{ent3cp} );
$template->param( ENT3CIP=> $Param->{ent3cip} );
$template->param( ENT4CF=> $Param->{ent4cf} );
$template->param( ENT4CP=> $Param->{ent4cp} );
$template->param( ENT4CIP=> $Param->{ent4cip} );
$template->param( ENT5CF=> $Param->{ent5cf} );
$template->param( ENT5CP=> $Param->{ent5cp} );
$template->param( ENT5CIP=> $Param->{ent5cip} );
$template->param( ENT6CF=> $Param->{ent6cf} );
$template->param( ENT6CP=> $Param->{ent6cp} );
$template->param( ENT6CIP=> $Param->{ent6cip} );
$template->param( ENT7CF=> $Param->{ent7cf} );
$template->param( ENT7CP=> $Param->{ent7cp} );
$template->param( ENT7CIP=> $Param->{ent7cip} );
$template->param( ENT8CF=> $Param->{ent8cf} );
$template->param( ENT8CP=> $Param->{ent8cp} );
$template->param( ENT8CIP=> $Param->{ent8cip} );
$template->param( ENT9CF=> $Param->{ent9cf} );
$template->param( ENT9CP=> $Param->{ent9cp} );
$template->param( ENT9CIP=> $Param->{ent9cip} );
$template->param( ENT10CF=> $Param->{ent10cf} );
$template->param( ENT10CP=> $Param->{ent10cp} );
$template->param( ENT10CIP=> $Param->{ent10cip} );
$template->param( ENT11CF=> $Param->{ent11cf} );
$template->param( ENT11CP=> $Param->{ent11cp} );
$template->param( ENT11CIP=> $Param->{ent11cip} );
$template->param( ENT12CF=> $Param->{ent12cf} );
$template->param( ENT12CP=> $Param->{ent12cp} );
$template->param( ENT12CIP=> $Param->{ent12cip} );
$template->param( ENT13CF=> $Param->{ent13cf} );
$template->param( ENT13CP=> $Param->{ent13cp} );
$template->param( ENT13CIP=> $Param->{ent13cip} );
$template->param( ENT14CF=> $Param->{ent14cf} );
$template->param( ENT14CP=> $Param->{ent14cp} );
$template->param( ENT14CIP=> $Param->{ent14cip} );
$template->param( ENT15CF=> $Param->{ent15cf} );
$template->param( ENT15CP=> $Param->{ent15cp} );
$template->param( ENT15CIP=> $Param->{ent15cip} );
$template->param( ENT16CF=> $Param->{ent16cf} );
$template->param( ENT16CP=> $Param->{ent16cp} );
$template->param( ENT16CIP=> $Param->{ent16cip} );
$template->param( ENT17CF=> $Param->{ent17cf} );
$template->param( ENT17CP=> $Param->{ent17cp} );
$template->param( ENT17CIP=> $Param->{ent17cip} );
$template->param( ENT18CF=> $Param->{ent18cf} );
$template->param( ENT18CP=> $Param->{ent18cp} );
$template->param( ENT18CIP=> $Param->{ent18cip} );
$template->param( ENT19CF=> $Param->{ent19cf} );
$template->param( ENT19CP=> $Param->{ent19cp} );
$template->param( ENT19CIP=> $Param->{ent19cip} );
$template->param( ENT20CF=> $Param->{ent20cf} );
$template->param( ENT20CP=> $Param->{ent20cp} );
$template->param( ENT20CIP=> $Param->{ent20cip} );
$template->param( ENT21CF=> $Param->{ent21cf} );
$template->param( ENT21CP=> $Param->{ent21cp} );
$template->param( ENT21CIP=> $Param->{ent21cip} );
$template->param( ENT22CF=> $Param->{ent22cf} );
$template->param( ENT22CP=> $Param->{ent22cp} );
$template->param( ENT22CIP=> $Param->{ent22cip} );
$template->param( ENT23CF=> $Param->{ent23cf} );
$template->param( ENT23CP=> $Param->{ent23cp} );
$template->param( ENT23CIP=> $Param->{ent23cip} );
$template->param( ENT24CF=> $Param->{ent24cf} );
$template->param( ENT24CP=> $Param->{ent24cp} );
$template->param( ENT24CIP=> $Param->{ent24cip} );
$template->param( ENT25CF=> $Param->{ent25cf} );
$template->param( ENT25CP=> $Param->{ent25cp} );
$template->param( ENT25CIP=> $Param->{ent25cip} );
$template->param( ENT26CF=> $Param->{ent26cf} );
$template->param( ENT26CP=> $Param->{ent26cp} );
$template->param( ENT26CIP=> $Param->{ent26cip} );
$template->param( ENT27CF=> $Param->{ent27cf} );
$template->param( ENT27CP=> $Param->{ent27cp} );
$template->param( ENT27CIP=> $Param->{ent27cip} );
$template->param( ENT28CF=> $Param->{ent28cf} );
$template->param( ENT28CP=> $Param->{ent28cp} );
$template->param( ENT28CIP=> $Param->{ent28cip} );
$template->param( ENT29CF=> $Param->{ent29cf} );
$template->param( ENT29CP=> $Param->{ent29cp} );
$template->param( ENT29CIP=> $Param->{ent29cip} );
$template->param( ENT30CF=> $Param->{ent30cf} );
$template->param( ENT30CP=> $Param->{ent30cp} );
$template->param( ENT30CIP=> $Param->{ent30cip} );
$template->param( ENT31CF=> $Param->{ent31cf} );
$template->param( ENT31CP=> $Param->{ent31cp} );
$template->param( ENT31CIP=> $Param->{ent31cip} );
$template->param( ENT32CF=> $Param->{ent32cf} );
$template->param( ENT32CP=> $Param->{ent32cp} );
$template->param( ENT32CIP=> $Param->{ent32cip} );
$template->param( ENT33CF=> $Param->{ent33cf} );
$template->param( ENT33CP=> $Param->{ent33cp} );
$template->param( ENT33CIP=> $Param->{ent33cip} );
$template->param( ENT34CF=> $Param->{ent34cf} );
$template->param( ENT34CP=> $Param->{ent34cp} );
$template->param( ENT34CIP=> $Param->{ent34cip} );
$template->param( ENT35CF=> $Param->{ent35cf} );
$template->param( ENT35CP=> $Param->{ent35cp} );
$template->param( ENT35CIP=> $Param->{ent35cip} );
$template->param( ENT36CF=> $Param->{ent36cf} );
$template->param( ENT36CP=> $Param->{ent36cp} );
$template->param( ENT36CIP=> $Param->{ent36cip} );
$template->param( ENT37CF=> $Param->{ent37cf} );
$template->param( ENT37CP=> $Param->{ent37cp} );
$template->param( ENT37CIP=> $Param->{ent37cip} );
$template->param( ENT38CF=> $Param->{ent38cf} );
$template->param( ENT38CP=> $Param->{ent38cp} );
$template->param( ENT38CIP=> $Param->{ent38cip} );
$template->param( ENT39CF=> $Param->{ent39cf} );
$template->param( ENT39CP=> $Param->{ent39cp} );
$template->param( ENT39CIP=> $Param->{ent39cip} );
$template->param( ENT40CF=> $Param->{ent40cf} );
$template->param( ENT40CP=> $Param->{ent40cp} );
$template->param( ENT40CIP=> $Param->{ent40cip} );
$template->param( ENT41CF=> $Param->{ent41cf} );
$template->param( ENT41CP=> $Param->{ent41cp} );
$template->param( ENT41CIP=> $Param->{ent41cip} );
$template->param( ENT42CF=> $Param->{ent42cf} );
$template->param( ENT42CP=> $Param->{ent42cp} );
$template->param( ENT42CIP=> $Param->{ent42cip} );
$template->param( ENT43CF=> $Param->{ent43cf} );
$template->param( ENT43CP=> $Param->{ent43cp} );
$template->param( ENT43CIP=> $Param->{ent43cip} );
$template->param( ENT44CF=> $Param->{ent44cf} );
$template->param( ENT44CP=> $Param->{ent44cp} );
$template->param( ENT44CIP=> $Param->{ent44cip} );
$template->param( ENT45CF=> $Param->{ent45cf} );
$template->param( ENT45CP=> $Param->{ent45cp} );
$template->param( ENT45CIP=> $Param->{ent45cip} );
$template->param( ENT46CF=> $Param->{ent46cf} );
$template->param( ENT46CP=> $Param->{ent46cp} );
$template->param( ENT46CIP=> $Param->{ent46cip} );
$template->param( ENT47CF=> $Param->{ent47cf} );
$template->param( ENT47CP=> $Param->{ent47cp} );
$template->param( ENT47CIP=> $Param->{ent47cip} );
$template->param( ENT48CF=> $Param->{ent48cf} );
$template->param( ENT48CP=> $Param->{ent48cp} );
$template->param( ENT48CIP=> $Param->{ent48cip} );
$template->param( ENT49CF=> $Param->{ent49cf} );
$template->param( ENT49CP=> $Param->{ent49cp} );
$template->param( ENT49CIP=> $Param->{ent49cip} );
$template->param( ENT50CF=> $Param->{ent50cf} );
$template->param( ENT50CP=> $Param->{ent50cp} );
$template->param( ENT50CIP=> $Param->{ent50cip} );
$template->param( ENT51CF=> $Param->{ent51cf} );
$template->param( ENT51CP=> $Param->{ent51cp} );
$template->param( ENT51CIP=> $Param->{ent51cip} );
$template->param( ENT52CF=> $Param->{ent52cf} );
$template->param( ENT52CP=> $Param->{ent52cp} );
$template->param( ENT52CIP=> $Param->{ent52cip} );
$template->param( ENT53CF=> $Param->{ent53cf} );
$template->param( ENT53CP=> $Param->{ent53cp} );
$template->param( ENT53CIP=> $Param->{ent53cip} );
$template->param( ENT54CF=> $Param->{ent54cf} );
$template->param( ENT54CP=> $Param->{ent54cp} );
$template->param( ENT54CIP=> $Param->{ent54cip} );
$template->param( ENT55CF=> $Param->{ent55cf} );
$template->param( ENT55CP=> $Param->{ent55cp} );
$template->param( ENT55CIP=> $Param->{ent55cip} );
$template->param( ENT56CF=> $Param->{ent56cf} );
$template->param( ENT56CP=> $Param->{ent56cp} );
$template->param( ENT56CIP=> $Param->{ent56cip} );
$template->param( ENT57CF=> $Param->{ent57cf} );
$template->param( ENT57CP=> $Param->{ent57cp} );
$template->param( ENT57CIP=> $Param->{ent57cip} );
$template->param( ENT58CF=> $Param->{ent58cf} );
$template->param( ENT58CP=> $Param->{ent58cp} );
$template->param( ENT58CIP=> $Param->{ent58cip} );
$template->param( ENT59CF=> $Param->{ent59cf} );
$template->param( ENT59CP=> $Param->{ent59cp} );
$template->param( ENT59CIP=> $Param->{ent59cip} );
$template->param( ENT60CF=> $Param->{ent60cf} );
$template->param( ENT60CP=> $Param->{ent60cp} );
$template->param( ENT60CIP=> $Param->{ent60cip} );
$template->param( ENT61CF=> $Param->{ent61cf} );
$template->param( ENT61CP=> $Param->{ent61cp} );
$template->param( ENT61CIP=> $Param->{ent61cip} );
$template->param( ENT62CF=> $Param->{ent62cf} );
$template->param( ENT62CP=> $Param->{ent62cp} );
$template->param( ENT62CIP=> $Param->{ent62cip} );
$template->param( ENT63CF=> $Param->{ent63cf} );
$template->param( ENT63CP=> $Param->{ent63cp} );
$template->param( ENT63CIP=> $Param->{ent63cip} );
$template->param( ENT64CF=> $Param->{ent64cf} );
$template->param( ENT64CP=> $Param->{ent64cp} );
$template->param( ENT64CIP=> $Param->{ent64cip} );

	 

# print the template output
$template->param( MESSAGES=> $message );
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
