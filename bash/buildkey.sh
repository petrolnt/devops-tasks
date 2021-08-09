#!/bin/bash

hostname=$1
[ -z "$hostname" ] && echo "Empty hostnamename! Use `basename $0` hostname" && exit

rsa_folder="/usr/share/easy-rsa"
cert_file=$rsa_folder"/keys/"$hostname".csr"

source vars
if [ ! -f $cert_file ]; then
    $rsa_folder/build-key --batch $hostname
    /usr/bin/python /usr/local/scripts/create_ccd.py $hostname
else
    echo "The host certificate already exists"
fi

