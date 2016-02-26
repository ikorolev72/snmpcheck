#!/usr/bin/perl

use COMMON_ENV;
use Digest::SHA qw(sha1 sha1_hex );
use Data::Dumper;

$dbh=db_connect();

$stmt =" CREATE TABLE IF NOT EXISTS `Users` (  id INTEGER PRIMARY KEY AUTOINCREMENT ,     login TEXT,    name TEXT,   password TEXT ) ; ";
do_sql( $stmt );
$pass=sha1_hex( 'support123' );
$stmt =" insert into  users (    login ,    name ,   password  ) values ( 'support' , 'Support user' ,  '$pass' ) ; ";
#do_sql( $stmt );
#$stmt =" CREATE TABLE IF NOT EXISTS `secrets` (  id INTEGER ,     login TEXT,    secret TEXT) ; ";

#$stmt ="DROP TABLE snmpworker; ";
#do_sql( $stmt );
#exit;

$stmt =" CREATE TABLE IF NOT EXISTS snmpworker (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sname  		TEXT,
	desc  		TEXT,
	ip		text,
	auth		BOOLEAN,
	snmpuser	text,
	snmpap		text,	
	snmppk		text,
	snmpr		INTEGER,	
	snmpt		INTEGER,
	snmpapro	text,	
	snmppro		text,	
	snmplevel	text	
);  ";


do_sql( $stmt );

$stmt =" insert into  snmpworker (    
	sname  	,
	desc  	,
	ip	,
	auth	,
	snmpuser,
	snmpap	,
	snmppk	,
	snmpr	,
	snmpt	,
	snmpapro,
	snmppro	,
	snmplevel
) 
values (  
	'ntpcheck'  	,
	'Ntpcheck'  	,
	'0.0.0.0'	,
	1	,
	'Admin',
	'password01'	,
	'password02'	,
	5	,
	1	,
	'MD5',
	'DES'	,
	'Authpriv'
) ; ";


do_sql( $stmt );
exit;
#$rec=$sth->fetchrow_hashref;
#print Dumper( $rec);


sub do_sql {
	$sth = $dbh->prepare( $stmt );
	$rv = $sth->execute(  ) or die ( "Cannot connect to database : $DBI::errstr" );
	if($rv < 0){
		die ( "Cannot connect to database : $DBI::errstr" );
	}
}
