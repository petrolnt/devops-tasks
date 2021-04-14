iptables
=========

This role was designed for install iptables-persistent and configure firewall rules

Requirements
------------

This role was designed for Debian and Ubuntu systems.

Role Variables
--------------

defaults:

```
tcp_ssh_port: 22
tcp_mosquitto_port: 1883
tcp_zabbix_port: 10050
tcp_vnc_port: 5900
tcp_nodered_port: 1880

input_policy: "DROP"
output_policy: "ACCEPT"
forward_policy: "ACCEPT"

#openvpn in houston
udp_openvpn_port: 5194


allowed_tcp_ports: ["{{tcp_ssh_port}}", "{{tcp_mosquitto_port}}", "{{tcp_zabbix_port}}", "{{tcp_vnc_port}}"]
```

vars:

```
ansible_ssh_user: admin
```

Example Playbook
----------------

```
---
- name: Install iptables rules
  hosts: '{{target}}'
  
  roles:
    - { role: iptables, become: yes }

```
-------

Usage
-----
Please use:</br>
`nsible-playbook iptables.yml -e '{"target":"your-server-ip"}' --key-file "/root/.ssh/your_key_file.pem"`</br>
or</br>
```ansible-playbook iptables.yml -e '{"target":"your-server-ip"}' --ask-vault-pass```</br>
