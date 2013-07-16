#!/bin/sh
##############################################################################
# SP-Mitigator (Based on MediaLayer - Deflate Application)                   #
##############################################################################
#                                                                            #
#  (C) 2013 , ServerPolice Tech.                                             #
#                                                                            #
# This program is distributed under the "MIT License" Agreement              #
#                                                                            #
# The LICENSE file is located in the same directory as this program. Please  #
#  read the LICENSE file before you make copies or distribute this program   #
##############################################################################
load_conf()
{
	CONF="/usr/local/mitigator/mitigate.conf"
	if [ -f "$CONF" ] && [ ! "$CONF" ==	"" ]; then
		source $CONF
	else
		head
		echo "Configuration File not found."
		exit 1
	fi
}

head()
{

echo "##############################################################################"
echo "#                             SP-Mitigator                                   #"
echo "##############################################################################"
echo "#                                                                            #"
echo "#  (C)-2013 , ServerPolice Tech.     <http://serverpolice.org>               #"
echo "#                                                                            #"
echo "# This program is distributed under the 'MIT License' Agreement              #"
echo "#                                                                            #"
echo "# The LICENSE file is located in the same directory as this program. Please  #"
echo "#  read the LICENSE file before you make copies or distribute this program   #"
echo "##############################################################################"
	echo
}

showhelp()
{
	head
	echo 'Usage: mitigate.sh [OPTIONS] [N]'
	echo 'N : number of tcp/udp	connections (default 150)'
	echo 'OPTIONS:'
	echo '-h | --help: Show	this help screen'
	echo '-c | --cron: Create cron job to run this script regularly (default 1 mins)'
	echo '-k | --kill: Block the offending ip making more than N connections'
}

unbanip()
{
	UNBAN_SCRIPT=`mktemp /tmp/unban.XXXXXXXX`
	TMP_FILE=`mktemp /tmp/unban.XXXXXXXX`
	UNBAN_IP_LIST=`mktemp /tmp/unban.XXXXXXXX`
	echo '#!/bin/sh' > $UNBAN_SCRIPT
	echo "sleep $BAN_PERIOD" >> $UNBAN_SCRIPT
	while read line; do
			## Offender Ban Time Over, Removing from Null-Route ##
			echo "route delete $line" >> $UNBAN_SCRIPT
			echo $line >> $UNBAN_IP_LIST
		done < $BANNED_IP_LIST
	echo "grep -v --file=$UNBAN_IP_LIST $IGNORE_IP_LIST > $TMP_FILE" >> $UNBAN_SCRIPT
	echo "mv $TMP_FILE $IGNORE_IP_LIST" >> $UNBAN_SCRIPT
	echo "rm -f $UNBAN_SCRIPT" >> $UNBAN_SCRIPT
	echo "rm -f $UNBAN_IP_LIST" >> $UNBAN_SCRIPT
	echo "rm -f $TMP_FILE" >> $UNBAN_SCRIPT
	. $UNBAN_SCRIPT &
}

add_to_cron()
{
	rm -f $CRON
	sleep 1
	service crond restart
	sleep 1
	echo "SHELL=/bin/sh" > $CRON
	if [ $FREQ -le 2 ]; then
		echo "0-59/$FREQ * * * * root /usr/local/mitigator/mitigate.sh >/dev/null 2>&1" >> $CRON
	else
		let "START_MINUTE = $RANDOM % ($FREQ - 1)"
		let "START_MINUTE = $START_MINUTE + 1"
		let "END_MINUTE = 60 - $FREQ + $START_MINUTE"
		echo "$START_MINUTE-$END_MINUTE/$FREQ * * * * root /usr/local/mitigator/mitigate.sh >/dev/null 2>&1" >> $CRON
	fi
	service crond restart
}


load_conf
while [ $1 ]; do
	case $1 in
		'-h' | '--help' | '?' )
			showhelp
			exit
			;;
		'--cron' | '-c' )
			add_to_cron
			exit
			;;
		'--kill' | '-k' )
			KILL=1
			;;
		 *[0-9]* )
			NO_OF_CONNECTIONS=$1
			;;
		* )
			showhelp
			exit
			;;
	esac
	shift
done

TMP_PREFIX='/tmp/mitigator'
TMP_FILE="mktemp $TMP_PREFIX.XXXXXXXX"
BANNED_IP_MAIL=`$TMP_FILE`
BANNED_IP_LIST=`$TMP_FILE`
echo "Banned the following ip addresses on `date`" > $BANNED_IP_MAIL
echo >>	$BANNED_IP_MAIL
BAD_IP_LIST=`$TMP_FILE`
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr > $BAD_IP_LIST
cat $BAD_IP_LIST
if [ $KILL -eq 1 ]; then
	IP_BAN_NOW=0
	while read line; do
		CURR_LINE_CONN=$(echo $line | cut -d" " -f1)
		CURR_LINE_IP=$(echo $line | cut -d" " -f2)
		if [ $CURR_LINE_CONN -lt $NO_OF_CONNECTIONS ]; then
			break
		fi
		IGNORE_BAN=`grep -c $CURR_LINE_IP $IGNORE_IP_LIST`
		if [ $IGNORE_BAN -ge 1 ]; then
			continue
		fi
		IP_BAN_NOW=1
		echo "$CURR_LINE_IP with $CURR_LINE_CONN connections" >> $BANNED_IP_MAIL
		echo $CURR_LINE_IP >> $BANNED_IP_LIST
		echo $CURR_LINE_IP >> $IGNORE_IP_LIST
		## Offeneder !!, Add to Null-Route ##
		route add -host $CURR_LINE_IP reject
	done < $BAD_IP_LIST
	if [ $IP_BAN_NOW -eq 1 ]; then
		dt=`date`
		if [ $EMAIL_TO != "" ]; then
			cat $BANNED_IP_MAIL | mail -s "IP addresses banned on $dt" $EMAIL_TO
		fi
		unbanip
	fi
fi
rm -f $TMP_PREFIX.*
