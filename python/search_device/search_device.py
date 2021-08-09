#This script is designed to search devices by MAC address in Cisco networks. To work with Cisco terminal, I use the excellent library Exscript written by Samuel: https://github.com/knipknap

from Exscript import Account
from Exscript.protocols import SSH2
import Exscript
import getpass
import re
import socket

#input command line parameters
router = raw_input("Enter router ip: ")
username = raw_input('Login: ')
passwd = getpass.getpass('Password: ')
searchMAC = raw_input('Enter the mac address for search: ')

ciscoName = ''

#delete : or - symbols from input mac address, and convert it to cisco format(xxxx.xxxx.xxxx)
replacementSymbols = ':- '
for ch in replacementSymbols:
    searchMAC = searchMAC.replace(ch, '')

ciscoMAC=''

for i in range(len(searchMAC)):
    if ((i % 4 == 0) and (i > 0)):
	ciscoMAC += '.' + searchMAC[i]
    else:
	ciscoMAC += searchMAC[i]

#create account and connecting to cisco switch or router
def connect(router, user, password):
    global username
    global passwd
    global ciscoName
    acc = Account(username,passwd)
    con = SSH2()
    if(not con.connect(router)):
	print "Can not connect to " + router
	exit()
    try:
	con.login(acc)
	con.execute('terminal length 0')
	ciscoName = ((con.response).split('\r\n')[-1]).strip().replace('>', '')
    except Exscript.protocols.Exception.LoginFailure:
	print "Username or password is wrong, please try again."
	username = raw_input('Login:')
	passwd = getpass.getpass('Password:')
	return connect(router,username,passwd)
    except socket.error as msg:
	print msg
	exit()
    return con

#search neighbor of current switch/router in wich searched mac address
def searchNeighbor(connection, interfaceName):
    global ciscoName
    print "Search current switch neighbor..."
    #search neighbor by inerface name and select IP Address
    connection.execute('show cdp neighbors ' + interfaceName + '  detail | include IP address')
    dataString = ((connection.response).split('\r\n')[-2]).strip() #.replace('IP address:', '').strip()
    ipAddress = ''
    try:
	ipAddress = re.findall(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b', dataString)[0]
    except IndexError:
	print 'Device with {0} mac address connected on {1}({2}) in {3} interface'.format(ciscoMAC,connection.get_host(), ciscoName, interfaceName) 
	print 'Next router is unmanaged, search completed'
	exit()
    print('Next router is: ' + ipAddress)
    return ipAddress
        
#search port where listed this mac address
def searchPort(con):
    global ciscoName
    #search inputing mac on this switch
    con.execute('show mac address-table | include ' + ciscoMAC)
    #spliting to strings and getting values from string
    output = con.response
    dataStrings = output.split('\r\n')[1:-1]
    if(len(dataStrings) > 1):
	print "Error! This mac address is not uniqui, more then one results was searched! Output is:\r\n " + output
	exit()
    elif(len(dataStrings) == 0):
	print "This mac address not found on " + router
	exit()
    
    x = re.findall(r'[\w\.\/]+', dataStrings[0])
    #get values from returned string
    vlan = x[0].strip()
    mac = x[1].strip()
    itype = x[2].strip()
    interface = x[3].strip()
    print 'Found mac address on:\r\nvlan = {0} , mac = {1}, type = {2}, int = {3}'.format(vlan,mac,itype,interface)
    #getting all mac adderesses on interface and check count of strings in response, if one string than port for this mac address searched
    con.execute('show mac address-table | include ' + interface)
    output = con.response
    dataString = output.split('\r\n')[1:-1]
    if(len(dataString) == 1):
	print "This device connected to: {0}({1}) on {2} interface".format(con.get_host(), ciscoName,  interface)
	exit();

    return interface

while True:
    con = connect(router, username, passwd)
    port = searchPort(con)
    router = searchNeighbor(con,port)

con.send('exit')
