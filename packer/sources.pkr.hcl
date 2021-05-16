data "amazon-ami" "amazon_linux2" {
  filters = {
    name = "amzn2-ami-hvm-*-x86_64-gp2"
  }
  most_recent = true
  owners      = ["137112412989"]
  region      = "ap-northeast-1"
}

source "amazon-ebs" "webserver" {
  region        = var.region
  source_ami    = data.amazon-ami.amazon_linux2.id
  instance_type = var.instance_type
  ssh_username  = "ec2-user"
  ssh_timeout   = "5m"
  ami_name      = "${local.prj_name}-{{ timestamp }}"
  tags = {
    Base_AMI_ID = "{{ .SourceAMI }}"
    Base_AMI_NAME = "{{ .SourceAMIName }}"
    Amazon_AMI_Management_Identifier = local.prj_name
  } 
}

