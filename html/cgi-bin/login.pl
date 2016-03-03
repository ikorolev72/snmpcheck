#!perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 
use COMMON_ENV;




$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'login.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

#print "Content-type: text/html\n\n" ;

my $dbh, $stmt, $sth, $rv;
$message='';

$dbh=db_connect() ;

my $show_form=1;
my $table='users';


if(  Action() ==0 ) {
	print "Content-type: text/html\n\n" ;
	message2 ( "Incorrect login or password" );			
} else {
			#my $secret=sha1_hex( time() );

			my $cookie1 = CGI::Cookie->new(-name    =>  'login',
                             -value   =>  [ $row->{login} ],
                             -expires =>  '+1H',
                             -domain  =>  $ENV{HTTP_HOST},
	                    );	
			print header(-cookie=>[$cookie1]);						
	message2 ( "Login successfull" );			
	$show_form=0;
}
	 
$template->param( SHOWFORM=>$show_form );
$template->param( LOGIN=>$Param->{login} );
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>"Login" );

  # print the template output
$template->param( MESSAGES=> $message );
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	
	if( $Param->{save} ) {
		my $row=GetRecordByField( $dbh,  $table, 'login', $Param->{login}, );
		unless( $row ) {	
			return 0;
		}
		if( $row->{password} eq sha1_hex( $Param->{password} ) ) {
			return 1;
		} else {
			return 0;
		}
	}
return 0;
}
