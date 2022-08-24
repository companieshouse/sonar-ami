# code-analysis-ansible

## Introduction

These scripts are used to provision and upgrade the code analysis (SonarQube) server software

## Prerequisites

### Software

The scripts have been developed and tested using:

- [Ansible](https://www.ansible.com/) (2.7.9)
- [Docker](https://www.docker.com/) (18.03.1)
- [python](https://www.python.org/downloads/mac-osx/)(2.6)
  - [pip](https://pip.pypa.io/en/stable/installing/) (1.3.1)
- [Vagrant](https://www.vagrantup.com/) (2.0.1)

## AWS Credentials

It is recommend to use the AWS SSO service for AWS access.  You will need to be signed into the `development` account in `eu-west-1`.  You should use `yawsso` as this will sync your temporary credentials.  See the AWS SSO User Guide on Confluence for full instructions.


## EC2 Pem Key
You will need a copy of the **development-infrastructure** pem key to administer the platform instance (live) and the **development-sandbox.pem** key for the sandbox instance (test)

## Ansible

These scripts make use of [Ansible](https://www.ansible.com/get-started)

## Ansible Vault
Currently you will need a copy of the Ansible Vault password to run this playbook. Please ask in **#dev-ops** Slack channel

## Docker

These scripts can be run with an Ansible Docker image. If you do not have Ansible installed or your version differs to the required version of Ansible to run this playbook (2.7.9) then you can run it using this method. Documentation can be found [here](https://docs.docker.com/)

## Docker Configuration

Docker will need to have the following configuration settings:
#### Manual proxy configuration:

```sh
# Web Server (HTTP):
websenseproxy.internal.ch:8080

# Secure Web Server (HTTPS):
websenseproxy.internal.ch:8080

# Bypass proxy settings for these hosts & domains:
repository.aws.chdev.org
```

## Vagrant
For local development a Vagrant configuration has been provided. It can be created by running:

```sh
vagrant up
```

This will create a box called **code-analysis.vagrant** ready for Ansible to be run against (see below).

## Vagrant Configuration

Vagrant will need to have a SSH key present in the following directory:

```sh
"~/.ssh/vagrant"
```
To generate a new SSH key, open a terminal and follow the instructions below:

```sh
# Paste the text below, substituting in your GitHub email address.
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# This creates a new ssh key, using the provided email as a label.
Generating public/private rsa key pair.

# When you're prompted to "Enter a file in which to save the key," press Enter. This accepts the default file location.
Enter a file in which to save the key (/Users/you/.ssh/vagrant): [Press enter]

# At the prompt, leave passphrase empty.
[Press enter]
```

Vagrant will need to have the following plugins:

* vagrant-hostmanager (1.8.8)
* vagrant-proxyconf (1.5.2)
* vagrant-vbguest (0.15.2)

## Roles

There are three roles:

- sonar - Install and configure the SonarQube server (also used for upgrading SonarQube versions)
- postgres - Install Postgres database for use on Vagrant
- insecure-docker-registries - Configure Docker which is used to install Postgres

## Tagging

There are options to run specific tasks within the Sonar role as you may not want to provision the whole playbook after the initial setup. We can do this by using one of the available tags when running the provisioning scripts. An example of running with a tag can be found below.

## Running

This playbook can be run in two ways. Natively or through Docker. Each has it's advantages and disadvantages.

## Docker (Recommended)
This is the preferred method as it guarantees the scripts are run against a known environment and avoids versioning issues.

### Advantages:
* Places very few requirements upon the host machine
* Consistent invocation
* Allows invocation of multiple Ansible versions without configuration changes

### Disadvantages:
* Requires Docker
* Requires access to the CH Docker [repository](http://repository.aws.chdev.org:8081/artifactory/webapp)

## Native
This is the simplest to invoke but places particular requirements upon the host machine. Specifically the version on Ansible and it's associated pip dependencies. This can be problematic to administer particularly if you need to run other playbooks requiring different versions of Ansible.

### Advantages:
* Simple to invoke

### Disadvantages:
* Places software requirements upon the host machine
* More complicated invocation

## Typical Operations

## Vagrant
#### Docker
Ensure you run the following command to authenticate your Docker client to your registry beforehand. Please note this token is only valid for 12 hours.

```sh
#For macOS or Linux systems, use the AWS CLI:
$(aws ecr get-login --no-include-email --region eu-west-1)
```

```sh
# provision Sonar
./run-docker-ansible -i vagrant site.yml

# configure sonar plugins
./run-docker-ansible -i vagrant site.yml --tags "configure-sonar"

```
#### Native
```sh
# provision Sonar
./run-ansible -i vagrant site.yml

# configure Sonar
./run-ansible -i vagrant site.yml --tags "configure-sonar"

```
When running, Code Analysis will be available at: [http://code-analysis.vagrant:9000](http://code-analysis.vagrant:9000)

## AWS
#### Docker
Ensure you run the following command to authenticate your Docker client to your registry beforehand. Please note this token is only valid for 12 hours.

```sh
#For macOS or Linux systems, use the AWS CLI:
$(aws ecr get-login --no-include-email --region eu-west-1)
```
```sh
# provision Sonar Platform
./run-docker-ansible -i aws-platform site.yml

# provision Sonar Sandbox
./run-docker-ansible -i aws-sandbox site.yml

# configure Sonar Platform
./run-docker-ansible -i aws-platform site.yml --tags "configure-sonar"

# configure Sonar Sandbox
./run-docker-ansible -i aws-sandbox site.yml --tags "configure-sonar"

```
#### Native
```sh
# provision Sonar Platform
./run-ansible -i aws-platform site.yml

# provision Sonar Sandbox
./run-ansible -i aws-sandbox site.yml

# configure Sonar Platform
./run-ansible -i aws-platform site.yml --tags "configure-sonar"

# configure Sonar Sandbox
./run-ansible -i aws-sandbox site.yml --tags "configure-sonar"

```
When running, Code Analysis will be available at:

**Platform:** [http://code-analysis.platform.aws.chdev.org:9000](http://code-analysis.platform.aws.chdev.org:9000)

**Sandbox:** [http://code-analysis.sandbox.aws.chdev.org:9000](http://code-analysis.sandbox.aws.chdev.org:9000)

## Upgrading SonarQube
**Always check the SonarQube upgrade instructions on their website first for full upgrade details.  Sometimes there may be additional steps required.**

To upgrade the version of SonarQube, you will first need to download the zip and place it the correct AWS S3 bucket and then update the `sonar_version` variable.
Then run the following:
#### Sandbox
```sh
# Download and install the new version
./run-ansible -i aws-sandbox site.yml --tags "install-sonar"

# Stop the current Sonar instance, configure the new version and start it up
./run-ansible -i aws-sandbox site.yml --tags "configure-sonar"

```
Once the service has started, go to  http://code-analysis.sandbox.aws.chdev.org:9000/setup and follow the instructions
#### Platform
```sh
# Download and install the new version
./run-ansible -i aws-platform site.yml --tags "install-sonar"

# Stop the current Sonar instance, configure the new version and start it up
./run-ansible -i aws-platform site.yml --tags "configure-sonar"
````
Once the service has started, go to  http://code-analysis.platform.aws.chdev.org:9000/setup and follow the instructions
