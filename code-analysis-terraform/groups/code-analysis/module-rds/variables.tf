# Environment
variable "env" {
  type = string
}

variable "service" {
  type = string
}

# Database
variable "db_allocated_storage" {
  type = number
}

variable "db_backup_retention_period" {
  type = number
}

variable "db_backup_window" {
  type = string
}

variable "db_buffer_pool_size" {
  type = number
}

variable "db_character_set_client" {
  type = string
}

variable "db_character_set_server" {
  type = string
}

variable "db_collation_connection" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_maintenance_window" {
  type = string
}

variable "db_max_allowed_packet" {
  type = string
}

variable "db_multi_az" {
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
}

variable "db_username" {
  type = string
}

variable "db_version" {
  type = string
}

variable "db_allow_major_version_upgrade" {
  type = bool
}

variable "db_apply_immediately" {
  type = bool
}

# DNS
variable "dns_zone" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

# Networking
variable "rds_cidrs" {
  type = list(string)
}

variable "rds_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}
