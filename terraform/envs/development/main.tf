module "s3" {
  source   = "../../modules/s3"
  prj_name = local.prj_name
}

module "nwfw-vpc" {
  source           = "../../modules/nwfw-vpc"
  prj_name         = local.prj_name
  region           = var.region
  vpc_cidr         = var.vpc_cidr
  http_permit_ips  = var.http_permit_ips
  nwfw_log_bucket  = module.s3.nwfw_log_bucket
  http_private_ips = module.auto-scaling.http_private_ips
}

module "ssm" {
  source             = "../../modules/ssm"
  prj_name           = local.prj_name
  vpc_id             = module.nwfw-vpc.vpc_id
  vpc_cidr           = module.nwfw-vpc.vpc_cidr
  private_subnet_ids = module.nwfw-vpc.private_subnet_ids
}

module "security-groups" {
  source   = "../../modules/security-groups"
  prj_name = local.prj_name
  vpc_id   = module.nwfw-vpc.vpc_id
  vpc_cidr = module.nwfw-vpc.vpc_cidr
}

module "auto-scaling" {
  source               = "../../modules/auto-scaling"
  prj_name             = local.prj_name
  ami_id               = var.web_ami_id
  instance_type        = var.web_instance_type
  instance_profile     = module.ssm.ssm_instance_profile
  vpc_id               = module.nwfw-vpc.vpc_id
  protected_sg_id      = module.security-groups.protected_sg_id
  private_sg_id        = module.security-groups.private_sg_id
  protected_subnet_ids = module.nwfw-vpc.protected_subnet_ids
  protected_subnet_cidrs = module.nwfw-vpc.protected_subnet_cidrs
  private_subnet_ids   = module.nwfw-vpc.private_subnet_ids
  lb_log_bucket        = module.s3.lb_log_bucket
}
