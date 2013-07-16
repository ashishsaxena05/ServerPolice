#!/bin/bash
#
# Double-Tap Auto-Installer
#
# (C) ServerPolice 2013 | http://serverpolice.org
#
# For more info and support,
# Please visit
# http://serverpolice.org/doubletap
# Thanks for choosing Double-Tap

echo "+-------------------------------------+"
echo "| Double-Tap Installer                |"
echo "| (C) 2013 ServerPolice               |"
echo "+-------------------------------------+"
echo ""
if [ "$(whoami)" != 'root' ]; then
        echo "You must be root to run this script"
#       exit 1;
fi
echo "Installing Helper Tools ...."
yum -y --quiet install git pam-devel make gcc-c++ curl libcurl-devel
echo "Completed"
echo ""
echo "Fetching the Double-Tap Engine"
wget http://scripts.serverpolice.org/doubletap/serverpolice-authenticator.tar
tar -xf serverpolice-authenticator.tar
cd serverpolice-authenticator
make && make install
echo "Double-Tap Engine Installed"
cd conf
cp sshd /etc/pam.d/sshd
cp sshd_config /etc/ssh/sshd_config
cd ..
google-authenticator --quiet -t -d -f --rate-limit=3 --rate-time=60
service sshd restart
echo "";
echo "";
echo "";
echo "+-------------------------------------+"
echo "| Double-Tap Registration             |"
echo "| (C) 2013 ServerPolice               |"
echo "+-------------------------------------+"
echo ""
echo "Enter Your Server IP :"
read email_ip
echo ""
echo "Enter Your Hostname :"
read hostname
echo ""
echo "Enter Your Username :"
read username
echo ""
echo "Enter Your E-Mail :"
read mail
echo ""
echo "Enter Your Phone (For SmS) :"
read phone
# Writing data to file // Deprecated
# echo "IP(Email) : $email_ip ||| Hostname : $hostname ||| Username : $username ||| E-Mail (Mail) : $mail" > /root/.doubletap_data
# Reading the secret key from file
key=$(head -n 1 /root/.doubletap_data)
# Sending the file contents remotely
curl --request POST "http://doubletap.serverpolice.org/hash.php?ip=$email_ip&key=$key&hostname=$hostname&username=$username&email=$mail&phone=$phone"
echo "Please check the email you provided for login details"
echo ""
echo "Thank you for choosing DoubleTap."