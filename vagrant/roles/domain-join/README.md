# Ansible domain-join role

Will join a host to an existing domain as specified by the variables.

## Requirements

An existing domain that the host can access through one of its network
adapters.

## Variables

### Mandatory Variables

* `man_domain_join_network_name`: The name of the Windows network interface that can access the DC, this adapter will have its DNS settings to point to `man_domain_join_dc_ip`.
* `man_domain_join_dc_ip`: The IP address of the domain controller, this is set as the primary DNS server for the network adapter `man_domain_join_network_name`.
* `man_domain_join_domain_name`: The FQDN domain name to join
* `man_domain_join_username`: A domain account that will allow the user to join and also run on the host afterwards
* `man_domain_join_password`: The password for `man_domain_join_username`

## Examples

```
- name: join hosts to the domain.local domain
  hosts: all
  vars:
    man_domain_join_network_name: Ethernet
    man_domain_join_dc_ip: 192.168.1.100
    man_domaon_join_domain_name: domain.local
    man_domain_join_username: domain-user@DOMAIN.LOCAL
    man_domain_join_password: SupaSecretPass1

  roles:
  - domain-join
```
