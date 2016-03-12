#!/usr/bin/perl

BEGIN{ unshift @INC, '$ENV{SITE_ROOT}/cgi-bin' ,'C:\GIT\snmpcheck\html\cgi-bin', '/opt/snmpcheck/html/cgi-bin','/home/nems/client_persist/htdocs/bulktool3/html/cgi-bin', '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/' , '/home/nems/client_persist/htdocs/bulktool3/lib/lib/perl5/x86_64-linux-thread-multi/'; } 
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
my $Cfg=ReadConfig();


$outfile=$ip_param->{sname}."_".generate_filename()."_$Param->{id}_log.csv";

my $json_out="$Paths->{JSON}/$Param->{id}.out.json";
my $row;
my $timenow=time();

my @IPs=get_ip_list( $ip_param );
$count_max=$#IPs || 1 ;
my $count=0;


######### header of worker output table 
WriteFile( "$Paths->{OUTFILE_DIR}/$outfile", "NE name,NE IP,Status,NTP server status,NTP server,Reference server,Stratum,t,When,Poll,Reach,Delay,Offset,Jitter\n" ) ;

foreach $IP( @IPs ) {
#######################################
########## we say to task manager thats task runing
	if( time() - $timenow  > 15 || 0==$count ) {
		sleep 1;
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
	$count++;

#######################################


#######################################
########### worker code
	my $code, $result_of_exec, $ne_name, $ntpstat;
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.11.1 2>/dev/null" ;
	#w2log( $code);
	$result_of_exec=qx( $code );
	next unless( $result_of_exec );
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.3.1 2>/dev/null | cut -d '\"' -f 2 " ;
	$ne_name=qx( $code ) ;
	chomp ( $ne_name );
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.6.1.1.1.3.1 2>/dev/null | cut -d '\"' -f 2-1000 | tail -2 | head -1 ";	
	$ntpstat= qx( $code ) ;
	chomp ( $ntpstat );
	
	
	my $ntps='NOT CONFIGURED';
	my $ntpok=0;
	my $ntpentry=0;
	my $ntpstatus='';

	if( $ntpstat =~ /^./ ) {
		$ntpstatus='Configured';
		$ntpentry=1;
	}

	if( $ntpstat =~ /^\+/ ) {
		$ntpstatus='Candidate';
		$ntpentry=1;
		$ntpok=1;
	}
	if( $ntpstat =~ /^\*/ ) {
		$ntpstatus='Selected';
		$ntpentry=1;
		$ntpok=1;
	}
	$ntpstat=~s/^[\+\*]//g;

	
	my ( $ntpserver, $ntpserverref, $stratum, $t, $when, $poll, $reach, $delay, $offset, $jitter )= split( /\s/, $ntpstat );


	if ( $ntpentry == 0  ) {
		AppendFile( $outfile, "$ne_name,$IP,NOT CONFIGURED") ;
	} else {
		if ( $ntpok == 0 ) {
			$ntps='NOT WORKING';
		} else {
			$ntps='WORKING';
		}
	}

	AppendFile( "$Paths->{OUTFILE_DIR}/$outfile", "$ne_name,$IP,$ntps,$ntpstatus,$ntpserver,$ntpserverref,$stratum,$t,$when,$poll,$reach,$delay,$offset,$jitter\n" ) ;

########### end of worker code
#######################################

}


#######################################
########## we say to task manager thats task finished

$row->{sdt}=time();
$row->{status}=4; # finished
$row->{id}=$Param->{id};
$row->{mess}='Finished successfully';
$row->{progress}=100 ;
$row->{outfile}=$outfile;

unless( WriteFile( $json_out, JSON->new->utf8->encode($row) ) ){
	w2log ("Cannot write file $json_file: $!");
}
#######################################

exit 0;
 


 
  
sub show_help {
print STDOUT "Usage: $0  --json='JSON_FILE' [ --help ]
Sample:
$0  --json='/tmp/123.json'
";
}