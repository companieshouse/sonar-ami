data "aws_subnet_ids" "application-subnets" {
  vpc_id = var.vpc_id
  filter {
    name   = "tag:Name"
    values = ["dev-management-private-*"]
  }
}


data "aws_vpc_peering_connection" "dev_management_ireland" {
  vpc_id = var.vpc_id

  tags   = {
    Name = "dev-management-ireland to dev-management-london"
  }
}

# Security group for Code Analysis Instance internal communication
resource "aws_security_group" "code-analysis" {
  name   = "${var.service}-${var.env}-security-group"
  vpc_id = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.service}-${var.env}-security-group"
    Environment = var.env
    Service     = var.service
  }
}

resource "aws_security_group_rule" "code-analysis-internal" {
  security_group_id = aws_security_group.code-analysis.id
  type               = "ingress"
  from_port          = 22
  to_port            = 22
  protocol           = "tcp"
  cidr_blocks        = var.admin_cidrs

}

resource "aws_security_group_rule" "code-analysis-internal-sonar" {
  security_group_id        = aws_security_group.code-analysis.id
  type                     = "ingress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.code-analysis-external.id

}

resource "aws_security_group_rule" "code-analysis-internal-egress" {
  security_group_id = aws_security_group.code-analysis.id
  type               = "egress"
  from_port          = 0
  to_port            = 0
  protocol           = "-1"
  cidr_blocks        = ["0.0.0.0/0"]

}

resource "aws_security_group" "code-analysis-external" {
  name   = "${var.service}-${var.env}-external-security-group"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  ingress {
    description = "Sonar"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = concat(var.web_cidrs, [
      data.aws_vpc_peering_connection.dev_management_ireland.peer_cidr_block
    ])
  }

  ingress {
    description = "HTTPS - Internal and VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.web_cidrs, [
      data.aws_vpc_peering_connection.dev_management_ireland.peer_cidr_block
    ])
  }
  ingress {
    description = "HTTP - Internal and VPN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(var.web_cidrs, [
      data.aws_vpc_peering_connection.dev_management_ireland.peer_cidr_block
    ])
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service}-${var.env}-external-security-group"
    Environment = var.env
    Service     = var.service
  }
}

resource "aws_instance" "code-analysis" {
  count                                = 1
  ami                                  = var.ami
  instance_type                        = var.instance_type
  instance_initiated_shutdown_behavior = "stop"
  subnet_id                            = var.application_subnet
  key_name                             = var.ssh_keyname
  vpc_security_group_ids               = [aws_security_group.code-analysis.id]
  associate_public_ip_address          = false

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  tags = {
    Name         = "${var.service}-${var.env}"
    Environment  = var.env
    Service      = var.service
    HostName     = "${var.service}.${var.env}.${var.dns_zone}"
    Domain       = "${var.service}.${var.env}.${var.dns_zone}"
    AnsibleGroup = "${var.service}-${var.env}"
    Snapshot     = var.backup_frequency
  }

  volume_tags = {
    Name        = "${var.env}-${var.service}"
    Environment = var.env
    Service     = var.service
    RootDevice  = "true"
    Snapshot    = var.backup_frequency
  }

  # Set hostname
  provisioner "remote-exec" {
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "centos"
      private_key = file(var.private_key_path)
    }

    inline = [
      "sudo setenforce 0",
      "sudo hostname ${var.service}.${var.env}.${var.dns_zone}",
    ]
  }
}

# Create Route53 entry
resource "aws_route53_record" "code-analysis" {
  zone_id = var.dns_zone_id
  name    = "${var.service}.${var.env}.${var.dns_zone}"
  type    = "A"
  alias {
    evaluate_target_health = true
    name                  = aws_lb.code-analysis.dns_name
    zone_id               = aws_lb.code-analysis.zone_id
  }
}

resource "aws_lb" "code-analysis" {
  name                       = "${var.service}-${var.env}-lb"
  subnets                    = data.aws_subnet_ids.application-subnets.ids
  security_groups            = [aws_security_group.code-analysis-external.id]
  load_balancer_type         = "application"
  idle_timeout               = 60
  enable_deletion_protection = false
  internal = true
  tags = {
    Name        = "${var.service}-${var.env}-lb"
    Environment = var.env
    Service     = var.service
  }
}

resource "aws_lb_listener" "code-analysis-https" {
  load_balancer_arn = aws_lb.code-analysis.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = aws_acm_certificate.code-analysis[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.code-analysis.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "code-analysis-http-9000" {
  load_balancer_arn = aws_lb.code-analysis.arn
  port              = 9000
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      protocol = "HTTPS"
      status_code = "HTTP_301"
      port = "443"
    }
  }
}

resource "aws_lb_listener" "code-analysis-http" {
  load_balancer_arn = aws_lb.code-analysis.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "code-analysis" {
  name        = "${var.service}-${var.env}-lb-tg"
  target_type = "instance"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    interval            = 60
    port                = 9000
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.service}-${var.env}-lb-tg"
    Environment = var.env
    Service     = var.service
  }
}

resource "aws_acm_certificate" "code-analysis" {
  count                     = 1
  domain_name               = "${var.service}.${var.env}.${var.dns_zone}"
  subject_alternative_names = ["*.${var.service}.${var.env}.${var.dns_zone}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  name    = aws_acm_certificate.code-analysis[0].domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.code-analysis[0].domain_validation_options[0].resource_record_type
  zone_id = var.dns_zone_id
  records = [aws_acm_certificate.code-analysis[0].domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "certificate" {
  certificate_arn         = aws_acm_certificate.code-analysis[0].arn
  validation_record_fqdns = [aws_route53_record.certificate_validation.fqdn]
}

resource "aws_lb_target_group_attachment" "code-analysis" {
  target_group_arn = aws_lb_target_group.code-analysis.arn
  target_id        = aws_instance.code-analysis[0].id
  port             = 9000
}