#!perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '/opt/' ,'/home/admin/lib'; } 
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
$template = HTML::Template->new(filename => 'ntpcheck.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

#print "Content-type: text/html\n\n" ;

my $dbh, $stmt, $sth, $rv;
$message='';

$dbh=db_connect() ;

my $show_form=1;
my $table='users';


if(  Action() ==0 ) {
	my $show_form=0;
	# task planing
}	
foreach $group ( get_groups() ) {
	my %row_data;   
	$row_data{ GROUP }=$group;
	push(@loop_data, \%row_data);
}
$template->param(GROUP_LIST_LOOP => \@loop_data);


	 
$template->param( SHOWFORM=>$show_form );
$template->param( LOGIN=>$Param->{login} );
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>"NTP status check tool" );
$template->param( MESSAGES=> $message );

  # print the template output
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	my $row;
	if( $Param->{save} ) {
		unless( check_ntpcheck_record()  ) {	
			return 0;
		}
			
	}
return 0;
}



sub check_record {
	my $retval=1;
	unless( CheckField ( $Param->{ip} ,'ip_op_empty', "Field 'ip' " )) {
			$retval=0;
	} 
	unless( CheckField ( $Param->{group} ,'text_no_empty', "Field 'group' ") ){
		$retval=0;
	}
	unless( CheckField ( $Param->{group} ,'text_no_empty', "Field 'group' ") ){
		$retval=0;
	}
	unless( CheckField ( $Param->{all_ipasolink} ,'text_no_empty', "Field 'group' ") ){
		$retval=0;
	}
	return $retval;
}