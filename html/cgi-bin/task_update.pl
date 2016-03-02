#!/usr/bin/perl

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


$query = new CGI;
foreach ( $query->param() ) { $Param->{$_}=$query->param($_); }

exit(1) unless ( $Param->{id} ) ; # task id
exit(2) unless ( $Param->{key} ) ; # magick key
# status
exit(3) unless ( $Param->{status} ) ; # status
# 1 - starting
# 2 - running
# 3 - finished
######   to future
# 4 - killed
# 5 - suspended
# 6 - stopped

if( $Param->{status} == 2 ) {
	exit(4) unless ( $Param->{all} ) ; 
	exit(4) unless ( $Param->{all} ) ; 
	
}

if( $Param->{status} == 1 ) {
	
}

if( $Param->{status} == 3 ) {
	
}

