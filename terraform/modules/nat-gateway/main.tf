variable "prj_name" {}
variable "private_rtb_id_c" {}
variable "private_rtb_id_d" {}
variable "nat_subnet_id_c" {}
variable "nat_subnet_id_d" {}

resource "aws_eip" "eip_natgw_c" {
  vpc = true
  tags = {
    Name = "${var.prj_name}-eip-natgw-c"
  }
}

resource "aws_eip" "eip_natgw_d" {
  vpc = true
  tags = {
    Name = "${var.prj_name}-eip-natgw-d"
  }
}

resource "aws_nat_gateway" "natgw_c" {
  allocation_id = aws_eip.eip_natgw_c.id
  subnet_id     = var.nat_subnet_id_c

  tags = {
    Name = "${var.prj_name}-natgw-c"
  }
}

resource "aws_nat_gateway" "natgw_d" {
  allocation_id = aws_eip.eip_natgw_d.id
  subnet_id     = var.nat_subnet_id_d

  tags = {
    Name = "${var.prj_name}-natgw-d"
  }
}

resource "aws_route" "route_to_nat_c" {
  route_table_id         = var.rtb_id_c
  nat_gateway_id         = aws_nat_gateway.natgw_c.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_to_nat_d" {
  route_table_id         = var.rtb_id_c
  nat_gateway_id         = aws_nat_gateway.natgw_c.id
  destination_cidr_block = "0.0.0.0/0"
}