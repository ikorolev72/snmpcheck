#!/usr/bin/perl

use COMMON_ENV;
use Digest::SHA qw(sha1 sha1_hex );
use Data::Dumper;

$dbh=db_connect();

$stmt =" CREATE TABLE IF NOT EXISTS `Users` (  id INTEGER PRIMARY KEY AUTOINCREMENT ,     login TEXT,    name TEXT,   password TEXT ) ; ";
#$stmt =" CREATE TABLE IF NOT EXISTS `secrets` (  id INTEGER ,     login TEXT,    secret TEXT) ; ";
do_sql( $stmt );

$pass=sha1_hex( 'support123' );
$stmt =" insert into  users (    login ,    name ,   password  ) values ( 'support' , 'Support user' ,  '$pass' ) ; ";
do_sql( $stmt );

#$stmt ="SELECT * FROM 'users'; ";
#$stmt ="SELECT * FROM SQLITE_SEQUENCE WHERE name='users'; ";
#do_sql( $stmt );
#$rec=$sth->fetchrow_hashref;
#print Dumper( $rec);


sub do_sql {
	$sth = $dbh->prepare( $stmt );
	$rv = $sth->execute(  ) or die ( "Cannot connect to database : $DBI::errstr" );
	if($rv < 0){
		die ( "Cannot connect to database : $DBI::errstr" );
	}
}
