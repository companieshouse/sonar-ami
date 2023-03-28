# Sonarqube Packer Build

Uses Packer and Ansible to create a Sonarqube Amazon Machine Image (AMI).


## Packer

All Packer configuration resides in the `./packer` directory and utilises standard Packer configuration syntax.


## Ansible

All Ansible configuration resides in the `./ansible` directory. The Ansble configuration will be called during the provisioning step of the Packer build as defined in `./packer/build.pkr.hcl`.

This template provides the basic code layout and structure only.

## Application

This playbook follows the requirements as of 26/08/2022

SonarQube install requirements are found here:
https://docs.sonarqube.org/latest/requirements/requirements/

Potential issue with: (https://community.sonarsource.com/t/access-denied-java-lang-runtimepermission-accessclassinpackage-jdk-internal-org-objectweb-asm/62016)
No notable impact found.

Some items in this playbook are referenced from:
https://github.com/lrk/ansible-role-sonarqube