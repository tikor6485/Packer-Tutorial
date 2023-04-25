# Packer Configuration for Ubuntu 16.04.6 Desktop with Apache Web Server

This configuration file is used to create a VirtualBox virtual machine with Ubuntu 16.04.6 Desktop and install Apache web server on it using Packer.


# Prerequisites

    Packer
    VirtualBox


# Configuration

This configuration file uses the 'virtualbox-iso' builder to create a VirtualBox virtual machine with Ubuntu 16.04.6 Desktop. The ISO file is downloaded from the URL specified in 'iso_url' and its SHA256 checksum is verified using 'iso_checksum'.

The 'communicator' option is set to SSH which will be used to communicate with the virtual machine. The 'ssh_username' is set to 'ubuntu' which is the default username for Ubuntu virtual machines.

The 'build' section specifies the source of the image and the provisioner to install Apache on the virtual machine. The source is set to 'source.virtualbox-iso.ubuntu' which refers to the 'virtualbox-iso' builder configuration.

The 'provisioner' is set to 'shell' which executes a shell script on the virtual machine. The shell script installs Apache web server and enables its firewall rules.


# Usage

To build the virtual machine, run the following command in the directory containing this configuration file:

packer build build.pkr.hcl 

The resulting virtual machine will have Ubuntu 22.04.2 Desktop with Apache web server installed and ready to use.