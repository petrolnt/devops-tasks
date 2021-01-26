import time
import paho.mqtt.client as mqttClient
import sys
import json

if len (sys.argv) != 4 :
    print "Usage: python ex.py <command_type> <int_from> <int_to>"
    sys.exit (1)
if(sys.argv[1] == "transfer"):
    command_type = sys.argv[1]
else:
    print("Unknown command: " + sys.argv[1])
    sys.exit(1)

try:
    int_from = int(sys.argv[2])
    int_to = int(sys.argv[3])
except:
    print("Error in parsing additional parameters")
    sys.exit(1)

if(int_from > 2 or int_to > 2):
    print("int_from or int_to values can be from 0 to 2")
    sys.exit(1)

json_command = '{"cmd": "%s","params": {"from": %d, "to": %d}}' %(command_type, int_from, int_to)

broker="127.0.0.1"
user="username"
password="1q2w3e4r"

client = mqttClient.Client("Peter") 
client.username_pw_set(user, password=password)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to broker")
        global Connected                #Use global variable
        Connected = True                #Signal connection 
    else:
        print("Connection failed")

def on_publish(client, userdata, result):             #create function for callback
    print("Message published")

client.on_connect = on_connect
client.on_publish = on_publish
client.connect(broker)

time.sleep(1)

client.publish("facility/atat", json_command)#publish
client.disconnect() #disconnect
