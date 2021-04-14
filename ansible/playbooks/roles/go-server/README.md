go-server
=========

This role was designed for preparing golang server with mongodb, and for updating go application.

Requirements
------------

This role designed for Debian or Ubuntu servers.

Role Variables
--------------

defaults:

```
go_tarball: "go1.11.2.linux-amd64.tar.gz"
go_tarball_checksum: "sha256:1dfe664fa3d8ad714bbd15a36627992effd150ddabd7523931f077b3926d736d"
go_version_target: "go version go1.11.2 linux/amd64"
set_go_path: true
go_app_name: "hello"
go_app_port: "8001"
go_root: "/usr/local/go"

go_get:
- name: mgo
  url: gopkg.in/mgo.v2
```

vars:

```
go_download_location: "https://storage.googleapis.com/golang/{{ go_tarball }}"
ansible_ssh_user: ubuntu
```

Example Playbook
----------------

```
---
- name: Install golang and nginx
  hosts: '{{target}}'

  roles:
    - { role: go-server, become: yes }
```

Usage
-----
For full configuration please use:<br/>
`ansible-playbook go-server.yml -e '{"target":"your-server-ip","preconf":true}' --key-file "/root/.ssh/your_key_file.pem"`<br/>
for update go project only:<br/>
`ansible-playbook go-server.yml -e '{"target":"your-server-ip","preconf":false}' --key-file "/root/.ssh/your_key_file.pem"`<br/>

