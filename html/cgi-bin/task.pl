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


