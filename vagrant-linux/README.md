# Vagrant Linux

This folder contains a Vagrantfile that can create multiple Linux VMs and
configure them so they can use Kerberos auth with the Windows servers created
in the [vagrant](https://github.com/jborean93/ansible-windows/tree/master/vagrant)
folder.

Note this is mostly configured for my personal use but can be modified to work
for you.

The majority of the configuration is done in `inventory.yml`, each host
configured must have the following vars defined;

* `ansible_host`: The IP address to set on the host only network adapater of the VM
* `ansible_package_name`: The name of the package manager to use, current only `apt`, `yum`, and `dnf` are configured.
* `vagrant_box`: The name of the box to use as the source of machine

Vagrant will loop through each host and configure them in turn.

## What is Created

Ultimately the final VM will have the following available

* The latest checkout of the Ansible devel branch at the time of provisioning and added to `~/.bashrc` to activate on logon
* A user called `ansible` with the password `ansible` created
  * The user is added to the sudoers file and can sudo without a password
  * An SSH public key is added to the `~/.ssh/authorized_keys` file based on the `man_user_setup_ssh_key` var
* A custom compiled version of Python 2 and 3 installed alongside the system Python
  * By default the versions are set by `python2_version` and `python3_version` which are `2.7.14` and `3.6.3` respectively
  * These are located in `/usr/local/bin/python2.7` and `/usr/local/bin/python3.6`
  * Attempts to symlink each altinstall with the builting system selinux bindings but this dependent on the distro
* A venv for both the Python 2 and Python 3 setup
  * Ansible and the pywinrm dependencies are installed in each venv
  * These are located at `~/ansible-py27` and `~/ansible-py36`
  * The Python 3 venv is set to active on logon in the`~/.bashrc` file
* Kerberos workstation packages installed and configured to communicate with the realm and kdc specified by the `man_kerberos_*` vars
* dnsmasq installed and setup to automatically lookup hosts with the domain specified by `man_kerberos_realm`

I have been toying adding the host to the actual domain and configure samba but
this is not necessary to use Kerberos auth with Ansible and further complicates
the install. I may look into adding this in the future as a configuration
option.

