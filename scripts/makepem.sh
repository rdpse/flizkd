#!/bin/sh
if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]] || [[ $1 == --help ]]
then echo "Usage is 'sh "$0 "<certname> <keyname> <filename>'"
exit 0
fi
certFile=$1
keyFile=$2
(
echo
echo
echo
echo $3
echo 
echo `hostname`
echo
echo
echo
)|
/usr/bin/openssl req -new -x509 -nodes -days 3650 -out ${certFile} -keyout ${keyFile}
echo
