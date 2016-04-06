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
$template = HTML::Template->new(filename => 'task_list_crontab.htm', die_on_bad_params=>0 );

$table='crontasks';
#$sname=$Param->{sname};

$template->param( AUTHORISED=>1 );

$dbh=db_connect() ;

#update_tasks($dbh);

$template->param( REQUEST_URI => $ENV{REQUEST_URI} );



if( $Param->{del} ) {
	my $row=GetRecord( $dbh , $Param->{id}, $table  );
	if( $row ) {
		if (  1==require_authorisation() || (require_authorisation() && ( $row->{login} eq get_login() )) ) { # we require authorisation for delete tasks
				$template->param( REQUEST_URI => $ENV{SCRIPT_NAME} );
				DeleteRecord( $dbh, $Param->{id}, $table  );
		} else{
			message2( "Only root or owner can remove crontab record" );
		}
	} else {
				message2( "Cannot found the record with id: $Param->{id}" ) ;
	}
}


if( $Param->{edit} ) {
		# if we will show full page of one task
		$template->param( SHOWFORM=>1 );
		if( $Param->{id} ){
			my $row=GetRecord( $dbh , $Param->{id}, $table  );
			if( $row ) {
				$template->param( TITLE=>"Show the crontab $row->{id} :".encode_entities( $row->{desc} ) );	

				$template->param( ID=>$row->{id} ); 
				$template->param( TASKID=>$row->{taskid} ); 
				$template->param( STATUS=> $Task->{ $row->{status} } ); 
				$template->param( PARAM=> encode_entities(  $row->{param} )  ); # need check how it code it
				$template->param( SNAME=>$row->{sname} ); 
				$template->param( DESC=> encode_entities( $row->{desc} )); 
				$template->param( LOGIN=> $row->{login}  ); 
				$template->param( SDT=> get_date( $row->{sdt} ) ); 
				$template->param( DT=>  get_date($row->{dt}) ); 
				$template->param( CRON=>  encode_entities($row->{cron}) ); 		
				
			} else {
				message2( "Do not found the record with id=$Param->{id}");
			}
		} else {
			message2( "You don't select record id");			
		}				
		
} else { 
		# if we will show the list of tasks	
		
	$template->param( SHOWFORM=>0 );

	# show list of workers
	$stmt ="SELECT * from $table order by dt DESC; " ; # LIMIT $limit OFFSET $page*$limit;
	$sth = $dbh->prepare( $stmt );
	unless ( $rv = $sth->execute() || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
	}

	while (my $row = $sth->fetchrow_hashref) {
		my %row_data;   		
		
				$row_data{ ID }=$row->{id} ;
				$row_data{ TASKID }=$row->{taskid} ;
				$row_data{ STATUS }= $Task->{ $row->{status} } ;
				$row_data{ PARAM }= encode_entities(  $row->{param} )  ;# need check how it code it
				$row_data{ SNAME }=$row->{sname} ;
				$row_data{ DESC }= encode_entities( $row->{desc} );
				$row_data{ LOGIN }= $row->{login}  ;
				$row_data{ SDT }= get_date( $row->{sdt} ) ;
				$row_data{ DT }=  get_date($row->{dt}) ;		
				$row_data{ CRON }=  encode_entities($row->{cron}) ;		



		push(@loop_data, \%row_data);
	}
	$template->param( CRONTAB_LIST_LOOP => \@loop_data);
	$template->param( TITLE=>" Crontab list records " );	
		
}


$template->param( ACTION_TASK_LIST => $Url->{ACTION_TASK_LIST} );
$template->param( ACTION =>  $ENV{SCRIPT_NAME} );
$template->param( MESSAGES=> $message );
print  $template->output;

db_disconnect( $dbh );





