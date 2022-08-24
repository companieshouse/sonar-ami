# Database
variable "db_allocated_storage" {
  # Gigabytes
  default = 10
  type = number
}

variable "db_backup_retention_period" {
  # Days
  default = 14
  type = number
}

variable "db_backup_window" {
  # UTC
  default = "21:00-22:00"
  type = string
}

variable "db_buffer_pool_size" {
  # 80% machine memory ~ 1.5 GB
  default = 1610612736
  type = number
}

variable "db_character_set_client" {
  default = "utf8"
  type = string
}

variable "db_character_set_server" {
  default = "utf8"
  type = string
}

variable "db_collation_connection" {
  default = "utf8_bin"
  type = string
}

variable "db_engine" {
  default = "postgres"
  type = string
}

variable "db_instance_class" {
  default = "db.t2.small"
  type = string
}

variable "db_maintenance_window" {
  # UTC
  default = "fri:22:00-sat:00:00"
  type = string
}

variable "db_max_allowed_packet" {
  # 256 MB
  default = "268435456"
  type = string
}

variable "db_multi_az" {
  default = true
  type = bool
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_storage_type" {
  type = string
  default = "gp2"
}

variable "db_username" {
  type = string
}

variable "db_version" {
  default = 9.6
  type = number
}

variable "db_allow_major_version_upgrade" {
  description = "Controls whether to allow major version upgrades (true) or not (false)"
  type        = bool
  default     = false
}

variable "db_apply_immediately" {
  description = "Controls whether DB changes are applied immediately (true) or in the next maintenance window (false)"
  type        = bool
  default     = false
}

# DNS
variable "dns_zone" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

# Instance
variable "ami" {
  # Centos 7 / Ireland
  default = "ami-0d063c6b"
  type = string
}

variable "instance_type" {
  type = string
  default = "t2.large"
}

# Networking
variable "azure_desktop_vm_cidr" {
  type = list(string)
}

# Region
variable "aws_region" {
  type = string
}

# SSH
variable "ssh_keyname" {
  type = string
}

variable "private_key_path" {
    default = "~/.ssh/platform.pem"
    type = string
}

# Tags
variable "tag_environment" {
  type = string
}

variable "tag_service" {
  type = string
}

variable "backup_frequency" {
  type = string
}
