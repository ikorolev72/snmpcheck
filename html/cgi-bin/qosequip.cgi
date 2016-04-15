#!/usr/bin/perl
# korolev-ia [at] yandex.ru
# version 1.1 2016.04.11
use lib 'C:\GIT\snmpcheck\lib' ;
use lib '/opt/snmpcheck/lib' ;
use lib '../lib' ;
use lib '../../lib' ;

print "Content-type: text/html

" ;


use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );



$sname="qosequip";
$title="iPasolink QoS set tool (equipment mode)";
$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'qosequip.htm', die_on_bad_params=>0 );

$template->param( SNAME=> $sname  );
$template->param( TITLE=> $title  );
$template->param( ACTION=>  $ENV{SCRIPT_NAME} );



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
		$template->param( MESSAGES=> $message );

		print  $template->output;
	exit 0;
 }
}


$dbh=db_connect() ;
unless( $Param ) {
	my $row=GetRecordByField( $dbh, 'def_val', 'sname', $sname );
	if( $row ) {
		my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
		$Param=$coder->decode ($row->{val});
		undef( $Param->{id} );
		undef( $Param->{save} );
		undef( $Param->{save_first} );
		undef( $Param->{save_second} );
		undef( $Param->{save_as_default} );
		undef( $Param->{edit} );
		undef( $Param->{new} );
	}
}


my $show_form=1;


$Param->{all_ipasolink}=$Param->{all_ipasolink}?1:0;
$Param->{subgroup}=$Param->{subgroup}?1:0;
$Param->{inop}=$Param->{inop}?1:0;
$Param->{ucon}=$Param->{ucon}?1:0;
$Param->{umng}=$Param->{umng}?1:0;


$template->param( SHOWFORM_FIRST=> 1 );
$template->param( SHOWFORM_SECOND=> 0 );
$template->param( SHOWFORM_TO_TASK=> 0 );

# get title of page from db
# my $trow=GetRecordByField ( $dbh, 'snmpworker', 'sname', $sname ) ;
# $title=$trow->{desc} if( $trow->{desc});

if( $Param->{save_as_default} ) {
	my $result=1;
	if( check_record()  ) {
		$template->param( SHOWFORM_FIRST=> 1 );
		$template->param( SHOWFORM_SECOND=> 0 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME} );
		$template->param( TITLE=> $title );	
		my $coder = JSON::XS->new->utf8->pretty->allow_nonref; # bugs with JSON module and threads. we need use JSON::XS
		my $json = $coder->encode ($Param);
		my $row;
		if( $row=GetRecordByField( $dbh, 'def_val', 'sname', $sname )  ) {
			$row->{ val }=$coder->encode ($Param);
			$result=UpdateRecord( $dbh, $row->{id}, 'def_val', $row );
		} else {
			$row->{id}=GetNextSequence($dbh);
			$row->{ val }=$coder->encode ($Param);
			$row->{ sname }=$sname;			
			$result=InsertRecord( $dbh, $row->{id}, 'def_val', $row );
		}
		if( $result) {
			message2( "<font color=green>Default form values saved</font>");
		} else {
			message2( "Cannot save default form values");
		}
	}
}


if( $Param->{save_first} ) {
	if( check_record()  ) {
		$template->param( SHOWFORM_FIRST=> 0 );
		$template->param( SHOWFORM_SECOND=> 1 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
		$template->param( DESC=> "$sname task " ) ; 	# .get_date() );
			if( 1 == $Param->{task_start_type} ) {
				$template->param( DESC=> "$sname crontab task " )
			}		
#message2( "<pre>".Dumper($Param)."</pre>");		
	} else{
		$template->param( SHOWFORM_FIRST=> 1 );
		$template->param( SHOWFORM_SECOND=> 0 );
		$template->param( SHOWFORM_TO_TASK=> 0 );
	}
}

if( $Param->{save_second} ) {
	if( check_record2()  ) {
		$template->param( SHOWFORM_FIRST=> 0 );
		$template->param( SHOWFORM_SECOND=> 0 );
		$template->param( SHOWFORM_TO_TASK=> 1 );
		$template->param( TITLE=>"$title. Ready to add task" );
		$template->param( ACTION=>  $ENV{SCRIPT_NAME}  );		
		$template->param( ACTION_TASK_ADD =>  $Url->{ACTION_TASK_ADD} );
		$template->param( DESC=> $Param->{desc}.get_date() );
		if( 1 == $Param->{task_start_type} ) {
			$template->param( ACTION_TASK_ADD =>  $Url->{ACTION_TASK_ADD_CRONTAB} );
			$template->param( DESC=> $Param->{desc} );
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




my @loop_data=();
	my $grp=get_groups(  $Cfg->{iplistdb} );
	$grp->{''}='';
	foreach $group ( sort keys( %{$grp} ) ) {
		my %row_data;   
		$row_data{ SELECTED }=' selected ' if( $Param->{group} eq $group );
		$row_data{ SELECTED }=' selected ' if( !$Param->{group} and $grp eq '' ) ;
		$row_data{ GROUP }=$group;
		$row_data{ GROUP_NAME }=$grp->{$group};		
		push(@loop_data, \%row_data);
	}
		#my %row_data;   
		#$row_data{ SELECTED }=' selected ' 	unless( $Param->{group}  ) ;
		#$row_data{ GROUP }='';
		#$row_data{ GROUP_NAME }='';	
		#push(@loop_data, \%row_data);
		
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


	
if( $Param->{Que_num}==1 ) {
	$template->param( QUE_TXT=> 4 );
}
if( $Param->{Que_num}==2 ) {
	$template->param( QUE_TXT=> 8 );
}	
		
foreach $y ( qw( Que_num queset profnum proselect delpro actpro ent1cf ent1cp ent1cip ent2cf ent2cp ent2cip 
ent3cf ent3cp ent3cip ent4cf ent4cp ent4cip ent5cf ent5cp ent5cip ent6cf ent6cp ent6cip ent7cf ent7cp ent7cip 
ent8cf ent8cp ent8cip ent9cf ent9cp ent9cip ent10cf ent10cp ent10cip ent11cf ent11cp ent11cip ent12cf ent12cp ent12cip 
ent13cf ent13cp ent13cip ent14cf ent14cp ent14cip ent15cf ent15cp ent15cip ent16cf ent16cp ent16cip ent17cf ent17cp ent17cip 
ent18cf ent18cp ent18cip ent19cf ent19cp ent19cip ent20cf ent20cp ent20cip ent21cf ent21cp ent21cip ent22cf ent22cp ent22cip 
ent23cf ent23cp ent23cip ent24cf ent24cp ent24cip ent25cf ent25cp ent25cip ent26cf ent26cp ent26cip ent27cf ent27cp ent27cip 
ent28cf ent28cp ent28cip ent29cf ent29cp ent29cip ent30cf ent30cp ent30cip ent31cf ent31cp ent31cip ent32cf ent32cp ent32cip 
ent33cf ent33cp ent33cip ent34cf ent34cp ent34cip ent35cf ent35cp ent35cip ent36cf ent36cp ent36cip ent37cf ent37cp ent37cip 
ent38cf ent38cp ent38cip ent39cf ent39cp ent39cip ent40cf ent40cp ent40cip ent41cf ent41cp ent41cip ent42cf ent42cp ent42cip 
ent43cf ent43cp ent43cip ent44cf ent44cp ent44cip ent45cf ent45cp ent45cip ent46cf ent46cp ent46cip ent47cf ent47cp ent47cip 
ent48cf ent48cp ent48cip ent49cf ent49cp ent49cip ent50cf ent50cp ent50cip ent51cf ent51cp ent51cip ent52cf ent52cp ent52cip 
ent53cf ent53cp ent53cip ent54cf ent54cp ent54cip ent55cf ent55cp ent55cip ent56cf ent56cp ent56cip ent57cf ent57cp ent57cip 
ent58cf ent58cp ent58cip ent59cf ent59cp ent59cip ent60cf ent60cp ent60cip ent61cf ent61cp ent61cip ent62cf ent62cp ent62cip 
ent63cf ent63cp ent63cip ent64cf ent64cp ent64cip
)) {
	my $Y=uc($y);
	$template->param( $Y => $Param->{ $y } );
	$template->param( "${Y}_$Param->{ $y }" => 1 ) if( $Param->{ $y } );
}
			

#message2( "<pre>".Dumper($template)."</pre>");		 

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
	if( 1 == $Param->{task_start_type} ) {
		unless( CheckField ( $Param->{cron} ,'cron', "Field 'Crontab' ") ){
			$retval=0;
		}
		unless( require_authorisation() ) { 
			message2( "Only authorised user can add crontab task" );
			$retval=0;
		}
	}
	unless( CheckField ( $Param->{desc} ,'desc', "Field 'Description' ") ){
		$retval=0;
	}
	return $retval;
}

