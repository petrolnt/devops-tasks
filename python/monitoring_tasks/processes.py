import subprocess
import json
from importlib.machinery import SourceFileLoader
import logging
import logging.config
import os
import socket
import time
import requests

class Processes:

    def __init__(self, logger):
        self.logger = logger

        current_dir = os.getcwd()
        json_obj_path = current_dir + "/json_objects/process_object.py"
        loader = SourceFileLoader("process_object.py", json_obj_path)
        self.proc_object = loader.load_module("process_object.py")
        #temporary files folder
        tmp_folder = '/tmp/sense7'
        subprocess.run(["mkdir", "-p", tmp_folder])

    def getProcessList(self):
        process_list = []
        try:
            res = subprocess.run(["ps", "aux", "--sort", "-%mem"], stdout=subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in processes: ", exc_info=True)
        for line in (res.stdout).decode("utf-8").split('\n'):
            try:
                if(not line.startswith("USER") and (len(line) > 0)):
                    tmp_arr = line.split()
                    process = self.proc_object.process()
                    process.user = tmp_arr[0]
                    process.pid= tmp_arr[1]
                    process.cpu = tmp_arr[2]
                    process.mem = tmp_arr[3]
                    process.command = " ".join(tmp_arr[10:])
                    process_list.append(process.__dict__)
            except Exception:
                self.logger.exception("Exception in processes: ", exc_info=True)
        return process_list

    def sendReport(self, url):
        processes_report = self.proc_object.processes()
        processes_report.host = socket.getfqdn()
        processes_report.time7 = int(time.time())
        processes_list = self.getProcessList()
        processes_report.processes = processes_list

        try:
            json_str = json.dumps(processes_report.__dict__)
            headers = {'Content-Type': 'application/json'}
            res = requests.post(url, data=json_str, headers=headers, verify=False)
            if(self.logger.root.level == logging.getLevelName("DEBUG")):
                f = open('reports/processes_report.json', 'w')
                f.write(json_str)
                f.close()
        except Exception:
            self.logger.exception("Exception in processes: ", exc_info=True)
