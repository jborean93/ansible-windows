# Ansible python role

## Overview

Install Python using `make altinstall` to `/usr/local/bin/python*`.

## Variables

### Mandatory Variables

* `ansible_package_name`: The name of the package manager for the distro, supports `yum`, `dnf`, and `dnf`.
* `man_python_version`: The Python version to install, should be the x.y.z version string.

## Examples

```yml
- name: install Python 2.7.14
  hosts: all
  vars:
    man_python_version: 2.7.14
  roles:
  - python


- name: install Python 3.6.3
  hosts: all
  vars:
    man_python_version: 3.6.3
  role:
  - python
```

