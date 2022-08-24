# DNS
variable "dns_zone" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

# Environment
variable "env" {
  type = string
}

variable "service" {
  type = string
}

# Instance
variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "backup_frequency" {
  type = string
}

# Networking
variable "admin_cidrs" {
  type = list(string)
}

variable "web_cidrs" {
  type = list(string)
}

variable "application_subnet" {
  type = string
}

variable "vpc_id" {
  type = string
}

# SSH
variable "private_key_path" {
  type = string
}

variable "ssh_keyname" {
  type = string
}
