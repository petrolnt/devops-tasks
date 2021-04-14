voyager
=========

This role was designed for preparing voyager server, and for updating voyager cotlin application.
It will do:
  - Install updates
  - Install OpenJDK
  - Install Kotlin
  - Install gradle, with version specified in variables
  - Copy project from Git to a target system
  - Build project on a target system
  - Install project binaryes as a Systemd service and enable it


Requirements
------------

This role is for debian or ubuntu systems. You need to install `git` before usage this role.

Role Variables
--------------

`defaults:`
```
gradle_version: 4.10.3
gradle_binary: "gradle-{{ gradle_version }}-all.zip"
gradle_checksum: sha256:336b6898b491f6334502d8074a6b8c2d73ed83b92123106bd4bf837f04111043
gradle_download: "/tmp/{{ gradle_binary }}"
gradle_download_url: "https://services.gradle.org/distributions/{{ gradle_binary }}"
gradle_base_dir: /opt
gradle_extract_dir:  "gradle-{{ gradle_version }}"
gradle_link: /usr/local/bin/gradle

#project variables
project_folder: /opt/voyager
project_src_folder: "/home/{{ ansible_ssh_user }}/voyager"
user_home: "/home/{{ ansible_ssh_user }}"
service_name: voyager.service
```

`vars:`
```
ansible_ssh_user: cti
ansible_sudo_pass: *************
```
vars/main.yml is encripted by ansible-vault. For edit please use:<br />
```ansible-vault edit main.yml```

Example Playbook
----------------

```
---
- name: Install voyager server
  hosts: '{{target}}'

  roles:
    - { role: voyager, become: yes }
```

Usage
----------------

For full configuration please use:<br />
`ansible-playbook voyager.yml -e '{"target":"your-server-ip","preconf":true}' --key-file "/root/.ssh/your_key_file.pem"`</br>
or<br />
`ansible-playbook voyager.yml -e '{"target":"your-server-ip","preconf":false}' --key-file "/root/.ssh/your_key_file.pem"`</br>
for update voyager application only
