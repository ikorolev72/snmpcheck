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



$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'task_add.htm', die_on_bad_params=>0 );

$table='tasks';
$id=0; # id of new task
$sname=$Param->{sname};

$template->param( AUTHORISED=>1 );
$dbh=db_connect() ;


if(  Action() ==0 ) {
	message2( "Cannot add new task" );	
} else {
	message2( "Task '$Param->{desc}' added. Please, check it in <a href='$Url->{ACTION_TASK_LIST}?id=$id&edit=1'> Task list </a>" ) ;
	$template->param( REDIRECT_TO=> "$Url->{ACTION_TASK_LIST}?id=$id&edit=1"  );
#	$template->param( REDIRECT=> "<meta http-equiv='refresh' content='2;url=$Url->{ACTION_TASK_LIST}?id=$id&edit=1'>"  );
}

$template->param( MESSAGES=> $message );
print  $template->output;

db_disconnect( $dbh );





sub Action {
	my $row;	

	if( $Param->{save} ) {
		unless( check_record()  ) {	
			return 0;
		}
			
		$row->{id}=GetNextSequence( $dbh ) ;
		$row->{sname}=$Param->{sname} ;
		$row->{desc}=$Param->{desc} ;
		$row->{user}='' ; # USER !!!!
		$row->{sdt}=time() ;
		$row->{pdt}=time() ; # planed time of starting task. there can be inserted future time
		$row->{dt}=time() ;
		$row->{param}=JSON->new->utf8->encode($Param); 
		$row->{status}=1 ; # added
		$row->{mess}='' ;
		
				
		if ( InsertRecord ( $dbh, $row->{id},  $table, $row ) ) {
			message2 ( "Record inserted succsesfuly" );
			$id=$row->{id};
			return 1;
		} else {
			message2 ( "Cannot insert record" );
			return 0;
		}
							
	}

return 0;
}




sub check_record {
	$retval=1;
	unless( CheckField ( $Param->{desc} ,'text', "Fields 'desc' ") ){
			$retval=0 ;
	}	
	unless( CheckField ( $Param->{sname} ,'login', "Fields 'sname' ") ){
			$retval=0 ;
	} else {
		my $table='snmpworker';
		my $row=GetRecordByField ( $dbh,  $table, 'sname', $Param->{sname} );
		unless( $row ) {
				message2( "Not found worker with name $Param->{sname}" );			
				$retval=0 ;
		}		
	}
	return $retval;
}
	


