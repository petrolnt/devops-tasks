mongodb-server
=========

Installation and preparing mongodb infrastructure

Requirements
------------

This playbook was designed for Debian or Ubuntu servers

Role Variables
--------------

vars:
```
ansible_ssh_user: ubuntu
mongodb_admin: admin
mongodb_admin_password: mongo_admin_password
```
`vars/main.yml` is ansible-vault encrypted file, for edit please use:</br>

`ansible-vault edit main.yml`

Example Playbook
----------------
```
---

- name: Install and configure MongoDB cluster
  hosts: '{{target}}'

  roles:
    - { role: mongodb-server, become: yes }
```

Usage
-----

```ansible-playbook mongodb-server.yml -e '{"target":"your-server-ip"}' --key-file "/root/.ssh/your_key_file.pem"```</br>
or</br>
```ansible-playbook mongodb-server.yml -e '{"target":"your-server-ip"}' --ask-vault-pass```</br>

