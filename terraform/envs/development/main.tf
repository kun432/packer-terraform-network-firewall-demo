provider "aws" {
  region  = var.region
}

module "vpc" {
  source   = "../../modules/vpc"
  prj_name = local.prj_name
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

module "ssm" {
  source   = "../../modules/ssm"
  prj_name = local.prj_name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}

