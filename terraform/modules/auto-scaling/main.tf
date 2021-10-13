variable "prj_name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "instance_profile" {}
variable "vpc_id" {}
variable "protected_sg_id" {}
variable "private_sg_id" {}
variable "protected_subnet_ids" {}
variable "protected_subnet_cidrs" {}
variable "private_subnet_ids" {}
variable "lb_log_bucket" {}

resource "aws_launch_template" "web" {
  name                   = "${var.prj_name}-web-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.private_sg_id]
  update_default_version = true

  iam_instance_profile {
    name = var.instance_profile
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "${var.prj_name}-web-asg-"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 60
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [ aws_lb_target_group.web.arn ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment#with-an-autoscaling-group-resource
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key   = "Name"
    value = "${var.prj_name}-web-asg"
    propagate_at_launch = true
  }
}

resource "aws_eip" "nlb1" {
  vpc      = true
}

resource "aws_eip" "nlb2" {
  vpc      = true
}

resource "aws_lb" "web" {
  name               = "${var.prj_name}-web-nlb"
  internal           = false
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id     = var.protected_subnet_ids[0]
    allocation_id = aws_eip.nlb1.id
  }

  subnet_mapping {
    subnet_id     = var.protected_subnet_ids[1]
    allocation_id = aws_eip.nlb2.id
  }
#  access_logs {
#    bucket  = var.lb_log_bucket
#    prefix  = "web-nlb"
#    enabled = true
#  }

  tags = {
    Name = "${var.prj_name}-web-nlb"
  }
}

resource "aws_lb_target_group" "web" {
  # https://thaim.hatenablog.jp/entry/2021/01/11/004738
  name     = "${var.prj_name}-tgtgrp-${substr(uuid(), 0, 3)}"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    interval            = 30
    port                = 80
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  } 

  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

output http_private_ips  { value = [ "${aws_eip.nlb1.private_ip}/32", "${aws_eip.nlb2.private_ip}/32" ] }