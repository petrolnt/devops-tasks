zabbix-agent
=========

Role for install and configure zabbix-agent

Requirements
------------

This role was designed for usage in Ubuntu or Debian systems.


Mandatory Role Variables
--------------
```
zabbix_server # internal IP from vpn network - 10.0.0.50 or zabbix.growcer.com for external networks
tls_settings # set False for hosts in VPN network or True for external networks
host_name: # uniqui value that must be same hostname in Zabbix monitoring for this host
```

Example Playbook
----------------
```
---

- name: Install Zabbix agent
  hosts: '{{target}}'
  
  roles:
    - { role: zabbix-agent, become: yes }
```

Usage
----------------

```ansible-playbook zabbix-agent.yml -e '{"target":"168.63.27.129", "zabbix_server":"zabbix.growcer.com", "tls_settings":True, "host_name":"WebServer"}' -u growcer_admin --key-file /home/petrol/.ssh/configurator_stage --ask-vault-pass```<br />
or<br />
```ansible-playbook zabbix-agent.yml -e '{"target":"10.0.0.12", "zabbix_server":"10.0.0.50", "tls_settings":False, "host_name":"Ftp Server"}' -u growcer_admin --ask-pass --ask-vault-pass```<br />
