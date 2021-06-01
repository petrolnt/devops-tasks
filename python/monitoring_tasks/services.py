import subprocess
import json
from importlib.machinery import SourceFileLoader
import logging
import logging.config
import os
import socket
import time
import requests

class Services:

    def __init__(self, logger):
        self.logger = logger
        current_dir = os.getcwd()
        json_obj_path = current_dir + "/json_objects/services_objects.py"
        loader = SourceFileLoader("services_objects.py", json_obj_path)
        self.services_objects = loader.load_module("services_objects.py")
        #temporary files folder
        tmp_folder = '/tmp/sense7'
        subprocess.run(["mkdir", "-p", tmp_folder])

    def getServicesList(self):
        services_list = []
        try:
            res = subprocess.run(["systemctl", "list-unit-files"], stdout=subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in processes: ", exc_info=True)
        for line in (res.stdout).decode("utf-8").split('\n'):
            try:
                if(".service" in line and ("enabled" in line or "disabled" in line)):
                    service = self.services_objects.service()
                    tmp_arr = line.split()
                    service.name = tmp_arr[0].split('.')[0]
                    service.enabled = tmp_arr[1]
                    services_list.append(service)
            except Exception:
                self.logger.exception("Exception in services: ", exc_info=True)
        return services_list

    def getServicesState(self, svc_list):
        services_list = []
        for svc in svc_list:
            try:
                res = subprocess.run(["systemctl", "show", svc.name], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
                arr = (res.stdout).decode("utf-8").split('\n')
                dict = {}
                for item in arr:
                    tmp_arr = item.split("=")
                    if(len(tmp_arr) >= 2):
                        if(tmp_arr[0] == "ExecStart"):
                            val = tmp_arr[2].split(";")[0].strip()
                            dict.update({tmp_arr[0]: val})
                        else:
                            dict.update({tmp_arr[0]: tmp_arr[1]})
                svc.description = dict.get("Description")
                svc.load_state = dict.get("LoadState")
                svc.active_state = dict.get("ActiveState")
                svc.unit_file_state = dict.get("UnitFileState")
                svc.started_time = dict.get("ActiveEnterTimestamp")
                svc.main_pid = dict.get("MainPID")
                svc.memory = dict.get("MemoryCurrent")
                svc.unit_path = dict.get("FragmentPath")
                svc.exec_start = dict.get("ExecStart")
                services_list.append(svc.__dict__)
            except Exception:
                self.logger.exception("Exception in services: ", exc_info=True)


        return services_list

    def sendReport(self, url):
        services_report = self.services_objects.services()
        services_report.host = socket.getfqdn()
        services_report.time7 = int(time.time())
        list_services = self.getServicesList()
        services = self.getServicesState(list_services)
        services_report.services = services

        try:
            json_str = json.dumps(services_report.__dict__)
            headers = {'Content-Type': 'application/json'}
            res = requests.post(url, data=json_str, headers=headers, verify=False)
            if(self.logger.root.level == logging.getLevelName("DEBUG")):
                f = open('reports/services_report.json', 'w')
                f.write(json_str)
                f.close()
            
        except Exception:
            self.logger.exception("Exception in processes: ", exc_info=True)