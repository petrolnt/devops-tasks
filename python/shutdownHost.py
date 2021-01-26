#This script was designed for remote shutdown VMWare ESXI Host.
#Host or hosts are passed as parameters when script will running: shutdownHost.py esxihost1 esxihost2 esxihost3.
#All hosts will be halted in one time in multithreaded mode.
import sys
import ssl
import time
import atexit
import pyVmomi
from pyVim import connect
from pyVmomi import vmodl
from pyVmomi import vim
from multiprocessing.dummy import Pool as ThreadPool

def shutdownHost(hostname):
    username = "root"
    passwd = "1q2w3e4r"
    service_instance = connect.SmartConnect(host=hostname, user=username, pwd=passwd)
    atexit.register(connect.Disconnect, service_instance)
    content = service_instance.RetrieveContent()
    container = content.rootFolder
    viewType = [vim.VirtualMachine]
    recursive = True
    hostView = [pyVmomi.vim.HostSystem]
    containerView = content.viewManager.CreateContainerView(container, viewType, recursive)
    host = (content.viewManager.CreateContainerView(container, hostView, recursive=True)).view[0]
    vms = containerView.view
    for vm in vms:	
	vm_name = vm.config.name
	vm_tools_version = vm.config.tools.toolsVersion
	vm_powerState = vm.runtime.powerState
	try:
            if(vm_powerState == "poweredOn"):
                #if vmware tools is installed then soft shutdown
                if(vm_tools_version != 0):
	            vm.ShutdownGuest()
	            print("The virtual machine " + vm_name + " on " + hostname + "  is going to shutting down.")
                #hard shutdown
                else:
                    print(vm_name + " on " + hostname + " hard shutdown.")
                    vm.PowerOffVM_Task()
            else:
	        print(vm_name + " on " + hostname + " is already turned off or suspended")
        except Exception as e:
            print("Error in shutting down virtual machine " + vm_name + " on " + hostname)
    
    #sleep 5 minutes for VMs will be shutting down
    time.sleep(300)
    #hard shutdown for virtual machines that not stopped in 5 minutes
    for vm in vms:
        vm_name = vm.config.name
        vm_powerState = vm.runtime.powerState
        try:
            if(vm_powerState == "poweredOn"):
                print("Virtual machine " + vm_name + " on " + hostname + " is not halted in 5 minutes - hard shutdown.")
                vm.PowerOffVM_Task()
        except Exception as e:
            print("Error in hard power off: " + e.msg)
    print("Shutdown host " + hostname)
    host.ShutdownHost_Task(True)

def main():
    #allow connect to hosts with unverified certificates
    default_context = ssl._create_default_https_context
    ssl._create_default_https_context = ssl._create_unverified_context
    #getting list of hosts from command line arguments and start shutting down in multithread mode
    hosts = sys.argv[1:]
    pool = ThreadPool(len(hosts))
    pool.map(shutdownHost, hosts)
    pool.close()
    pool.join
	
    
    


    
# Start program
if __name__=="__main__":
    main()
