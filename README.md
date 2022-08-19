# Sonarqube Packer Build

Uses Packer and Ansible to create a Sonarqube Amazon Machine Image (AMI).


## Packer

All Packer configuration resides in the `./packer` directory and utilises standard Packer configuration syntax.


## Ansible

All Ansible configuration resides in the `./ansible` directory. The Ansble configuration will be called during the provisioning step of the Packer build as defined in `./packer/build.pkr.hcl`.

This template provides the basic code layout and structure only.