#!/bin/sh
if [ -d '/usr/local/mitigator' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/mitigator
fi
clear
echo; echo 'Installing SP-Mitigator v0.1'; echo
echo; echo -n 'Downloading source files...'
wget --no-check-certificate -q -O /usr/local/mitigator/mitigate.conf http://serverpolice.org/scripts/mitigator/mitigate.conf
echo -n '.'
wget --no-check-certificate -q -O /usr/local/mitigator/LICENSE http://serverpolice.org/scripts/mitigator/LICENSE
echo -n '.'
wget --no-check-certificate -q -O /usr/local/mitigator/ignore.ip.list http://serverpolice.org/scripts/mitigator/ignore.ip.list
echo -n '.'
wget --no-check-certificate -q -O /usr/local/mitigator/mitigate.sh http://serverpolice.org/scripts/mitigator/mitigate.sh
chmod 0755 /usr/local/mitigator/mitigate.sh
cp -s /usr/local/mitigator/mitigate.sh /usr/local/sbin/mitigator
echo '...done'

echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/mitigator/mitigate.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/mitigator/mitigate.conf'
echo 'For further help and support, Please visit : https://serverpolice.org'
echo
cat /usr/local/mitigator/LICENSE | less
