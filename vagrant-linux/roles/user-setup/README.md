# Ansible user-setup role

## Overview

Sets up an admin user account with an SSH key according to the vars set.

## Variables

### Mandatory Variables

* `man_user_setup_user`: The name of the user
* `man_user_setup_enc_pass`: The hashed password of the user.
* `man_user_setup_ssh_key`: The public SSH key to add to `~/.ssh/authorized_keys`
* `man_user_setup_group`: The group the user is a member of.

## Examples

```yml
- name: create user and setup
  hosts: all
  vars:
    man_user_setup_user: ansible
    man_user_setup_enc_pass: '$6$OpPwep0n4zujElhs$gWIk6yiEIYVg9h8rcs.Nq8fgas0TSgC/3Wc.Y2SHhvtFfO74Kc63RNaZBY119UAc7kfg1MEbkCIzTod2ksedp1'
    man_user_setup_ssh_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7zoTeDWENzfCBvlqpEJoQdsGHGlP/CeC1UIpaB31WJWnkmWSrHltzw8xVD6m2dn0ZGZxlqGX1awCnWao2zQPAYpOAuReTV7RpT9+ehSfREwbGMYO22kqSITw19ZTCvqZSM1bxirdgreJ7cM7/wFcVc7WUphccFA72V2giNhyNCQU5IQbBGIjODsE6Tmfk4DUkLwRjf9GOriJQY7L11Vn1Of8bRfqKv7E7s6QpvVnnNty2CsocGR07CGQDCL379+5TQJElPsLSajk/TV42+yUDdmYupugtvOkSaBlQLb2wbP6WMmS5JTPLVgHVQKF23kRhW/K0PIbyEecoLDze1dQ5
    man_user_setup_group: ansible-admin
  roles:
  - user-setup
```

