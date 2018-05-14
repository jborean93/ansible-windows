# Ansible adcs-winrm role

Will change the existing WinRM HTTPS listener to use the auto enrolled
certificate issued by AD CS in a domain.

_Note: There is a small chance the WinRM listener will be deleted during a failed operation and Ansible won't be able to connect anymore. The listener must be manually recreated if this happens._

## Requirements

* A Windows domain set up and the host is connected to that domain
* Active Directory Certificate Services is setup and contains a valid auto enrollment template
* GPO set up so the host will auto enroll and get the certificate from AD CS

The last 2 points can be done with the `adcs-enrollment` role.

## Variables

### Mandatory Variables

* `man_adcs_winrm_is_dc`: A boolean variable that defines whether the current host is a domain controller with AD CS installed or another host. The logic to get the real certificate is different with this type of host and so we need to know beforehand

## Examples

```
- name: change the WinRM listener to use the AD CS certificate
  hosts: all
  vars:
    man_adcs_winrm_is_dc: no
  roles:
  - adcs-winrm
```
