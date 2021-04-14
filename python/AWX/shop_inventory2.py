#!/usr/bin/env python

import os
import sys
import argparse

try:
    import json
except ImportError:
    import simplejson as json

class ShopInventory(object):
    def __init__(self):
        self.inventory = {}
        self.read_cli_args()
        # Called with `--list`.
        if self.args.list:
            self.inventory = self.shop_inventory()
        # Called with `--host [hostname]`.
        elif self.args.host:
            # Not implemented, since we return _meta info `--list`.
            self.inventory = self.empty_inventory()
    	# If no groups or vars are present, return an empty inventory.
        else:
            self.inventory = self.empty_inventory()
        print(json.dumps(self.inventory));

    def get_hosts(self, terminals_count):
        hosts = []
        shop_prefix = "pfister-1844-t"
        domain = ".storeone.lc"
        for x in range(1, terminals_count+1):
            host_name = shop_prefix + str(x) + domain
            hosts.append(host_name)
        return hosts

	# Example inventory for testing.
    def shop_inventory(self):
        terminals_count = 16
        shop_name = "villeneuve"
        hosts = self.get_hosts(terminals_count)
        return {
        	shop_name: {
            	'hosts': hosts,
            	'vars': {
					'ansible_ssh_port': '24383'
            	}
        	},
        	'_meta': {
            	'hostvars': {
                	
            	}
        	}
    	}
		

	# Empty inventory for testing.
    def empty_inventory(self):
    	return {'_meta': {'hostvars': {}}}

	# Read the command line args passed to the script.
    def read_cli_args(self):
    	parser = argparse.ArgumentParser()
    	parser.add_argument('--list', action = 'store_true')
    	parser.add_argument('--host', action = 'store')
    	self.args = parser.parse_args()

# Get the inventory.
ShopInventory()