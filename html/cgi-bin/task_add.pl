#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );



$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'task_add.htm', die_on_bad_params=>0 );

$table='tasks';
$id=0; # id of new task
$sname=$Param->{sname};
$outfile=$sname."_".generate_filename()."_log.csv";


$dbh=db_connect() ;


if(  Action() ==0 ) {
	message2( "Cannot add new task" );	
} else {
	message2( "Task '$Param->{desc}' added. Please, check it in <a href='/cgi-bin/task_list.pl'> Task list </a>" ) ;


}

$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
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
		$row->{outfile}=$outfile ;
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

	unless( CheckField ( $outfile ,'filename', "Fields 'outfile' $outfile ") ){
		$retval=0 ;
	}
	return $retval;
}
	


