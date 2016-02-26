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


$ENV{ "HTML_TEMPLATE_ROOT" }=$Paths->{TEMPLATE};
$template = HTML::Template->new(filename => 'users.htm', die_on_bad_params=>0 );

$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }


my $dbh, $stmt, $sth, $rv;
$message='';

$dbh=db_connect() ;

my $show_form=0;
my $table='snmpworker';
my $record;


unless ( Action() ) {
	$show_form=1;
};

	
 

if( $show_form ) {
	$template->param( SHOWFORM=>1 );
	$template->param( EDIT=>$Param->{edit} );
	$template->param( NEW=>$Param->{new} );

	
  if( $Param->{new} ) {
	$template->param( NAME=>$Param->{name} );
	$template->param( DESC=>$Param->{desc} );
	$template->param( IP=>$Param->{ip} );
	$template->param( AUTH=>$Param->{auth} );
	$template->param( SNMPUSER=>$Param->{snmpuser} );
	$template->param( SNMPAP=>$Param->{snmpap} );
	$template->param( SNMPPK=>$Param->{snmppk} );
	$template->param( SNMPR=>$Param->{snmpr} );
	$template->param( SNMPT=>$Param->{snmpt} );
	$template->param( SNMPAPRO=>$Param->{snmpapro} );
	$template->param( SNMPPRO=>$Param->{snmppro} );
	$template->param( SNMPLEVEL=>$Param->{snmplevel} );
  }
  if( $Param->{edit} ) {
	my $row=GetRecord ( $dbh, $Param->{id}, $table );
	if( $row ) {		
		$template->param( ID=>$row->{id} );
		$template->param( NAME=>$row->{name} );
		$template->param( DESC=>$row->{desc} );
		$template->param( IP=>$row->{ip} );
		$template->param( AUTH=>$row->{auth} );
		$template->param( SNMPUSER=>$row->{snmpuser} );
		$template->param( SNMPAP=>$row->{snmpap} );
		$template->param( SNMPPK=>$row->{snmppk} );
		$template->param( SNMPR=>$row->{snmpr} );
		$template->param( SNMPT=>$row->{snmpt} );
		$template->param( SNMPAPRO=>$row->{snmpapro} );
		$template->param( SNMPPRO=>$row->{snmppro} );
		$template->param( SNMPLEVEL=>$row->{snmplevel} );
	}
	else{
		message2 ( " Cannot to get record from table $table with id = $Param->{id}" );
	}
  }
} else {

# show list of workers
	$stmt ="SELECT *  from $table order by name; " ;
	$sth = $dbh->prepare( $stmt );
	unless ( $rv = $sth->execute() || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
	}

	while (my $row = $sth->fetchrow_hashref) {
		my %row_data;   
		foreach( keys( %{$row}) ) {
			#print $_;
			$row_data{ $_ }=$row->{$_};
		}
		push(@loop_data, \%row_data);
	}
	$template->param(USERS_LIST_LOOP => \@loop_data);
}
 
#print "<pre>".Dumper( $ENV{'SCRIPT_NAME'} )."</pre>";
$template->param( ACTION=>  "$ENV{'SCRIPT_NAME'}" );
$template->param( TITLE=>"Add / Edit / Delete users" );
$template->param( MESSAGES=> $message );

  # print the template output
print "Content-type: text/html\n\n" ;
print  $template->output;

 
db_disconnect( $dbh );

##############################################

sub Action {
	my $row;	

	if( $Param->{save} ) {
		unless( check_smnpworker_record()  ) {	
			return 0;
		}
		
		$row->{name}=$Param->{name} ;
		$row->{desc}=$Param->{desc} ;
		$row->{ip}=$Param->{ip} ;
		$row->{auth}=$Param->{auth} ;
		$row->{snmpuser}=$Param->{snmpuser} ;
		$row->{snmpap}=$Param->{snmpap} ;
		$row->{snmppk}=$Param->{snmppk} ;
		$row->{snmpr}=$Param->{snmpr} ;
		$row->{snmpt}=$Param->{snmpt} ;
		$row->{snmpapro}=$Param->{snmpapro} ;
		$row->{snmppro}=$Param->{snmppro} ;
		$row->{snmplevel}=$Param->{snmplevel} ;
		
		unless( $Param->{id} ) { # if we save the new record 					
			if ( InsertRecord ( $dbh, $Param->{id},  $table, $row ) ) {
				message2 ( "Record updated succsesfuly" );
				return 1;
			} else {
				return 0;
			}
		}	
					
		if ( UpdateRecord ( $dbh, $Param->{id}, $table, $row ) ) {
			message2 ( "Record updated succsesfuly" );
			return 1;
		} else {
			return 0;
		}
			
	}
	if( $Param->{new} ) {
			return 0;
	}
 
	if( $Param->{edit} ) {
			return 0;
	}	

	if( $Param->{del} ) {
		if ( DeleteRecord ( $dbh, $Param->{id},  $table ) ) {
			message2 ( "Record deleted succsesfuly" );
			return 1;
		} else {
			return 0;
		}
	}	
return 1;
}


sub check_smnpworker_record {
	my $retval=1;
	unless( CheckField ( $Param->{ name } ,'login', "Field 'name' ") ) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ desc } ,'text', "Field 'desc' ") ) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ ip } ,'ip', "Field 'ip' ")) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ auth } ,'boolean', "Field 'auth' ")) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmpuser } ,'login', "Field 'snmpuser' ")) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmpap } ,'password', "Field 'snmpap' ")) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmppk } ,'password', "Field 'snmppk' ") ){
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmpr } ,'int', "Field 'snmpr' ") ){
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmpt } ,'int', "Field 'snmpt' ")) {
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmpapro } ,'text', "Field 'snmpapro' ") ){
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmppro } ,'text', "Field 'snmppro' ") ){
			$retval=0 ;
	}
	unless( CheckField ( $Param->{ snmplevel } ,'text', "Field 'snmplevel' ") ){
			$retval=0 ;
	}
	return $retval;
}

