import paho.mqtt.client as mqttClient
import time
import json
 
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to broker")
        global Connected                #Use global variable
        Connected = True                #Signal connection 
    else:
        print("Connection failed")
 
def on_message(client, userdata, message):
    try:
	str_json = message.payload
	json_command = json.loads(str_json)
	command_type = json_command.get('cmd')
	str_from = json_command.get('params').get('from')
	str_to = json_command.get('params').get('to')
	if(command_type == "transfer"):
	    print("Transfer from %s to %s" %(str_from, str_to))
	else:
	    print("Unknown command")
    except:
	print("Exception in parsing command")
 
Connected = False   #global variable for the state of the connection
 
broker_address= "127.0.0.1"
user = "atat"                    #Connection username
password = "1q2w3e4r"            #Connection password
queue = "facility/atat"
 
client = mqttClient.Client("atat")               #create new instance
client.username_pw_set(user, password=password)    #set username and password
client.on_connect= on_connect                      #attach function to callback
client.on_message= on_message                      #attach function to callback
try:
    client.connect(broker_address)
except:
    print('Exception in connecting to mqtt server')
    sys.exit(1)

try:
    client.loop_start()        #start the loop
except:
    print('Exception in starting loop')
    sys.exit(1)

while Connected != True:    #Wait for connection
    time.sleep(0.1)

try:
    client.subscribe(queue)
except:
    print('Exception in subscription to queue:' + queue)
    sys.exit(1)
 
try:
    while True:
        time.sleep(1)
 
except KeyboardInterrupt:
    print "exiting"
    client.disconnect()
    client.loop_stop()
