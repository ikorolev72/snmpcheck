#!/bin/bash

read_param() {
shift
shift
shift
for var in "$@"
do
	export "$var"
done
}

CONFIG=$1
IP=$2
logfile=$3

if [ -z ${CONFIG+x} ]; then 
	exit 2
fi
if [ -z ${IP+x} ]; then 
	exit 2
fi
if [ -z ${logfile+x} ]; then 
	exit 2
fi



. $CONFIG

read_param "$@"

tmp=/tmp/worker.$$
mkdir $tmp
cd $tmp
error=0

###########

vlanlist="$tmp/vlanlist.$$"
portlist="$tmp/portlist.$$"


if [ $allvlan'a' == 'ona' ]
then
vlanidstart=1
vlanidstop=4094
else
if [ $vlanidstop'a' == 'a' ]
then
vlanidstop=$vlanidstart
fi
fi

accessible=`snmpget -v 3 -a $snmpapro -u $snmpuser -A $snmpap -x $snmppro -X $snmppk -l $snmplevel -r 2 -t 3 -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.11.1 2>/dev/null`
lengthaccessible=${#accessible}
if (($lengthaccessible != 0))
then
ne_name=`snmpget -v 3 -a $snmpapro -u $snmpuser -A $snmpap -x $snmppro -X $snmppk -l $snmplevel -r $snmpr -t $snmpt -Ov $IP .1.3.6.1.4.1.119.2.3.69.5.1.1.1.3.1 2>/dev/null | cut -d '"' -f 2`
snmpwalk -v 3 -a $snmpapro -u $snmpuser -A $snmpap -x $snmppro -X $snmppk -l $snmplevel -r $snmpr -t $snmpt -On $IP .1.3.6.1.4.1.119.2.3.69.501.5.20.5.1.3 > $vlanlist

if [ $portassignment'a' == 'ona' ]
then
snmpwalk -v 3 -a $snmpapro -u $snmpuser -A $snmpap -x $snmppro -X $snmppk -l $snmplevel -r $snmpr -t $snmpt -On $IP .1.3.6.1.4.1.119.2.3.69.501.5.20.2.1.4 > $portlist
fi

while read vlanline
do
vlanid=`echo $vlanline | cut -d '.' -f 18 | cut -d ' ' -f 1`

if (( $vlanid >= $vlanidstart )) && (( $vlanid <= $vlanidstop ))
then

vlanname=`echo $vlanline | cut -d '"' -f 2`
if [ $portassignment'a' == 'ona' ]
then
assigned=0

while read portline
do
portvid=`echo $portline | cut -d '.' -f 19 | cut -d ' ' -f 1`
if [ $portvid'a' == $vlanid'a' ]
then
assigned=1
portid=`echo $portline | cut -d '.' -f 18`
slot=$(($portid/8388608-1))
port=$((($portid-($slot+1)*8388608)/65536))

if (( $slot == -1 ))
then
if (( $port <=64 ))
then
slot='LAG'
else
slot='RTA'
port=$(( port - 64 ))
fi
fi

mode=`echo $portline | cut -d ' ' -f 4`
if (( $mode == 1 ))
then
modestr='Access'
fi
if (( $mode == 2 ))
then
modestr='Tunnel'
fi
if (( $mode == 3 ))
then
modestr='Trunk'
fi
echo $ne_name','$IP','$vlanid','$vlanname',Assigned,'$slot','$port','$modestr',COMPLETED' >> $logfile
fi

done < $portlist

if (( $assigned == 0 ))
then
echo $ne_name','$IP','$vlanid','$vlanname',Unassigned,,,,COMPLETED' >> $logfile
fi
else
echo $ne_name','$IP','$vlanid','$vlanname',COMPLETED' >> $logfile
fi

fi
done < $vlanlist

else
echo ','$IP',,,,FATAL,,,,FATAL' >> $logfile
fi

####
rm -rf $tmp
exit $error