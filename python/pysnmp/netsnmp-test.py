import netsnmp

serv = "10.83.101.1"
snmp_pass = "VGRO"

def print_cpu():
    oid = netsnmp.VarList(netsnmp.Varbind('1.3.6.1.4.1.9.9.109.1.1.1.1.2',''))
    snmp_res = netsnmp.snmpwalk(oid, Version=2, DestHost=serv, Community=snmp_pass)
    for x in oid:
        print "snmp_res:: ", x.iid, " = ", x.val

def print_interfaces():
    oid = netsnmp.VarList('IF-MIB::ifDescr')
    snmp_res = netsnmp.snmpwalk(oid, Version=2, DestHost=serv, Community=snmp_pass)
    for x in oid:
        print x.iid, " = ", x.val

print_interfaces()

