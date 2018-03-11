# Ansible and Windows

This repo contains some scripts and other stuff that can be useful when using
Ansible with Windows hosts.

Further scripts and utilities may be added in the future as required.

## Scripts

There are a few scripts in the `scripts` folder that can be used to do things
like upgrade PowerShell to a certain version. The [README](scripts/README.md) page of that folder
has more details on each script and how to run them.

## Vagrant

Contains a Vagrantfile and Ansible playbook that will create a dev environment
of multiple Windows servers in a domain. See the [README](vagrant/README.md) page for more details.

## Vagrant Linux

Contains a Vagrantfile and Ansible playbook that will create a dev environment
of multiple Linux servers that can communicate with the domain created by the
files in the `vagrant` folder. This is useful if you want to test out things
like Kerberos authentication with Ansible without polluting your localhost.

See the [README](vagrant-linux/README.md) page for more details.
