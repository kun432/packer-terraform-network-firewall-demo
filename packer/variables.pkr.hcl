variable "stage" {
  default = "my"
}

variable "project" {
  default = "sample"
}

variable "host" {
  default = "web"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "region" {
  default = "ap-northeast-1"
}

locals {
  prj_name = "${var.stage}-${var.project}-${var.host}"
}

