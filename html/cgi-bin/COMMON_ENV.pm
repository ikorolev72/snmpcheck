#!/usr/bin/perl
# korolev-ia [at] yandex.ru


BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/home/admin/lib' ,'/home/admin/lib'; } 
use DBI;

$Paths->{HOME}='C:/GIT/snmpcheck/';
#$Paths->{HOME}='/var/www';
$Paths->{TEMPLATE}="$Paths->{HOME}/data/templates";
$Paths->{DB}="$Paths->{HOME}/data/db";
$Paths->{LOG}="$Paths->{HOME}/data/log/snmpcheck.log";


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
	my @Val,@Col;

	foreach $key ( keys %{ $row }) {
		push ( @Col," $key = ? " ) ;
		push ( @Val, $row->{$key} ) ;
	}
		push ( @Val, $id ) ;
	my $stmt ="UPDATE $table set " . join(',',@Col ). " where id=?  ";
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
	my $stmt ="INSERT into users ( ". join(',', @F). ") values ( ". join(',', @Q). " ) ;";
	my $sth = $dbh->prepare( $stmt );
	my $rv;
	unless ( $rv = $sth->execute( @V )  || $rv < 0  ) {
		message2 ( "Someting wrong with database  : $DBI::errstr" );
		w2log ( "Sql( $stmt ). Someting wrong with database  : $DBI::errstr" );
		return 0;
	}
	return ( 1 );	
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


		$constrains->{login}->{max}=50;
		$constrains->{login}->{min}=4;
		$constrains->{login}->{no_spaces}=1;
		$constrains->{login}->{first_char_letter}=1;
		$constrains->{login}->{no_special_chars}=1;

		$constrains->{text}->{max}=254;
		$constrains->{text}->{min}=0;
		$constrains->{text}->{no_angle_brackets}=1;

		$constrains->{html}->{max}=254;
		$constrains->{html}->{min}=0;
						
		$constrains->{password}->{max}=20;
		$constrains->{password}->{min}=6;
		$constrains->{password}->{no_spaces}=1;

	unless( $constrains->{$type} ) {
		return 0;
	}


	foreach $key ( keys ( %{ $constrains->{$type} } ) ) {
		#print "# $f # $type -";
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
			if(  $f=~/^\w$/ ) {
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




1;

