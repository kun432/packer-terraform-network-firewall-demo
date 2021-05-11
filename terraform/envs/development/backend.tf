terraform {
  backend "s3" {
    bucket = "my-network-firewall-sample"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}