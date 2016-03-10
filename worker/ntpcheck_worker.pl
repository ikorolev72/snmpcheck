#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin'; } 
use COMMON_ENV;

use Getopt::Long;



GetOptions (
        'json=s' => \$json_file,
        "help|h|?"  => \$help ) or show_help();



unless( -f $json_file ) {
	show_help();
	exit 1;
}


$json_text=ReadFile( $json_file );

$Param =JSON->new->utf8->decode($json_text);
$ip_param=JSON->new->utf8->decode($Param->{param});

$outfile=$ip_param->{sname}."_".generate_filename()."_$Param->{id}_log.csv";
AppendFile( "$Paths->{OUTFILE_DIR}/$outfile", "Unix time now\n");


my $json_out="$Paths->{JSON}/$Param->{id}.out.json";
my $row;
my $timenow=time();

my @IPs=get_ip_list( $ip_param );
$count_max=$#IPs;

foreach $count ( 0..$count_max )  {
	if( time() - $timenow  > 15 ) {
		AppendFile( "$Paths->{OUTFILE_DIR}/$outfile", $IPs[$count]."\n");
		$timenow=time();
		$row->{sdt}=time();
		$row->{status}=3; # running
		$row->{id}=$Param->{id};
		$row->{mess}='Task running. All ok.';
		$row->{progress}=int( $count*100/$count_max ) ;	
		unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
				w2log ("Cannot write file $json_file: $!");
		}
	}
	sleep 10;
	$|=1;
	print $count;
}

$row->{sdt}=time();
$row->{status}=4; # finished
$row->{id}=$Param->{id};
$row->{mess}='Finished successfully';
$row->{progress}=100 ;
$row->{outfile}=$outfile;

unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
	w2log ("Cannot write file $json_file: $!");
}

exit 0;
 


sub get_ip_list {
	my $ip_param=shift;
	my $Cfg=ReadConfig();
	my @IPs=();
	#print Dumper( $Cfg );
	#print Dumper( $ip_param );

	if( $Cfg->{iplistdb} eq 'ms5000' ) {
		# not yet realised
	} else {
		# stadalone configuration
		if( $ip_param->{ip} ) {		
			return ( $ip_param->{ip} ) ;
		}
		if( $ip_param->{group} ) {
			if( -f "$Paths->{GROUPS}/$ip_param->{group}" ) {							
				@IPs=split( /\s/, ReadFile( "$Paths->{GROUPS}/$ip_param->{group}" ) );
				return @IPs;
			}
		}
		if( $ip_param->{all_ipasolink} ) {
			if( -f $Paths->{global.ipasolink} ) {
				@IPs=split( /\s/, ReadFile( $Paths->{global.ipasolink} ));
				return @IPs;				
			}
		}
	}
	return undef;
}
 
  
sub show_help {
print STDOUT "Usage: $0  --json='JSON_FILE' [ --help ]
Sample:
$0  --json='/tmp/123.json'
";
}