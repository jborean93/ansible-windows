# Ansible kerberos role

## Overview

Role that will set up the Kerberos packages for a host and configure DNS and
Kerberos itself to be able to look at domain/realm.

## Variables

### Mandatory Variables

* `ansible_package_name`: The name of the package manager for the distro, supports `yum`, `dnf`, and `apt`.
* `man_kerberos_realm`: The realm/domain of to configure, this should be in lowercase.
* `man_kerberos_kdc_hostname`: The hostname (not FQDN) of the KDC or domain controller.
* `man_kerberos_kdc_ip`: The IP address of the KDC or domain controller.

## Examples


```yml
- name: setup kerberos on host
  hosts: all
  vars:
    man_kerberos_realm: example.com
    man_kerberos_kdc_hostname: dc01
    man_kerberos_kdc_ip: 192.168.1.100
  roles:
  - kerberos
```
