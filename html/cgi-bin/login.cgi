#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );




$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'login.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

#print "Content-type: text/html\n\n" ;

my $dbh, $stmt, $sth, $rv;
$message='';
$title="Login";

$template->param( AUTHORISED=>1 );

$dbh=db_connect() ;

my $show_form=1;

if(  Action() ==0 ) {
	message2 ( "Incorrect login or password" );			
} else {
		my $row=GetRecordByField( $dbh,  'users', 'login', $Param->{login}, );
		my $secret=sha1_hex( time() );
		
		my $cookie_time=4; # set the cookies to 4 hours 
		my $cookie="<script type='text/javascript'>
		createCookie('id',		'$row->{id}',$cookie_time);
		createCookie('login',	'$row->{login}',$cookie_time);
		createCookie('name',	'$row->{name}',$cookie_time);
		createCookie('secret',	'$secret',$cookie_time);
		</script>"; 

		$template->param( SET_COOKIES=>$cookie );					
		my $nrow;
		$nrow->{login}=$Param->{login};
		$nrow->{secret}=$secret;
		$nrow->{dt}=time()+$cookie_time*3600;
		$nrow->{id}=$row->{id};
		DeleteRecord( $dbh, $nrow->{id}, 'session' );
 		InsertRecord( $dbh, $nrow->{id}, 'session', $nrow );
	message2 ( "Login successfull" );			
	$show_form=0;
}


	 
$template->param( SHOWFORM=>$show_form );
$template->param( LOGIN=>$Param->{login} );
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>$title );

  # print the template output
$template->param( MESSAGES=> $message );

#my %cookies = CGI::Cookie->fetch;
#if ( $cookies{'name'} ) {
#	$template->param( LOGIN_AS=> "You are login as '$cookies{'name'}->value'"  );	
#}

print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	
	if( $Param->{save} ) {
		my $row=GetRecordByField( $dbh, 'users', 'login', $Param->{login}, );
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
