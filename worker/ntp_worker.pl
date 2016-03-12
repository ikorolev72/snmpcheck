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
WriteFile( "$Paths->{OUTFILE_DIR}/$outfile", "NE name,NE IP,Main operation,Polling period,Result\n" ) ;

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
	my $code, $result_of_exec, $ne_name, $ntpstat, $error;
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.3.1 2>/dev/null | cut -d '\"' -f 2 " ;
	$ne_name=qx( $code ) ;
	chomp ( $ne_name );
	unless( $ne_name ) {
		AppendFile( $outfile, "$ne_name,$IP,inaccessible,,FATAL\n" );
		next;
	} 
	
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r 2 -t 5 -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.1.1.3.1 i 1 2>/dev/null | cut -d ' ' -f 2";	
	$result_of_exec=qx( $code );
	chomp( $result_of_exec );
	if( $result_of_exec eq '1' ) {
		AppendFile( $outfile, "$ne_name,$IP,NTP service stop,,COMPLETED\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,NTP service stop,,ERROR\n" );
		$error=1;
	}
	my $result1,$result2,$result3,$result4;
	my $pollres1,$pollres2,$pollres3,$pollres4;

	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.3.1 a $ip_param->{ntp1} 2>/dev/null | cut -b 11-50";
	$result1=qx( $code );
	chomp( $result1 );
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.5.1 i $ip_param->{ntp1_poll} 2>/dev/null | cut -d ' ' -f 2";
	$pollres1=qx( $code );
	chomp( $pollres1 );
	if( ($result1 eq $ip_param->{ntp1})  && ($pollres1 eq  $ip_param->{ntp1_poll}) ) {
		AppendFile( $outfile, "$ne_name,$IP,ntp server1 address is set to '$ip_param->{ntp1}',ntp server1 polling period is set to '$ip_param->{ntp1_poll}',COMPLETED'\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,ntp server1 address or polling period set,,ERROR\n" );
		$error=1;
	}


	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.3.2 a $ip_param->{ntp2} 2>/dev/null | cut -b 11-50";
	$result2=qx( $code );
	chomp( $result2 );
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.5.2 i $ip_param->{ntp2_poll} 2>/dev/null | cut -d ' ' -f 2";
	$pollres2=qx( $code );
	chomp( $pollres2 );
	if( ($result2 eq $ip_param->{ntp2})  && ($pollres2 eq  $ip_param->{ntp2_poll}) ) {
		AppendFile( $outfile, "$ne_name,$IP,ntp server2 address is set to '$ip_param->{ntp2}',ntp server1 polling period is set to '$ip_param->{ntp2_poll}',COMPLETED'\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,ntp server2 address or polling period set,,ERROR\n" );
		$error=1;
	}	
	
	
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.3.3 a $ip_param->{ntp3} 2>/dev/null | cut -b 11-50";
	$result3=qx( $code );
	chomp( $result3 );
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.5.3 i $ip_param->{ntp3_poll} 2>/dev/null | cut -d ' ' -f 2";
	$pollres3=qx( $code );
	chomp( $pollres3 );
	if( ($result3 eq $ip_param->{ntp3})  && ($pollres3 eq  $ip_param->{ntp3_poll}) ) {
		AppendFile( $outfile, "$ne_name,$IP,ntp server3 address is set to '$ip_param->{ntp3}',ntp server1 polling period is set to '$ip_param->{ntp3_poll}',COMPLETED'\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,ntp server3 address or polling period set,,ERROR\n" );
		$error=1;
	}	
	
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.3.4 a $ip_param->{ntp4} 2>/dev/null | cut -b 11-50";
	$result4=qx( $code );
	chomp( $result4 );
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.2.1.5.4 i $ip_param->{ntp4_poll} 2>/dev/null | cut -d ' ' -f 2";
	$pollres4=qx( $code );
	chomp( $pollres4 );
	if( ($result4 eq $ip_param->{ntp4})  && ($pollres4 eq  $ip_param->{ntp4_poll}) ) {
		AppendFile( $outfile, "$ne_name,$IP,ntp server4 address is set to '$ip_param->{ntp4}',ntp server1 polling period is set to '$ip_param->{ntp4_poll}',COMPLETED'\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,ntp server4 address or polling period set,,ERROR\n" );
		$error=1;
	}	
	

	
	$code="snmpset -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r 2 -t 10 -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.3.4.1.1.3.1 i 2 2>/dev/null | cut -d ' ' -f 2";	
	$result_of_exec=qx( $code );
	chomp( $result_of_exec );
	if( 2==$result_of_exec  ) {
		AppendFile( $outfile, "$ne_name,$IP,NTP service start,,COMPLETED\n" );
	} else {
		AppendFile( $outfile, "$ne_name,$IP,NTP service start,,ERROR\n" );
		$error=1;
	}
	
	#if( $error ){
	#	print "$ne_name '$IP' error\n";
	#} else {
	#	print "$ne_name '$IP' passed\n";
	#}
	

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