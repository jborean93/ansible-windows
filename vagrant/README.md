# Vagrant

This can be used to spin up a single Windows host or a standalone domain that
contains a mixture of Windows hosts. Please note the Vagrant images for Windows
hosts are a lot larger than normal images. While the download operation only
happens once, it will take a while to complete and store on the hard drive.

The following is required to run any of these steps;

* Vagrant
* VirtualBox

These examples use existing Windows Vagrant images for VirtualBox that have
been created with the [packer-windoze](https://github.com/jborean93/packer-windoze)
repository. As of writting this, the following boxes are available to be used
and have been uploaded to the Vagrant Cloud service;

* jborean93/WindowsServer2008-x86
* jborean93/WindowsServer2008-x64
* jborean93/WindowsServer2008R2
* jborean93/WindowsServer2012
* jborean93/WindowsServer2012R2
* jborean93/WindowsServer2016

See the repo url or [this blog post](http://www.bloggingforlogging.com/2017/11/23/using-packer-to-create-windows-images/)
for more details.

## Single Instance Example

If you only need a single Windows instance up and running you can easily set
it up by creating a single file called `Vagrantfile` with the following
contents.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "jborean93/WindowsServer2016"
end
```

You can specify another box if you want to use a different Windows version, see
the intro for more details.

Once this file is created, you can run `vagrant up` in the same directory as
that file and Vagrant will automatically provision a new Windows Server 2016
host for you. Once the host is started up you can use it immediately with
Ansible by using the following inventory file.

```ini
[windows]
Server2016  ansible_host=127.0.0.1

[windows:vars]
ansible_user=vagrant
ansible_password=vagrant
ansible_port=55986
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```

Feel free to play around with the different version or inventory, you can also
access the host through RDP using the default port of `3389` over `127.0.0.1`.
If that port is already being used by another service then Vagrant will
use another port and display that in the output.

## Domain Setup Example

While the above example can set up a single Windows instance, if you want to
run Ansible over multiple Windows hosts in a domain, you can use the existing
Vagrantfile in this folder to set this up for you.

The 4 files that you need to run this process are;

* `Vagrantfile`: The Vagrant file that reads the settings from the inventory and set's up the hosts that are required
* `inventory.yml`: The Ansible inventory file that defines how the hosts will be set up
* `main.yml`: Run after the hosts are provisioned to create a domain controller and join the other hosts to the domain
* `roles`: A bunch of roles used by `main.yml` to create the environment

This process will create a domain environment will the following set up;

* A domain user, defined in `inventory.yml`, that is part of the `Domain Admins` group
* An Active Directory Certificate Services (AD CS) install with auto enrollment of server certificates
* A local copy at `ca_chain.pem` that is the root certificate used by AD CS to sign each certificate
* The child hosts, connected to the domain
* The WinRM HTTPS listeners use the certificate that was issued by AD CS

The existing `inventory.yml` file is set up to create a host for each major
Windows Server releases that are supported by Ansible + an extra domain
controller running on Server 2016. You can modify the inventory to either
remote hosts or change the Vagrant boxes that are used.

Once the inventory has been set up, run `vagrant up` to start the provisioning
process. Sit back and wait until it is complete. You can either reuse the same
inventory file for your own playbooks or just create your own.

A few tips and tricks;

* If the Ansible playbook to provision the hosts fail, you can rerun just that
  step by running `vagrant provision`
* While the hosts are set up with a host only network adapter and should be
  accessible by the IP address, Vagrant will also set up a port forwarder
  for RDP, SSH, SMB and WinRM. See the `inventory.yml` file for more info

Depending on the number of hosts you have defined in your `inventory.yml` file,
the provisioning process can take some time to complete as Vagrant/VirtualBox
does not support provisioning in parallel. Either give it more time or reduce
the number of hosts that are defined in the `domain_children` section of the
inventory.
