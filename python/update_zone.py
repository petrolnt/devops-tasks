from datetime import datetime
import time
import re
import os
import dns.zone
from dns.exception import DNSException
from dns.rdataclass import *
from dns.rdatatype import *

def update_zone(hostname, ip):
    domain = "houston.lc"
    zone_file = "/etc/bind/%s" % domain
    try:
	zone = dns.zone.from_file(zone_file, domain)
	rdataset = None
	print "Zone origin:", zone.origin
	A_change = hostname
        try:
	    rdataset = zone.find_rdataset(A_change, rdtype=A)
        except KeyError, e:
	    print "Entry for %s is not found" % hostname
	    
        
	if(rdataset != None):
	    print "Changing A record for", A_change, "to", ip
    	    for rdata in rdataset:
		rdata.address = ip
	else:
	    print "Adding record of type A:", A_change
    	    rdataset = zone.find_rdataset(A_change, rdtype=A, create=True)
	    rdata = dns.rdtypes.IN.A.A(IN, A, address=ip)
    	    rdataset.add(rdata, ttl=86400)
	print "Saving zone..."
	zone.to_file(zone_file)
	print "Reloading zone..."
	rncd_cmd = "/usr/sbin/rndc reload " + domain
	retval = os.popen(rncd_cmd).read()
    except DNSException, e:
	print e.__class__, e


STATUS_FILE = '/var/log/openvpn/openvpn-status.log'
HOSTS_FILE = '/root/hosts.custom'
GMTIMEDIFF = 7200

with open(STATUS_FILE) as f:
    data = f.read()
    host_data = re.search('Last Ref.(.+).GLOBAL STATS.*', data, re.S).group(1)
    host_data = host_data.splitlines()
    conn_data = re.search('Connected Since.(.+).ROUTING TABLE.*', data, re.S).group(1)
    conn_data = conn_data.splitlines()

latest_client = max([int(datetime.strptime(x.split(',')[4], '%c').strftime('%s')) for x in conn_data])
latest_client -= GMTIMEDIFF
try:
    latest_update = int(time.strftime('%s', time.gmtime(os.stat(HOSTS_FILE).st_mtime)))
except:
    latest_update = 0

print(latest_update)
print(latest_client)

if latest_update < latest_client:
    # we have a new client connected since last HOSTS_FILE modification
    print('Updating..')
    for entry in host_data:
        ip, hostname, ip2, date = entry.strip().split(',')
	if("/" not in ip):
	    if(ip.endswith('C')):
		ip = ip[:-1]
    	    update_zone(hostname, ip)

