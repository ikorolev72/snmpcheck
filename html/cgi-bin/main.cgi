#!/usr/bin/perl
# korolev-ia [at] yandex.ru

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin','/home/nems/client_persist/htdocs/bulktool3/html/cgi-bin', '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/' , '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/x86_64-linux-thread-multi/'; } 
use COMMON_ENV;
use CGI::Carp qw ( fatalsToBrowser );



$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'main.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }


my $dbh, $stmt, $sth, $rv;
$message='';
$title="Main administration page";


$template->param( AUTHORISED=>1 );



$dbh=db_connect() ;

my $show_form=0;
my $table='snmpworker';
my $record;



# show list of workers
#approved_application_for_authentication
#approved_application_for_no_authentication

	$stmt ="SELECT *  from snmpworker order by sname  ; " ;
	$sth = $dbh->prepare( $stmt );
	unless ( $rv = $sth->execute(  ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
	}
	my @loop_data=();
	while (my $row = $sth->fetchrow_hashref) {
		my %row_data;   
		$row_data{ TOOL_DESC }=$row->{desc};
		$row_data{ TOOL_URL }="./$row->{cgiscript}";
		push(@loop_data, \%row_data);
	}
	$template->param(TOOL_LIST_LOOP => \@loop_data);


 
#print "<pre>".Dumper( $ENV{'SCRIPT_NAME'} )."</pre>";
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>$title );




  # print the template output
$template->param( MESSAGES=> $message );
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

