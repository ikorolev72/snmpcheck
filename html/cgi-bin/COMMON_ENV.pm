#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/cgi-bin/html'; } 

use DBI;
#use strict;
#use warnings;
use HTML::Template;
use DBI;
use CGI qw(param);
use Digest::SHA qw(sha1 sha1_hex );
use Data::Dumper;
use CGI::Cookie;
use CGI qw/:standard/;
use JSON;
use HTML::Entities;






$Paths->{HOME}='C:/GIT/snmpcheck/';
if( -d '/opt/snmpcheck' ) { 
	$Paths->{HOME}='/opt/snmpcheck/';
}	
$Paths->{TEMPLATE}="$Paths->{HOME}/data/templates";
$Paths->{DB}="$Paths->{HOME}/data/db";
$Paths->{LOG}="$Paths->{HOME}/data/log/snmpcheck.log";
$Paths->{WORKER_LOG}="$Paths->{HOME}/data/log/worker.log";  # after all tests it can be set to /dev/null 
#$Paths->{WORKER_LOG}="/dev/null";
$Paths->{GROUPS}="$Paths->{HOME}/data/iplist/groups/";
$Paths->{global.ipasolink}="$Paths->{HOME}/data/iplist/global.ipasolink";
$Paths->{WORKER_DIR}="$Paths->{HOME}/worker";
$Paths->{JSON}="$Paths->{HOME}/data/json";
$Paths->{OUTFILE}="$Paths->{HOME}/html/reports";
$Paths->{TASK_UPDATE}="$Paths->{HOME}/html/cgi-bin/task_update.pl";
$Paths->{PID_DIR}="$Paths->{HOME}/data/pid";

$Url->{OUTFILE}='/reports';



$Task->{1}='added';
$Task->{2}='started';
$Task->{3}='running';
$Task->{4}='finished';
$Task->{5}='failed';
$Task->{6}='canceled';


sub get_groups {
	my $html_dir=$Paths->{GROUPS};
	my @ls;
	opendir(DIR, $html_dir) || w2log( "can't opendir $html_dir: $!" );
		@ls = reverse sort grep { -f "$html_dir/$_" } readdir(DIR);
	closedir DIR;
	return @ls;
}


sub get_workers {
	my $html_dir=$Paths->{WORKER_DIR};
	my @ls;
	opendir(DIR, $html_dir) || w2log( "can't opendir $html_dir: $!" );
		@ls = reverse sort grep { -f "$html_dir/$_" } readdir(DIR);
	closedir DIR;
	return @ls;
}



sub update_tasks{
	my $dbh=shift;
	my $timeout=3600;	# set timeout to 1 hour for task. After this time without 
						# activities ( if not any any changes in ID.out.json files ) task mark as failed
	my $stmt ="SELECT * from tasks  where status IN (  ?, ? ); " ;  
	my $sth = $dbh->prepare( $stmt );
	my $mess='';
	unless ( $rv = $sth->execute( 2, 3 ) || $rv < 0 ) { # select only started or running tasks
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log( "Sql ($stmt) Someting wrong with database  : $DBI::errstr"  );
		return 0;
	}

	while (my $row = $sth->fetchrow_hashref) {
		my $json_file="$Paths->{JSON}/$row->{id}.out.json";		
		my $json_text=ReadFile( $json_file ) ;
			if( $json_text ) {
				my $nrow = JSON->new->utf8->decode($json_text) ;		
				if( $nrow->{sdt} == $row->{sdt} ) {
					next;
				}
				if( $row->{sdt} + $timeout < time() ) { #failed by timeout
					$mess="Task $row->{id} failed by timeout reason. Do not get any status update json messages during $timeout sec.";
					w2log( $mess );
					$nrow->{mess}=$mess ;
					$nrow->{sdt}=time() ;
					$nrow->{id}=$row->{id} ;
					$nrow->{status}=5; # failed				
				}
				update_task_status(  $dbh , $nrow );																		
			} else {
				my $nrow;
				if( $row->{sdt}+$timeout < time() ) { failed by timeout
					$mess="Task $row->{id} failed by timeout reason. Do not get any status update json messages during $timeout sec.";
					w2log( $mess );
					$nrow->{status}=5 ; # failed				
					$nrow->{mess}=$mess ;
					$nrow->{sdt}=time() ;
					$nrow->{id}=$row->{id} ;					
					# $nrow->{progress}=0 ;				
					update_task_status(  $dbh , $nrow );					
				}			
			}		
	}	
}




sub update_task_status {
	my $dbh=shift;
	my $row=shift;
	my $table='tasks';	
	return( UpdateRecord ( $dbh, $row->{id}, $table, $row ) )  ;	
}

sub db_connect {
	
my $dbfile = "$Paths->{DB}/sqlite.db"; 
my $dsn      = "dbi:SQLite:dbname=$dbfile";
my $user     = "";
my $password = "";

my $dbh = DBI->connect($dsn, $user, $password, {
   PrintError       => 0,
   RaiseError       => 1,
   AutoCommit       => 1,
   FetchHashKeyName => 'NAME_lc',
}) or w2log ( "Cannot connect to database : $DBI::errstr" );
return $dbh;
}

sub db_disconnect {
	my $dbh=shift;
	$dbh->disconnect;
}

sub get_date {
	my $time=shift() || time();
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
	$year+=1900;$mon++;
    return sprintf( "%s-%.2i-%.2i %.2i:%.2i:%.2i",$year,$mon,$mday,$hour,$min,$sec);
}	

sub generate_filename {
	my $time=shift() || time();
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
	$year+=1900;$mon++;
    return sprintf( "%s-%.2i-%.2i_%.2i-%.2i-%.2i",$year,$mon,$mday,$hour,$min,$sec);
}
	

sub w2log {
	my $msg=shift;
	open (LOG,">>$Paths->{LOG}") || print ("Can't open file $Paths->{LOG}. $msg") ;
	print LOG get_date()."\t$msg\n";
	#print STDERR $msg;
	close (LOG);
}

sub check_by_type{
	my $type=shift;
	
}


sub message2 {
	my $msg=shift;
	$message=$message."$msg<br>";
}

sub DeleteRecord {
	my $dbh=shift;
	my $id=shift;
	my $table=shift;
	my $stmt ="DELETE FROM $table WHERE id = ? ; ";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( $id ) ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Someting wrong with database  : $DBI::errstr" );
		return 0;
	}	
	return 1;
}

sub GetRecord {
	my $dbh=shift;
	my $id=shift;
	my $table=shift;
	#my $fields=shift || '*';
	my $stmt ="SELECT * from $table where id = ? ;";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( $id ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ) Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	return ( $sth->fetchrow_hashref );	
}

sub GetRecordByField {
	my $dbh=shift;
	my $table=shift;
	my $field=shift;
	my $value=shift;
	#my $fields=shift || '*';
	my $stmt ="SELECT * from $table where $field = ? ;";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( $value ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ) Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	return ( $sth->fetchrow_hashref );	
}


sub UpdateRecord {
	my $dbh=shift;
	my $id=shift;
	my $table=shift;
	my $row=shift;
	my @Val=();
	my @Col=();
	foreach $key ( keys %{ $row }) {
		push ( @Col," $key = ? " ) ;
		push ( @Val, $row->{$key} ) ;
	}
		push ( @Val, $id ) ;
	my $stmt ="UPDATE $table set " . join(',',@Col ). " where id=?  ";
	#w2log( $stmt,@Col );
	#unless ( $dbh->do( $stmt,  @Val ) ) {
	#	message2 ( "Someting wrong with database  : $DBI::errstr" );
	#	w2log ( "Sql( $stmt )Someting wrong with database  : $DBI::errstr" );
	#	return 0;
	#}
	;
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( @Val ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt )Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	return ( 1 );	
}

sub InsertRecord {
	my $dbh=shift;
	my $id=shift; # do not used
	my $table=shift;
	my $row=shift;
	my @F;
	my @V;
	my @Q;
	foreach( keys %{ $row }) {
		push ( @F, $_ );
		push (@V , $row->{$_} );
		push ( @Q, '?');
	}
	my $stmt ="INSERT into $table ( ". join(',', @F). ") values ( ". join(',', @Q). " ) ;";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( @V )  || $rv < 0  ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ). Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	return ( 1 );	
}



sub GetNextSequence {
	my $dbh=shift;
	my $table='sequ';
	my $stmt ="update $table set id=id+1; ";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ) Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	$stmt ="select id from $table";
	$sth = $dbh->prepare( $stmt );
	unless ( $rv = $sth->execute(  ) || $rv < 0 ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ) Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	my $row=$sth->fetchrow_hashref;
	return ( $row->{id} );	
}



sub CheckField {
	my $f=shift;
	my $type=shift;
	my $prefix=shift; 
	my $constrains;
	my $retval=1;
		# Sample of constrains
		#$constrains->{login}->{max}=50;
		#$constrains->{login}->{min}=4;
		#$constrains->{login}->{no_spaces}=1;
		#$constrains->{login}->{first_char_letter}=1;
		#$constrains->{login}->{no_special_chars}=1;
		#$constrains->{login}->{no_angle_brackets}=1;
		#$constrains->{login}->{no_quotes}=1;

		$constrains->{int}->{numeric}=1;
		$constrains->{int}->{max}=20;
		$constrains->{int}->{min}=1;
		$constrains->{int}->{no_spaces}=1;
		#$constrains->{int}->{no_special_chars}=1;

		$constrains->{ip_op_empty}->{ip_op_empty}=1;
		$constrains->{ip_op_empty}->{max}=15;
		$constrains->{ip_op_empty}->{min}=0;
		$constrains->{ip_op_empty}->{no_spaces}=1;

		$constrains->{ip}->{ip}=1;
		$constrains->{ip}->{max}=15;
		$constrains->{ip}->{min}=7;
		$constrains->{ip}->{no_spaces}=1;

		$constrains->{filename}->{max}=254;
		$constrains->{filename}->{min}=1;
		$constrains->{filename}->{no_quotes}=1;
		$constrains->{filename}->{no_special_chars}=1;
		$constrains->{filename}->{no_spaces}=1;
		
		
		$constrains->{login}->{max}=50;
		$constrains->{login}->{min}=4;
		$constrains->{login}->{no_spaces}=1;
		$constrains->{login}->{first_char_letter}=1;
		$constrains->{login}->{no_special_chars}=1;

		$constrains->{text}->{max}=254;
		$constrains->{text}->{min}=0;
		$constrains->{text}->{no_angle_brackets}=1;

		$constrains->{text_no_empty}->{max}=254;
		$constrains->{text_no_empty}->{min}=1;
		
		$constrains->{desc}->{max}=254;
		$constrains->{desc}->{min}=1;
		#$constrains->{desc}->{no_special_chars}=1;
		
		$constrains->{html}->{max}=254;
		$constrains->{html}->{min}=0;
						
		$constrains->{password}->{max}=20;
		$constrains->{password}->{min}=6;
		$constrains->{password}->{no_spaces}=1;

		$constrains->{boolean}->{boolean}=1;
		$constrains->{boolean}->{max}=1;
		$constrains->{boolean}->{min}=0;

		
		
	unless( $constrains->{$type} ) {
		return 0;
	}


	foreach $key ( keys ( %{ $constrains->{$type} } ) ) {
		#print "# $f # $type -";
		if( $key eq 'boolean' ) {
			unless( $f=~/^[0|1]*$/ ) {
				message2( "$prefix must be 1 or 0" );
				$retval=0;
			}
		}
		if( $key eq 'numeric' ) {
			unless( $f=~/^\d+$/ ) {
				message2( "$prefix must be numeric integer" );
				$retval=0;
			}
		}
		if( $key eq 'ip_or_empty' ) {
			if( $f ne '' ) {
			unless( $f=~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ ) {
				message2( "$prefix must be empty or IP address " );
				$retval=0;
			}
			}
		}
		if( $key eq 'ip' ) {
			unless( $f=~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ ) {
				message2( "$prefix must be IP address " );
				$retval=0;
			}
		}
		if( $key eq 'max' ) {
			if( length( $f ) > $constrains->{$type}->{max} ) {
				message2( "$prefix must be less than  $constrains->{$type}->{max} letter(s)" );
				$retval=0;
			}
		}
		if( $key eq 'min' ) {
			if( length( $f ) < $constrains->{$type}->{min} ) {
				message2( "$prefix must be greater or equiv than $constrains->{$type}->{min} letter(s)" );
				$retval=0;
			}
		}
		if( $key eq 'no_spaces' ) {
			if( $f=~/\s/ ) {
				message2( "$prefix must contain not spaces" );
				$retval=0;
			}
		}
		if( $key eq 'first_char_letter' ) {
			unless( $f=~/^[A-Za-z]\w+$/ ) {
				#print "# $f # $type -";
				message2( "$prefix must begin from letter" );
				$retval=0;
			}
		}
		if( $key eq 'no_special_chars' ) {
			unless(  $f=~/^[\w\.\s-]*$/ ) {
				message2( "$prefix "."must have not special chars" );
				$retval=0;
			}
		}
		if( $key eq 'no_angle_brackets' ) {
			if(  $f=~/\</  ||  $f=~/\>/ ) {
				message2( "$prefix must have not angle brackets" );
				$retval=0;
			}
		}
		if( $key eq 'no_quotes' ) {
			if(  $f=~/\'/  ||  $f=~/\"/ ) {
				message2( "$prefix must have not any quotes" );
				$retval=0;
			}
		}
	}		
	return $retval;	
}

sub ReadFile {
	my $filename=shift;
	my $ret="";
	open (IN,"$filename") || w2log("Can't open file $filename") ;
		while (<IN>) { $ret.=$_; }
	close (IN);
	return $ret;
}	

sub WriteFile {
	my $filename=shift;
	my $body=shift;
	unless( open (OUT,">$filename")) { w2log("Can't open file $filename" ) ;return 0; }
	print OUT $body;
	close (OUT);
	return 1;
}	



1;

