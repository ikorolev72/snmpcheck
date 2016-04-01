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
$template = HTML::Template->new(filename => 'task_list.htm', die_on_bad_params=>0 );

$table='tasks';
$sname=$Param->{sname};

$template->param( AUTHORISED=>1 );
$template->param( REFRESH_PAGE => 0 );


$dbh=db_connect() ;

update_tasks($dbh);

my $request_uri=$ENV{'REQUEST_URI'};
$request_uri=~s/del=1/del=0/g;
$template->param( REQUEST_URI => $request_uri );

$Param->{page}=1 if( !$Param->{page} || !$Param->{page}=~/^\d+$/  ); # start from first page
$Param->{lines_per_page}=25 if( !$Param->{lines_per_page} || !$Param->{lines_per_page}=~/^\d+$/ ) ;
$Param->{filter_sname}='' if( !$Param->{filter_sname} || !$Param->{lines_per_page}=~/^\w+$/ ) ;




if( $Param->{del} ) {
	if (  require_authorisation() ) { # we require authorisation for delete tasks
		$template->param( REQUEST_URI => "$ENV{'SCRIPT_NAME'}" );
		my $row=GetRecord( $dbh , $Param->{id}, $table  );
			if( $row ) {
				unlink( "$Paths->{JSON}/$row->{id}.\w+\.json" ) ;
				unlink( "$Paths->{OUTFILE_DIR}/$row->{outfile}" ) ;
				unlink( "$Paths->{WORKER_DIR}.$row->{id}.lod" ) ;
				DeleteRecord( $dbh, $Param->{id}, $table  );
			} else {
				message2( "Cannot found the record with id: $Param->{id}" ) ;
			}
	} else{
		message2( "Only authorised users can delete tasks" );
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
					if( 2==$row->{status} || 4==$row->{status}  ) {
						$template->param( STATUS_GREEN=>1 );
					}
					if( 3==$row->{status} ) {
						$template->param( STATUS_YELLOW=>1 );
					}
					if( 5==$row->{status} || 6==$row->{status} ) {
						$template->param( STATUS_RED=>1 );
					}
				$template->param( MESS=>  encode_entities(  $row->{mess} )   ); 				
				$template->param( OUTFILE=>"$Url->{OUTFILE_DIR}/$row->{outfile}" ) if ( -f "$Paths->{OUTFILE_DIR}/$row->{outfile}" );
				
				if(  4!=$row->{status}  ) { # do not refresh page if status if finished
					$template->param( REFRESH_PAGE => 1 );
				}
			} else {
				message2( "Do not found the record with id=$Param->{id}");
			}
		} else {
			message2( "You don't select record id");
			
		}				
		
} else { 
		# if we will show the list of tasks	
		
	$template->param( SHOWFORM=>0 );
	$template->param( REFRESH_PAGE => 1 );

	my $Where;
	$Where->{ sname }=$Param->{filter_sname} if( $Param->{filter_sname} );	
	
	my @F=();
	my @V=();	
	foreach( keys %{ $Where }) {
		push ( @F, " $_ = ? " );
		push ( @V , $Where->{$_} );
	}
	my $stmt ="";

	if( $#F > -1 ) {
		$stmt ="SELECT * FROM  $table where " . join( ' and ',  @F )." order by dt DESC LIMIT ? OFFSET ? ;";		
		$sth = $dbh->prepare( $stmt );
		unless ( $rv = $sth->execute( @V, $Param->{lines_per_page}, $Param->{lines_per_page}*($Param->{page}-1) ) || $rv < 0 ) {
			message2 ( "Someting wrong with database  : $DBI::errstr" );
			w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
		}
	} else {
		$stmt ="SELECT * FROM  $table order by dt DESC LIMIT ? OFFSET ? ;";		
		$sth = $dbh->prepare( $stmt );
		unless ( $rv = $sth->execute( $Param->{lines_per_page}, $Param->{lines_per_page}*($Param->{page}-1) ) || $rv < 0 ) {
			message2 ( "Someting wrong with database  : $DBI::errstr" );
			w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
		}
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
		$row_data{ WORKER }=$Task->{ $row->{worker} }  ; 
		$row_data{ PROGRESS }= "$row->{progress} %"  ; 
				if( 2==$row->{status} || 4==$row->{status} ) {
					$row_data{ STATUS_GREEN }=1 ;
				}
				if( 3==$row->{status} ) {
					$row_data{  STATUS_YELLOW }=1 ;
				}
				if( 5==$row->{status} || 6==$row->{status} ) {
					$row_data{ STATUS_RED }=1 ;
				}
		
		$row_data{ OUTFILE }="$Url->{OUTFILE_DIR}/$row->{outfile}" if ( -f "$Paths->{OUTFILE_DIR}/$row->{outfile}" ) ; 
		$row_data{ MESS }=encode_entities(  $row->{mess} ); 

		push(@loop_data, \%row_data);
	}
	$template->param(TASKS_LIST_LOOP => \@loop_data);
	$template->param( TITLE=>" List of tasks " );	
		
}



$template->param( FILTER_SNAME=> $Param->{filter_sname}  ); 
$template->param( PAGE=> $Param->{page} ); 
$template->param( LINES_PER_PAGE=> $Param->{lines_per_page} ); 

@loop_data=();
my $Cfg=ReadConfig();
foreach $w ( sort( split(/,/, $Cfg->{approved_application_for_no_authentication}), split(/,/,$Cfg->{approved_application_for_authentication}) ) ) {
	my %row_data;   
	$row_data{ LOOP_SNAME }=$w;
	push(@loop_data, \%row_data);
}
$template->param(SNAME_LIST_LOOP => \@loop_data);


my $Where;
$Where->{ sname }=$Param->{filter_sname} if( $Param->{filter_sname} );



my $count=GetCountRecords( $dbh, $table, $Where );
#my $pages=$count/$Param->{lines_per_page};

my @loop_data=();
foreach $i ( 1..( $count/$Param->{lines_per_page}+1 ) ) {
		my %row_data;   		
		if( $i==$Param->{page} ) {
			$row_data{ PAGE_SELECTED_BGCOLOR }=1 ;
		}
		$row_data{ PAGE }=$i ; 
		$row_data{ PAGE_PARAM }="?page=$i&filter_sname=$Param->{filter_sname}&lines_per_page=$Param->{lines_per_page}" ; 
		push(@loop_data, \%row_data);	
}
$template->param(PAGER_LOOP => \@loop_data);



$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( MESSAGES=> $message );
print  $template->output;

db_disconnect( $dbh );





