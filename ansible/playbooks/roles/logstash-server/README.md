logstash-server
=========

Role for install and configure logstash server.

Requirements
------------

This role was designed for Ubuntu and Debian systems.

Role Variables
--------------

defaults:
```
logstash_version: '6.x'

# logstash jvm options
initial_heap_space: "-Xms256m"
maximum_heap_space: "-Xms256m"
```

vars:

```
ansible_ssh_user: admin
```

Example Playbook
----------------

```
---
- name: Install a Logstash server
  hosts: '{{target}}'
  
  roles:
    - { role: logstash-server, become: yes }

```
Usage
----

Please use:</br>
`ansible-playbook logstash.yml -e '{"target":"your-server-ip"}' --key-file "/root/.ssh/your_key_file.pem"`</br>
or</br>
`ansible-playbook logstash.yml -e '{"target":"your-server-ip"}' --ask-pass`</br>
for password based authentication.
