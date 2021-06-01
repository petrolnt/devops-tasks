import json
from importlib.machinery import SourceFileLoader
import os
import re
import sys
import subprocess
import time
import socket
import requests
import logging
import logging.config

class Metrics:


    def __init__(self, logger, metrics_interval):
        self.metrics_interval = metrics_interval
        self.logger = logger
        current_dir = os.getcwd()
        json_obj_path = current_dir + "/json_objects/metrics_objects.py"
        loader = SourceFileLoader("metrics.py", json_obj_path)
        self.metrics_objects = loader.load_module("metrics.py")

        #temporary files folder
        tmp_folder = '/tmp/sense7'
        subprocess.run(["mkdir", "-p", tmp_folder])
        self.list_iostat_objects = self.createIOStatObjects()

    def getCpuStat(self):
        cpu_stat = []
        try:
            res = subprocess.run(["cat", "/proc/stat"], stdout=subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in metrics: ", exc_info=True)

        for line in (res.stdout).decode("utf-8").split('\n'):
            try:
                if(line.startswith("cpu")):
                    tmp_arr = line.split()
                    cpu_stat.append(tmp_arr)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)
        return cpu_stat

    def getCpuUsage(self):
        list_cpu = []
        try:
            prev_cpu_stat_strings = self.getCpuStat()
            time.sleep(1)
            cur_cpu_stat_strings = self.getCpuStat()
        except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)

        for i in range(len(prev_cpu_stat_strings)):
            try:
                prev_cpu_stat = prev_cpu_stat_strings[i]
                cur_cpu_stat = cur_cpu_stat_strings[i]
                prev_idle =  int(prev_cpu_stat[4]) + int(prev_cpu_stat[5])
                idle = int(cur_cpu_stat[4]) + int(cur_cpu_stat[5])
                prev_non_idle = int(prev_cpu_stat[1]) + int(prev_cpu_stat[2]) + int(prev_cpu_stat[3]) + int(prev_cpu_stat[6]) + int(prev_cpu_stat[7]) + int(prev_cpu_stat[8])
                non_idle = int(cur_cpu_stat[1]) + int(cur_cpu_stat[2]) + int(cur_cpu_stat[3]) + int(cur_cpu_stat[6]) + int(cur_cpu_stat[7]) + int(cur_cpu_stat[8])
                prev_total = prev_idle + prev_non_idle
                total = idle + non_idle
                total_dif = total - prev_total
                idle_dif = idle - prev_idle
                cpu_perc = round((total_dif - idle_dif)/total_dif*100,1)
                cpu = self.metrics_objects.cpu(prev_cpu_stat_strings[i][0])
                cpu.usage_percent = cpu_perc
                list_cpu.append(cpu.__dict__)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)
    
        return list_cpu



    #interfaces
    def getListInterfaces(self):
        list_interfaces = []

        list_iface_names = os.listdir('/sys/class/net/')
        for iface_name in list_iface_names:
            try:
                interface = self.metrics_objects.interface(iface_name)
                file = open("/proc/net/dev", "r")
                for line in file:
                    try:
                        if re.search(iface_name, line):
                            iface_stat = line.split()
                            interface.rx_bytes = iface_stat[1]
                            interface.rx_packets = iface_stat[2]
                            interface.rx_errors = iface_stat[3]
                            interface.rx_drop = iface_stat[4]
                            interface.rx_fifo = iface_stat[5]
                            interface.rx_frame = iface_stat[6]
                            interface.rx_compressed = iface_stat[7]
                            interface.rx_multicast = iface_stat[8]
                            interface.tx_bytes = iface_stat[9]
                            interface.tx_packets = iface_stat[10]
                            interface.tx_errors = iface_stat[11]
                            interface.tx_drop = iface_stat[12]
                            interface.tx_fifo= iface_stat[13]
                            interface.tx_colls = iface_stat[14]
                            interface.tx_carrier = iface_stat[15]
                            interface.tx_compressed = iface_stat[16]
                            list_interfaces.append(interface.__dict__)
                    except Exception:
                        self.logger.exception("Exception in metrics: ", exc_info=True)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)
        return list_interfaces
        

    #filesystems
    def getListFilesystems(self):
        list_filesystems = []
        try:
            res = subprocess.run(["df", "-Th"], stdout=subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in metrics: ", exc_info=True)
        for line in (res.stdout).decode("utf-8").split('\n'):
            try:
                if(not line.startswith("Filesystem") and (len(line) > 0)):
                    fs_entry = line.split()
                    fs = self.metrics_objects.filesystem(fs_entry[0])
                    fs.mount_point = fs_entry[6]
                    fs.size =  fs_entry[2]
                    fs.used = fs_entry[3]
                    fs.available = fs_entry[4]
                    fs.used_perc = fs_entry[5]
                    fs.filesystem = fs_entry[1]
                    list_filesystems.append(fs.__dict__)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)
        return list_filesystems

    #disks
    def getListDisks(self, filesystems):
        disks = []
        try:
            res = subprocess.run(["lsblk", "-a", "-o", "NAME,MOUNTPOINT,SIZE,TYPE"],
            stdout = subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in metrics: ", exc_info=True)

        arr_output = (res.stdout).decode("utf-8").split('\n')
        
        for i in range(len(arr_output)):
            if arr_output[i].startswith('NAME') or len(arr_output[i]) == 0:
                continue
            blk_list = arr_output[i].split()
            node_type = blk_list[-1]
            if (not node_type in ["disk", "part", "lvm"]):
                continue
            #parse string
            node_name = re.sub('\W', '', blk_list[0])
            
            if("/" in blk_list[1] or "[" in blk_list[1]):
                mountpoint = blk_list[1]
                node_size = blk_list[2]
                fs_object = {"name": node_name, "mountpoint": mountpoint, 
                "type": node_type, "size": node_size, "childs": []}
                #filesystems
                for fs in filesystems:
                    if(fs_object["mountpoint"] == fs["mount_point"]):
                        fs_object["used"] = fs["used"]
                        fs_object["available"] = fs["available"]
                        fs_object["used_perc"] = fs["used_perc"]
                        fs_object["filesystem"] = fs["filesystem"]
            else:
                node_size = blk_list[1]
                fs_object = {"name": node_name, "type": node_type, "size": node_size, "childs": []}
            #add disk or child
            #if(arr_output[i].startswith('├─') or arr_output[i].startswith('└─')):
            if('part' in arr_output[i]):
                disks[-1]["childs"].append(fs_object)
            #elif(arr_output[i].startswith('SUBCASE\s+(├─)') or arr_output[i].startswith('SUBCASE\s+(└─)')):
            elif('lvm' in arr_output[i]):
                disks[-1]["childs"][-1]["childs"].append(fs_object)
            else:
                disks.append(fs_object)
        return disks

    #iostat
    def getIOStat(self):
        list_iostat = []

        for obj in self.list_iostat_objects:
            try:
                res = subprocess.run(["awk", "/"+obj.name+"/{ print; }", "/proc/diskstats"], stdout = subprocess.PIPE)
                arr_output = (res.stdout).decode("utf-8").split('\n')

                if len(arr_output[0]) > 0:
                    tmp_arr = arr_output[0].split()
                    obj.set_read_sectors(int(tmp_arr[5]))
                    obj.set_read_ops(int(tmp_arr[3]))
                    obj.set_read_merged(int(tmp_arr[4]))
                    obj.set_read_duration(int(tmp_arr[6]))
                    obj.set_write_sectors(int(tmp_arr[9]))
                    obj.set_write_ops(int(tmp_arr[7]))
                    obj.set_write_merged(int(tmp_arr[8]))
                    obj.set_write_duration(int(tmp_arr[10]))
                    obj.set_busy_duration(int(tmp_arr[12]))
                    obj.set_transaction_duration(int(tmp_arr[13]))
                    obj.set_transaction_queue_length(int(tmp_arr[11]))
                    fs_object_stat = {
                        "disk_name": "",
                        "read_bytes_persec": 0,
                        "write_bytes_persec": 0,
                        "disk_load_perc": 0,
                        "merged_read_ops_persec": 0,
                        "merged_write_ops_persec": 0,
                        "read_duration_avg": 0,
                        "write_duration_avg": 0,
                        "transaction_duration_avg": 0,
                        "ops_queue_lenght": 0,
                        "read_ops_persec": 0,
                        "write_ops_persec": 0
                    }
                    fs_object_stat["disk_name"] = obj.name
                    fs_object_stat["read_bytes_persec"] = round(obj.get_read_bytes()/self.metrics_interval, 2)
                    fs_object_stat["write_bytes_persec"] = round(obj.get_write_bytes()/self.metrics_interval, 2)
                    fs_object_stat["disk_load_perc"] = round(obj.get_busy_duration()/self.metrics_interval, 2)
                    fs_object_stat["merged_read_ops_persec"] = round(obj.get_read_merged()/self.metrics_interval, 2)
                    fs_object_stat["merged_write_ops_persec"] = round(obj.get_write_merged()/self.metrics_interval, 2)
                    fs_object_stat["read_duration_avg"] = round(obj.get_read_duration()/self.metrics_interval, 2)
                    fs_object_stat["write_duration_avg"] = round(obj.get_write_duration()/self.metrics_interval, 2)
                    fs_object_stat["transaction_duration_avg"] = round(obj.get_transaction_duration()/self.metrics_interval, 2)
                    fs_object_stat["ops_queue_length"] = obj.get_transaction_queue_length()
                    fs_object_stat["read_ops_persec"] = round(obj.get_read_ops()/self.metrics_interval, 2)
                    fs_object_stat["write_ops_persec"] = round(obj.get_write_ops()/self.metrics_interval, 2)
                    list_iostat.append(fs_object_stat)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)

        return list_iostat
                

    def createIOStatObjects(self):
        fs_object_stats = []
        try:
            res = subprocess.run(["cat", "/proc/diskstats"], stdout = subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in iostat: ", exc_info=True)

        arr_output = (res.stdout).decode("utf-8").split('\n')
        for line in arr_output:
            try:
                if len(line) > 0:
                    tmp_arr = line.split()
                    iostat_obj = self.metrics_objects.iostat_helper(tmp_arr[2])
                    iostat_obj.set_read_sectors(int(tmp_arr[5]))
                    iostat_obj.set_read_ops(int(tmp_arr[3]))
                    iostat_obj.set_read_merged(int(tmp_arr[4]))
                    iostat_obj.set_read_duration(int(tmp_arr[6]))
                    iostat_obj.set_write_sectors(int(tmp_arr[9]))
                    iostat_obj.set_write_ops(int(tmp_arr[7]))
                    iostat_obj.set_write_merged(int(tmp_arr[8]))
                    iostat_obj.set_write_duration(int(tmp_arr[10]))
                    iostat_obj.set_busy_duration(int(tmp_arr[12]))
                    iostat_obj.set_transaction_duration(int(tmp_arr[13]))
                    iostat_obj.set_transaction_queue_length(int(tmp_arr[11]))
                    fs_object_stats.append(iostat_obj)
                
            except Exception:
                self.logger.exception("Exception in iostat: ", exc_info=True)
        return fs_object_stats


    #RAM
    def getMemoryUsage(self):
        list_memory = []
        try:
            res = subprocess.run(["free"], stdout=subprocess.PIPE)
        except Exception:
            self.logger.exception("Exception in metrics: ", exc_info=True)
        for line in (res.stdout).decode("utf-8").split('\n'):
            try:
                if line.startswith("Mem:"):
                    tmp_arr = line.split()
                    total_memory = tmp_arr[1]
                    free_memory = tmp_arr[3]
                    list_memory.append(total_memory)
                    list_memory.append(free_memory)
                elif (line.startswith("Swap:")):
                    tmp_arr = line.split()
                    swap_total = tmp_arr[1]
                    swap_free = tmp_arr[3]
                    list_memory.append(swap_total)
                    list_memory.append(swap_free)
            except Exception:
                self.logger.exception("Exception in metrics: ", exc_info=True)
        return list_memory

    def sendReport(self, url):
        metrics_report = self.metrics_objects.metrics_report()
        metrics_report.host = socket.getfqdn()
        metrics_report.time7 = int(time.time())
        list_memory_usage = self.getMemoryUsage()
        metrics_report.total_memory = list_memory_usage[0]
        metrics_report.free_memory = list_memory_usage[1]
        metrics_report.swap_total = list_memory_usage[2]
        metrics_report.swap_free = list_memory_usage[3]
        metrics_report.cpus = self.getCpuUsage()
        metrics_report.filesystems = self.getListFilesystems()
        metrics_report.disks = self.getListDisks(metrics_report.filesystems)
        metrics_report.interfaces = self.getListInterfaces()
        metrics_report.iostat = self.getIOStat()
        
        try:
            json_str = json.dumps(metrics_report.__dict__)
            headers = {'Content-Type': 'application/json'}
            res = requests.post(url, data=json_str, headers=headers, verify=False)
            if(self.logger.root.level == logging.getLevelName("DEBUG")):
                f = open('reports/metrics_report.json', 'w')
                f.write(json_str)
                f.close()
        except Exception:
            self.   logger.exception("Exception in metrics: ", exc_info=True)

    
