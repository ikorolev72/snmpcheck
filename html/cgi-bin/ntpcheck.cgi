#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$sname="ntpcheck";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'ntpcheck.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );
$title="NTP status check tool";


$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

my $dbh, $stmt, $sth, $rv;
$message='';
$template->param( AUTHORISED=>1 );
$template->param( MS5000=>1 );


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
#	$template->param( DESC=> $Param->{desc} || "$sname task ".get_date() );
#	$template->param( IP=> $Param->{ip} );
#	$template->param( GROUP=> $Param->{group} );
#	$template->param( SUBGROUP=> $Param->{subgroup} );
#	$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );
	
} else {
	$template->param( SHOWFORM=> 0 );
	$template->param( SHOWFORM_TO_TASK => 1 );
	$template->param( LOGIN=>$Param->{login} );
	$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
	$template->param( ACTION_TASK_ADD=>  "/cgi-bin/task_add.cgi" );
	$template->param( TITLE=>"$title. Ready to add task" );
}

	foreach $group ( get_groups() ) {
		my %row_data;   
		$row_data{ GROUP }=$group;
		push(@loop_data, \%row_data);
	}
	$template->param(GROUP_LIST_LOOP => \@loop_data);	
	$template->param( DESC=> $Param->{desc} || "$sname task ".get_date() );
	$template->param( IP=> $Param->{ip} );
	$template->param( GROUP=> $Param->{group} );
	$template->param( SUBGROUP=> $Param->{subgroup} );
	$template->param( ALL_IPASOLINK=> $Param->{all_ipasolink} );




	 

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