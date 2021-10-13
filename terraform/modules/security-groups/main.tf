variable "prj_name" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

resource "aws_security_group" "protected_sg" {
  name = "${var.prj_name}-protected-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prj_name}-protected-sg"
  }
}

resource "aws_security_group_rule" "protected_allow_http_from_all" {
  type                      = "ingress"
  from_port                 = 80
  to_port                   = 80
  protocol                  = "tcp"
  security_group_id         = aws_security_group.protected_sg.id
  cidr_blocks               = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "protected_allow_all_from_same_vpc" {
  type                      = "ingress"
  from_port                 = 0
  to_port                   = 0
  protocol                  = "-1"
  security_group_id         = aws_security_group.protected_sg.id
  cidr_blocks               = [var.vpc_cidr]
}

resource "aws_security_group" "private_sg" {
  name = "${var.prj_name}-private-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prj_name}-private-sg"
  }
}

resource "aws_security_group_rule" "private_allow_all_from_same_vpc" {
  type                      = "ingress"
  from_port                 = 80
  to_port                   = 80
  protocol                  = "TCP"
  security_group_id         = aws_security_group.private_sg.id
  cidr_blocks               = ["0.0.0.0/0"]
  lifecycle {
    create_before_destroy = true
  }
}

output protected_sg_id {
  value = aws_security_group.protected_sg.id
}

output private_sg_id {
  value = aws_security_group.private_sg.id
}