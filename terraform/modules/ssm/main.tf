variable "prj_name" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "private_subnet_ids" {}

resource "aws_security_group" "endpoint" {
  name   = "endpoint"
  vpc_id = var.vpc_id
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prj_name}-endpoint-ssm"
  }
}

resource "aws_security_group_rule" "endpoint_ingress_https" {
  security_group_id = aws_security_group.endpoint.id
  type              = "ingress"
  cidr_blocks       = [var.vpc_cidr]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  tags = {
    Name = "${var.prj_name}-endpoint-s3"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.prj_name}-endpoint-ssm"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.prj_name}-endpoint-ec2msg"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.prj_name}-endpoint-ssmmsg"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.prj_name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Name = "${var.prj_name}-ssm-role"
  }
}

resource "aws_iam_role_policy" "ssm_role_policy" {
  name = "${var.prj_name}-ssm-role-policy"
  role   = aws_iam_role.ssm_role.id
  policy = data.aws_iam_policy.ssm_core.policy
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${var.prj_name}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

output ssm_instance_profile {
  value = aws_iam_instance_profile.ssm_instance_profile.name
}