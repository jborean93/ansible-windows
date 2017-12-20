# Ansible ansible role

## Overview

Creates a venv which includes Ansible and pywinrm for both Python 2 and 3 in
the home directory for the user. It also pulls down the latest devel checkout
adds that to the bashrc for loading.

## Variables

None

## Examples

```yml
- name: setup Ansible
  hosts: all
  roles:
  - ansible-setup
```
