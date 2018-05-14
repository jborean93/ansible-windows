# Ansible adcs-enrollment role

This role will install and configured Active Directory Certificate Services
and set up a GPO for all computers in that domain to auto enroll and get a
certificate from AD CS.

_Note: These steps may not follow best practice in the real world. This should just be used to set up a lab environment and test thigns out._

This role will also add the following Windows modules to Ansible's module path;

* `win_adcs_template`:
* `win_gpo_link`:
* `win_gpo_reg`:

These modules are used within this role but they can also be used by others tasks once called.

The `adcs-winrm` role can be used after this to change the WinRM HTTPS listener
to use the certificate issued by AD CS instead of a self signed cert.

## Requirements

* The host that this is running on should be the domain controller for the domain that AD CS sits in

## Variables

### Mandatory Variables

None

### Output Variables

* `out_adcs_enrollment_chain_thumbprint`: The PEM encoded certificate chain for the AD CS instance created. This can then be used by Ansible as the value for `ansible_winrm_ca_trust_path` to validate the hosts server certificate.

## Examples

```
- name: setup AD CS and auto enrollment configuration
  hosts: all
  roles:
  - adcs-enrollment

  post_tasks:
  - name: create a local copy of the AD CS certificate chain for later use
    copy:
      content: '{{out_adcs_enrollment_chain_thumbprint}}'
      dest: ca_chain.pem
    delegate_to: localhost
    run_once: yes
```
