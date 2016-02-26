#!perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/home/admin/lib' ,'/home/admin/lib'; } 
use COMMON_ENV;
#use strict;
#use warnings;
use HTML::Template;
use DBI;
use CGI::Carp qw ( fatalsToBrowser );
use CGI qw(param);
use Digest::SHA qw(sha1 sha1_hex );
use Data::Dumper;
use CGI::Cookie;
use CGI qw/:standard/;


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
}
	 
$template->param( SHOWFORM=>1 );
$template->param( LOGIN=>$Param->{login} );
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>"Login" );
$template->param( MESSAGES=> $message );

  # print the template output
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
return 1;
}
