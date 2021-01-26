
from pysnmp.hlapi import *
from pysnmp.hlapi.asyncore import *

def print_bulk():
    for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(SnmpEngine(),
        CommunityData('SNMP_COMMUNITY', mpModel=0),
        UdpTransportTarget(('10.83.101.1', 161)),
        ContextData(),
        ObjectType(ObjectIdentity('1.3.6.1.4.1.9.9.109.1.1.1'))):
            if errorIndication or errorStatus:
                print(errorIndication or errorStatus)
                break
            else:
                for varBind in varBinds:
                    print(' = '.join([x.prettyPrint() for x in varBind]))


def print_interfaces():
    iterator = getCmd(
    SnmpEngine(),
    CommunityData('VGRO'),
    UdpTransportTarget(('10.83.101.1', 161)),
    ContextData(),
    ObjectType(ObjectIdentity('IF-MIB', 'ifInOctets', 1)),
    ObjectType(ObjectIdentity('IF-MIB', 'ifOutOctets', 1)),
    lookupMib=True)

    errorIndication, errorStatus, errorIndex, varBinds = next(iterator)

    if errorIndication:
        print(errorIndication)

    elif errorStatus:
        print('%s at %s' % (errorStatus.prettyPrint(), errorIndex and varBinds[int(errorIndex) - 1][0] or '?'))

    else:
        for varBind in varBinds:
            print(' = '.join([x.prettyPrint() for x in varBind]))

#print_interfaces()

def construct_object_types(list_of_oids):
    object_types = []
    for oid in list_of_oids:
        object_types.append(ObjectType(ObjectIdentity(oid)))
    return object_types


def fetch(handler, count):
    result = []
    for i in range(count):
        try:
            error_indication, error_status, error_index, var_binds = next(handler)
            if not error_indication and not error_status:
                items = {}
                for var_bind in var_binds:
                    items[str(var_bind[0])] = cast(var_bind[1])
                result.append(items)
            else:
                raise RuntimeError('Got SNMP error: {0}'.format(error_indication))
        except StopIteration:
            break
    return result

def cast(value):
    try:
        return int(value)
    except (ValueError, TypeError):
        try:
            return float(value)
        except (ValueError, TypeError):
            try:
                return str(value)
            except (ValueError, TypeError):
                pass
    return value



def get(target, oids, credentials, port=161, engine=SnmpEngine(), context=ContextData()):
    handler = getCmd(
        engine,
        credentials,
        UdpTransportTarget((target, port)),
        context,
        *construct_object_types(oids)
    )
    return fetch(handler, 1)[0]


def get_bulk_auto(target, oids, credentials, count_oid, start_from=0, port=161,
                  engine=SnmpEngine(), context=ContextData()):
    count = get(target, [count_oid], credentials, port, engine, context)[count_oid]
    return get_bulk(target, oids, credentials, count, start_from, port, engine, context)

#its = get_bulk_auto('10.83.101.1', ['1.3.6.1.2.1.2.2.1.2', '1.3.6.1.2.1.31.1.1.1.18'], CommunityData('VGRO'), '1.3.6.1.2.1.2.1.0')
#for it in its:
#    for k, v in it.items():
#        print("{0}={1}".format(k, v))
#    print('')
print(get('10.83.101.1', ['1.3.6.1.2.1.1.5.0'], CommunityData('VGRO')))


