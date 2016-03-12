

WriteFile( $outfile, "NE name,NE IP,Status,NTP server status,NTP server,Reference server,Stratum,t,When,Poll,Reach,Delay,Offset,Jitter\n" ) ;

foreach $IP( @IPs ) {
	my $code, $result_of_exec, $ne_name, $ntpstat;
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.11.1 2>/dev/null" ;
	$result_of_exec=qx( $code );
	next uness( $result_of_exec );
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.3.1 2>/dev/null | cut -d '\"' -f 2 " ;
	$ne_name=qx( $code );
	$code="snmpget -v 3 -a $Cfg->{snmpapro} -u $Cfg->{snmpuser} -A $Cfg->{snmpap} -x $Cfg->{snmppro} -X $Cfg->{snmppk} -l $Cfg->{snmplevel} -r $Cfg->{snmpr} -t $Cfg->{snmpt} -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.6.1.1.1.3.1 2>/dev/null | cut -d '\"' -f 2-1000 | tail -2 | head -1 ";	
	$ntpstat=qx( $code );
	
	
	my $ntps='NOT CONFIGURED'
	my $ntpok=0
	my $ntpentry=0
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
		AppenFile( $outfile, "$ne_name,$IP,NOT CONFIGURED") ;
	} else {
		if ( $ntpok == 0 ) {
			$ntps='NOT WORKING'
		} else {
			$ntps='WORKING'
		}
	}

	AppenFile( $outfile, "$ne_name,$IP,$ntps,$ntpstatus,$ntpserver,$ntpserverref,$stratum,$t,$when,$poll,$reach,$delay,$offset,$jitter" ) ;

}


