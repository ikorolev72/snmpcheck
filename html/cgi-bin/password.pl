#!perl
# korolev-ia [at] yandex.ru

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );



$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'password.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }


my $dbh, $stmt, $sth, $rv;
$message='';

$dbh=db_connect() ;

my $show_form=0;
my $table='users';


if( 0 == Action() ) {
	$show_form=1;

}
	 
if( $show_form ) {
	$template->param( SHOWFORM=>1 );
	$template->param( EDIT=>$Param->{edit} );
  if( $Param->{edit} ) {
	my $row=GetRecord ( $dbh, $Param->{id}, $table );
	if( $row ) {		
		$template->param( LOGIN=>$row->{login} );
		$template->param( NAME=>$row->{name} );
		$template->param( ID=>$row->{id} );
	}
	else{
		message2 ( " Cannot to get record from table $table with id = $Param->{id}" );
	}
  }
} 

$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>"Change password" );

  # print the template output
$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	unless( $Param->{id} ) {
		message2 ( "incorrect parameter, cannot see id " );
		return 0;
	}
	
	my $row=GetRecord ( $dbh, $Param->{id}, $table );	
	if( $row ) {
		$template->param( ID=>$row->{id} );
	}
	else{
		message2 ( " Cannot to get record from table $table with id = $Param->{id}" );
		return 0;
	}

	if( $Param->{save} ) {
		# if exist fiels id, then we edit the record
		# if fiels password is not empty, then update password too
			if( check_password_record() ) {
				$row->{password}=sha1_hex( $Param->{password} );
			} else {
				return 0;
			}
			
		if ( UpdateRecord ( $dbh, $Param->{id}, 'users', $row ) ) {
			message2 ( "Record updated succsesfuly" );
			return 1;
		} else {
			message2 ( "Cannot update record" );
			return 0;
		}
			
	}
	if( $Param->{edit} ) {
		return 0;
	}	

return 1;
}


sub check_password_record {
	my $row=GetRecord ( $dbh, $Param->{id}, $table );
	unless( $row ) {		
		message2 ( " Cannot to get record from table $table with id = $Param->{id}" );
		return 0;
	}

	if( sha1_hex( $Param->{old_password} ) ne $row->{password} ) {
		message2( "Incorrect 'Old password'" ); 
		return 0;
	}
	if( $Param->{password} ne $Param->{password0}  ) {
		message2( "Fields 'password' and 'password0' must be equiv" ); 
		return 0;
	}
	if( CheckField ( $Param->{password} ,'password', "Field 'password' ") ) {
			return 1;
		}
	return 0;
}

