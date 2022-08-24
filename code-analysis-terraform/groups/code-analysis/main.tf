# Configure the AWS provider
provider "aws" {
  region  = var.aws_region
  version = "~> 2.0"
}

terraform {
  backend "s3" {
  }
}

# Database instance
module "rds" {
  source                         = "./module-rds"
  env                            = var.tag_environment
  db_allocated_storage           = var.db_allocated_storage
  db_allow_major_version_upgrade = var.db_allow_major_version_upgrade
  db_apply_immediately           = var.db_apply_immediately
  db_backup_retention_period     = var.db_backup_retention_period
  db_backup_window               = var.db_backup_window
  db_buffer_pool_size            = var.db_buffer_pool_size
  db_character_set_client        = var.db_character_set_client
  db_character_set_server        = var.db_character_set_server
  db_collation_connection        = var.db_collation_connection
  db_engine                      = var.db_engine
  db_instance_class              = var.db_instance_class
  db_maintenance_window          = var.db_maintenance_window
  db_max_allowed_packet          = var.db_max_allowed_packet
  db_multi_az                    = var.db_multi_az
  db_password                    = var.db_password
  db_name                        = var.db_name
  db_storage_type                = var.db_storage_type
  db_username                    = var.db_username
  db_version                     = var.db_version
  dns_zone                       = var.dns_zone
  dns_zone_id                    = var.dns_zone_id
  rds_subnet_ids                 = local.application_private_subnet_ids
  service                        = var.tag_service
  vpc_cidr                       = local.vpc_cidr
  vpc_id                         = local.vpc_id
  rds_cidrs                      = concat(local.application_subnet_cidr, local.admin_cidrs)
}

# Machine instance to conduct the code analysis
module "instance" {
  source                  = "./module-instance"
  env                     = var.tag_environment
  admin_cidrs             = local.admin_cidrs
  ami                     = var.ami
  application_subnet      = local.application_subnet_id
  dns_zone                = var.dns_zone
  dns_zone_id             = var.dns_zone_id
  instance_type           = var.instance_type
  private_key_path        = var.private_key_path
  service                 = var.tag_service
  ssh_keyname             = var.ssh_keyname
  vpc_id                  = local.vpc_id
  backup_frequency        = var.backup_frequency
  web_cidrs               = concat(local.admin_cidrs, local.application_subnet_cidr, var.azure_desktop_vm_cidr, local.dmz_subnet, local.build_cidrs)
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------
data "vault_generic_secret" "build_cidrs" {
  path = "aws-accounts/shared-services/build_subnet_cidrs"
}

# ------------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------------
locals {
  availability_zone = "${var.aws_region}a"

  admin_cidrs                       = concat(values(data.terraform_remote_state.management_vpc.outputs.vpn_cidrs), values(data.terraform_remote_state.management_vpc.outputs.internal_cidrs))
  application_subnet_id             = data.terraform_remote_state.management_vpc.outputs.management_private_subnet_ids["${local.availability_zone}"]
  application_subnet_cidr           = [data.terraform_remote_state.management_vpc.outputs.management_private_subnet_cidrs["${local.availability_zone}"]]
  build_cidrs                       = values(data.vault_generic_secret.build_cidrs.data)
  dmz_subnet                        = [data.terraform_remote_state.management_vpc.outputs.dmz_subnet]
  vpc_id                            = data.terraform_remote_state.management_vpc.outputs.management_vpc_id
  vpc_cidr                          = data.terraform_remote_state.management_vpc.outputs.management_vpc_cidr
  application_private_subnet_ids    = values(data.terraform_remote_state.management_vpc.outputs.management_private_subnet_ids)
}

# ------------------------------------------------------------------------------
# Remote State
# ------------------------------------------------------------------------------
data "terraform_remote_state" "management_vpc" {
  backend = "s3"
  config = {
    bucket = "development-${var.aws_region}.terraform-state.ch.gov.uk"
    key    = "aws-common-infrastructure-terraform/common-${var.aws_region}/networking.tfstate"
    region = var.aws_region
  }
}
