#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );



$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'task_list.htm', die_on_bad_params=>0 );

$table='tasks';
$sname=$Param->{sname};


$dbh=db_connect() ;





update_status($dbh); 

$template->param( REQUEST_URI => "$ENV{'REQUEST_URI'}" );

if( $Param->{del} ) {
	$template->param( REQUEST_URI => "$ENV{'SCRIPT_NAME'}" );
	my $row=GetRecord( $dbh , $Param->{id}, $table  );
		if( $row ) {
			unlink( "$Paths->{JSON}/$row->{id}.\w+\.json" ) ;
			unlink( "$Paths->{OUTFILE}/$row->{outfile}" ) ;
			DeleteRecord( $dbh, $Param->{id}, $table  );
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
				$template->param( TITLE=>"Show the task $row->{id} :".encode_entities( $row->{desc} ) );	
				$template->param( ID=>$row->{id} ); 
				$template->param( SNAME=>$row->{sname} ); 
				$template->param( DESC=> encode_entities( $row->{desc} )); 
				$template->param( WORKER=>$row->{worker} ); 
				$template->param( PARAM=> encode_entities(  $row->{param} )  ); # need check how it code it
				$template->param( DT=>  get_date($row->{dt}) ); 
				$template->param( SDT=> get_date( $row->{sdt} ) ); 
				$template->param( STATUS=> $Task->{ $row->{status} } ); 
				$template->param( PROGRESS=> "$row->{progress} %"  ); 
					if( 4==$row->{status} ) {
						$template->param( STATUS_GREEN=>1 );
					}
					if( 3==$row->{status} ) {
						$template->param( STATUS_YELLOW=>1 );
					}
					if( 5==$row->{status} || 6==$row->{status} ) {
						$template->param( STATUS_RED=>1 );
					}
				$template->param( MESS=>  encode_entities(  $row->{mess} )   ); 
				$template->param( OUTFILE=>"$Url->{OUTFILE}/$row->{outfile}" ) if ( -f "$Paths->{OUTFILE}/$row->{outfile}" );							
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
		$row_data{ DESC }=encode_entities(  $row->{desc} ); 
		$row_data{ ACTION }=$row->{action} ; 
		$row_data{ SNAME }=$row->{sname} ; 
		$row_data{ DT }=get_date( $row->{dt} ); 
		$row_data{ SDT }=get_date( $row->{sdt} ); 
		$row_data{ STATUS }=$Task->{ $row->{status} }  ; 
		$row_data{ PROGRESS }= "$row->{progress} %"  ; 
				if( 4==$row->{status} ) {
					$row_data{ STATUS_GREEN }=1 ;
				}
				if( 3==$row->{status} ) {
					$row_data{  STATUS_YELLOW }=1 ;
				}
				if( 5==$row->{status} || 6==$row->{status} ) {
					$row_data{ STATUS_RED }=1 ;
				}
		
		$row_data{ OUTFILE }="$Url->{OUTFILE}/$row->{outfile}" if ( -f "$Paths->{OUTFILE}/$row->{outfile}" ) ; 
		$row_data{ MESS }=encode_entities(  $row->{mess} ); 

		push(@loop_data, \%row_data);
	}
	$template->param(USERS_LIST_LOOP => \@loop_data);
	$template->param( TITLE=>" List of tasks " );	
		
}




$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
print  $template->output;

db_disconnect( $dbh );




sub update_status {
	my $dbh=shift;
	my $timeout=3600; # set timeout for tasks to 1 hour
	# SELECT * FROM COMPANY WHERE AGE NOT IN ( 25, 27 );
	my $stmt ="SELECT id, dt from $table where status IN ( 1,2,3 ) order by dt DESC  ; " ;  # select only task started, added or running 
		# LIMIT $limit OFFSET $page*$limit;																
	my $sth = $dbh->prepare( $stmt );
	unless ( $rv = $sth->execute() || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
		return 0;
	}

	while (my $row = $sth->fetchrow_hashref) {
		my $json_out="$Paths->{JSON}/$row->{id}.out.json";
		unless( -f $json_out ) {
#			if ( time() - $row->{pdt} > $timeout )  { # task do not start during timeout after planed time
#				my $nrow;
#				$nrow->{ dt }=time();
#				$nrow->{ status }=5; # failed by timeout
#				$nrow->{ mess }="Task planed start at ". get_date( $row->{pdt} ) ." but do not start during $timeout sec. Failed by timeout";						
#				$nrow->{ progress }=1;						
#				update_task_status ( $dbh, $nrow ) ;				
#				next;
#			}
#			if ( time() - $row->{dt} > $timeout )  {  # time of task do not changed during timeout
#				my $nrow;
#				$nrow->{ dt }=time();
#				$nrow->{ status }=5; # failed by timeout
#				$nrow->{ mess }="Do not get any messages from task during $timeout sec. Failed by timeout";						
#				$nrow->{ progress }=1;						
#				update_task_status ( $dbh, $nrow ) ;				
#				next;
#			}
			next;
		}
		
		my $json_text   = ReadFile(  $json_out ); 

		my $nrow = JSON->new->utf8->decode($json_text) ;		
		$nrow->{ dt }=time();
		if( $row->{dt} == $nrow->{ dt }   )  {
				if(  time() - $row->{dt} > $timeout ) {
					$nrow->{ status }=5; # failed by timeout
					$nrow->{ mess }="Do not get any messages from task during $timeout sec. Failed by timeout";						
					$nrow->{ progress }=1;						
					update_task_status ( $dbh, $nrow ) ;			
					next;
				}
			next;
		}
		update_task_status ( $dbh, $nrow ) ;			
	}		
	return 1;
}





