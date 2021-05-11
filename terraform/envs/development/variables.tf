variable "stage" {
  default = "my"
}

variable "project" {
  default = "sample"
}

locals {
  prj_name = "${var.stage}-${var.project}"
}

variable "region" {
  default = "ap-northeast-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "web_ami_id" {
  default = "ami-XXXXXXXXXXXXXXXXX"
}

variable "web_instance_type" {
  default = "t2.micro"
}