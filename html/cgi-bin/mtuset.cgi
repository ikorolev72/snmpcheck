#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin','/home/nems/client_persist/htdocs/bulktool3/html/cgi-bin', '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/' , '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/x86_64-linux-thread-multi/'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$sname="mtuset";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'mtuset.htm', die_on_bad_params=>0 );
$template->param( SNAME=> $sname  );
$title="iPasolink MTU set tool";

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
$Param->{gbemtuallow}=$Param->{gbemtuallow}?1:0;
$Param->{femtuallow}=$Param->{femtuallow}?1:0;

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
	$template->param( GBEMTUALLOW=>$Param->{gbemtuallow} );
	$template->param( GBEMTU=>$Param->{gbemtu} );
	$template->param( FEMTUALLOW=>$Param->{femtuallow} );
	$template->param( FEMTU=>$Param->{femtu} );
	 

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
	if( !$Param->{gbemtuallow} && !$Param->{femtuallow} ) {
			message2( "Please, select GbE MTU, FE MTU checkboxes" );
			$retval=0;
	}
	unless( CheckField ( $Param->{gbemtu} ,'int', "Field 'GbE MTU' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{femtu} ,'int', "Field 'FE MTU' " )) {
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