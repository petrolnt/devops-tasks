#!/usr/bin/python

from os import listdir
from os.path import isfile, join
import operator
from socket import inet_aton,inet_ntoa
import struct
import sys

hostname = sys.argv[1]

def ip2long(ip):
    packed = inet_aton(ip)
    lng = struct.unpack("!L", packed)[0]
    return lng

def long2ip(lng):
    packed = struct.pack("!L", lng)
    ip=inet_ntoa(packed)
    return ip

leased_ips = []

dir = "/etc/openvpn/server/ccd"
files = [f for f in listdir(dir)]
for f in files:
    file = open(join(dir,f), "r") 
    ccd_string = file.read()
    arr = ccd_string.split()
    leased_ips.append(ip2long(arr[1]))

sorted_ips = sorted(leased_ips)

newip = long2ip(sorted_ips[-1] + 1)

new_ccd_string = 'ifconfig-push ' + newip + ' 255.255.254.0\npush "route 192.168.100.0 255.255.255.0"\npush "route 192.168.3.0 255.255.255.0"\n'

new_ccd_file = join(dir, hostname)
nf = open(new_ccd_file, "w+")
nf.write(new_ccd_string)
nf.close()
