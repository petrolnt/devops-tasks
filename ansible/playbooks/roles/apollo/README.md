apollo
=========

Install dependencies for nodered project and update project.


Requirements
------------

This role designed for Raspbian OS

Role Variables
--------------

defaults:

```
ansible_ssh_user:       pi
ansible_ssh_pass:       *********
zabbix_server:          10.0.0.50
env_password:           some_sha_hash^
```

Dependencies
------------

Need to install `git` package

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```
---
- name: Install dependencies and update Raspbian
  hosts: '{{target}}'

  roles:
    - role: apollo

```
Usage
-----

`ansible-playbook apollo.yml -e "target=preconf" --ask-vault-pass`
