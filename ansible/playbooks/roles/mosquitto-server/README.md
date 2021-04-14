mosquitto-server
=========

Install and configure MQTT brocker Mosquitto.

Role Variables
--------------

defaults:
```
mosquitto_packages:
  - mosquitto
  - mosquitto-clients

mosquitto_password_file: "/etc/mosquitto/passwd"
mosquitto_client: "10.0.0.51"
mosquitto_port: "1883"
mosquitto_allow_anonymous: "false"
```

vars:
```
mosquitto_auth_users: [{name: "voyager", password: "*******"}, {name: "petrol", password: "********"}]
ansible_ssh_user: "admin"

```


Example Playbook
----------------
```
---
- name: Install Mosquitto broker
  hosts: '{{target}}'

  roles:
    - { role: mosquitto-server, become: yes }
```

Usage
-----
```
ansible-playbook mosquitto-server.yml -e '{"target":"your-server-ip"}' --key-file "/root/.ssh/your_key_file.pem"
```
