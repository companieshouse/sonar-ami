# code-analysis-terraform

## Introduction

These scripts are used to provision the code analysis server

## Prerequisites

### Software

The scripts have been developed and tested using:

- [Docker](https://www.docker.com/) (18.03.1)
- [Terraform](https://www.terraform.io/) (0.11.7)
- [Python](https://www.python.org/) (2.7.15)

## AWS Credentials

AWS credentials are supplied via the `AWS_PROFILE` environmental variables. If you do not have this set you cannot run the playbook. You can either export this in your current shell or preferably add it to your `~/.bash_profile`

## EC2 Pem Key
Currently, you will need a copy of the **development-infrastructure** pem key to administer the instance. You will need to create a hard link to the environment name e.g. **platform** in which the key is associated with

```
ln development-infrastructure.pem platform.pem
```

## Terraform

These scripts make use of Terraform. The [Terraform Documentation](https://www.terraform.io/docs) provides all the information you might need about this tool.

## Modules

There are two modules:

- Instance<br />Responsible for provisioning an EC2 instance to run the analysis software
- RDS<br />Responsible for provisioning an RDS instance for persistence

## Variables

| Name                    | Description                                                          | Example                         |
|-------------------------|----------------------------------------------------------------------|---------------------------------|
| db_allocated_storage    | The allocated storage in gigabytes                                   | 10                              |
| db_engine               | The database engine to use                                           | mysql                           |
| db_instance_class       | The EC2 instance type of RDS instance                                | db.t2.micro                     |
| db_multi_az             | Indicates whether or not the RDS instance is multi availability zone | false                           |
| db_password             | The database password                                                | password                        |
| db_schema_name          | The database schema name                                             | schema                          |
| db_storage_type         | The type of storage employed (magentic/SSD etc)                      | gp2                             |
| db_username             | The database username                                                | username                        |
| db_version              | The database version                                                 | 5.7.17                          |
| dns_zone                | The DNS zone in which to place the instances                         | aws.somewhere.org               |
| dns_zone_id             | The route 53 zone id                                                 | Z1R8UBAEXAMPLE                  |
| ami                     | The instance ami to use                                              | ami-0d063c6b                    |
| instance_type           | The instance type to use                                             | t2.large                        |
| application_subnet      | The subnet into which the instance will be placed                    | subnet-abcd1234                 |
| application_subnet_cidr | The CIDR for the specified application subnet                        | 10.0.1.0/24                     |
| internal_cidrs          | The CIDRs for internal access                                        | 10.0.2.0/24                     |
| rds_subnet_ids          | The subnets used to form the RDS subnet group                        | subnet-abcd1234,subnet-abcd5678 |
| vpc_cidr                | The CIDR for the VPC in which we're creating an instance             | 10.0.3.0/24                     |
| vpc_id                  | The id of the VPC in which we're creating an instance                | vpc-abcd1234                    |
| vpn_cidrs               | The CIDRs for VPN access                                             | 10.0.4.0/24                     |
| aws_region              | The AWS region in which we're administering resources                | eu-west-1                       |
| ssh_keyname             | The name of the SSH key we're using to manage instances              | my-key                          |
| private_key_path        | The local path to the pem key file we're using                       | ~/.ssh/my-key.pem               |
| bucket                  | The S3 bucket in which we're storing Terraform state                 | ch-development-terraform-state  |
| STATEFILE_NAME          | The name of the Terraform state file                                 | code-analysis.tfstate           |
| tag_environment         | The environment tag to apply to instances                            | development                     |
| tag_service             | The service tag to apply to instances                                | code-analysis                   |

## State

Terraform state is stored remotely in an S3 bucket. The region, state bucket name, and workspace prefix are determined dynamically based on the configuration of the host environment and the `AWS_PROFILE` environment variable.

An example of a defined state:  

```
AWS Profile: development-eu-west-1
Environment: platform
Region: eu-west-1
Bucket: development-eu-west-1.terraform-state.ch.gov.uk
Workspace key prefix: code-analysis-terraform
Workspace: platform
State file: code-analysis.tfstate
State file path: development-eu-west-1.terraform-state.ch.gov.uk/code-analysis-terraform/platform/code-analysis.tfstate
```

## Applying infrastructure changes

These scripts can be run using Companies House Terraform-runner.

View the [terraform-runner usage instructions](https://companieshouse.atlassian.net/wiki/spaces/DEVOPS/pages/1694236886/Terraform-runner).
