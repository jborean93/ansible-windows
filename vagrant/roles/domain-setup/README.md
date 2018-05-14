# Ansible domain-setup role

Will create a branch new domain on a Windows Server. This role is just a
basic bare bones roles to create the domain. No hardening or secure practices
are really included here.

## Requirements

N/A

## Variables

### Mandatory Variables

* `man_domain_setup_network_name`: The name of the Windows network interface that the domain will set itself as the primary DNS server.
* `man_domain_setup_domain_name`: The FQDN of the domain to create
* `man_domain_setup_safe_mode_password`: The password to set as the safe mode admin password when creating the domain
* `man_domain_setup_username`: A domain account name to create that is a member of the `Domain Admins` group
* `man_domain_setup_password`: The password for `man_domain_setup_username`

## Examples

```
- name: create domain controller for the domain domain.local
  hosts: all
  vars:
    man_domain_setup_network_name: Ethernet
    man_domain_setup_domain_name: domain.local
    man_domain_setup_safe_mode_password: Password01
    man_domain_setup_username: domain-user
    man_domain_setup_password: Password01
```
