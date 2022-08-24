# Create a db subnet group using the private subnets
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.service}-${var.env}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids

  tags = {
    "Name"        = "${var.service}-${var.env}-db-subnet-group"
    "Service"     = var.service
    "Environment" = var.env
  }
}

# Create a security group for the RDS instance
resource "aws_security_group" "rds-security-group" {
  name   = "${var.service}-${var.env}-rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    description = "Postgresql - Application"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.rds_cidrs
  }

  tags = {
    Name        = "${var.service}-${var.env}-rds-security-group"
    Environment = var.env
    Service     = var.service
  }
}

# Create an RDS instance
resource "aws_db_instance" "code-analysis" {
  allocated_storage           = var.db_allocated_storage
  db_subnet_group_name        = aws_db_subnet_group.rds-subnet-group.id
  engine                      = var.db_engine
  engine_version              = var.db_version
  final_snapshot_identifier   = "${var.service}-${var.env}-${var.db_engine}db-final-snapshot"
  identifier                  = "${var.service}-${var.env}-${var.db_engine}db"
  instance_class              = var.db_instance_class
  multi_az                    = var.db_multi_az
  name                        = var.db_name
  password                    = var.db_password
  backup_retention_period     = var.db_backup_retention_period
  backup_window               = var.db_backup_window
  maintenance_window          = var.db_maintenance_window
  storage_type                = var.db_storage_type
  username                    = var.db_username
  allow_major_version_upgrade = var.db_allow_major_version_upgrade
  apply_immediately           = var.db_apply_immediately
  vpc_security_group_ids      = [aws_security_group.rds-security-group.id]

  tags = {
    "Name"        = "${var.service}-${var.env}-${var.db_engine}db"
    "Service"     = var.service
    "Environment" = var.env
  }
}

# Create Route53 entry
resource "aws_route53_record" "code-analysis-db" {
  zone_id = var.dns_zone_id
  name    = "db.${var.service}.${var.env}.${var.dns_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.code-analysis.address]
}
