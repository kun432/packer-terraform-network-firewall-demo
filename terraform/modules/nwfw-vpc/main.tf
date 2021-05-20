variable "prj_name" {}
variable "region" {}
variable "vpc_cidr" {}
variable "nwfw_log_bucket" {}

resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "${var.prj_name}-vpc"
  }
}

# Network Firewall Segment
resource "aws_subnet" "subnet_firewall_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 0)
  availability_zone = "${var.region}c"

  tags = {
    Name = "${var.prj_name}-subnet-firewall-c"
  }
}

resource "aws_subnet" "subnet_firewall_d" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  availability_zone = "${var.region}d"

  tags = {
    Name = "${var.prj_name}-subnet-firewall-d"
  }
}

resource "aws_networkfirewall_rule_group" "ips" {
  capacity = 100
  name     = "ips"
  type     = "STATEFUL"
  #rules    = file("${path.module}/rules/sample-rules.txt")
  rule_group  {
    rules_source {
      rules_string = file("${path.module}/rules/sample-suricata-rules.txt")
    }
    rule_variables {
      ip_sets {
        key = "EXTERNAL_NET"
        ip_set {
          definition = ["0.0.0.0/0"]
        }
      }

      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.vpc_cidr]
        }
      }
      port_sets {
        key = "HTTP_PORTS"
        port_set {
          definition = ["[80,443]"]
        }
      }
    }
  }
  tags = {
    Name = "${var.prj_name}-nwfw-rules-ips"
  }
}

resource "aws_networkfirewall_firewall_policy" "firewall" {
  name = "${var.prj_name}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.ips.arn
    }
  }

  tags = {
    Name = "${var.prj_name}-subnet-firewall-initial-policy"
  }
}

resource "aws_networkfirewall_firewall" "firewall" {
  name                = "${var.prj_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall.arn
  vpc_id              = aws_vpc.vpc.id

  subnet_mapping {
    subnet_id     = aws_subnet.subnet_firewall_c.id
  }
  subnet_mapping {
    subnet_id     = aws_subnet.subnet_firewall_d.id
  }

  tags = {
    Name = "${var.prj_name}-firewall"
  }
}

resource "aws_networkfirewall_logging_configuration" "firewall" {
  firewall_arn = aws_networkfirewall_firewall.firewall.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        bucketName = var.nwfw_log_bucket
        prefix = "nwfw"
      }
      log_destination_type = "S3"
      log_type             = "ALERT"
    }
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prj_name}-igw"
  }
}


# NAT Segment
resource "aws_subnet" "subnet_protected_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  availability_zone = "${var.region}c"

  tags = {
    Name = "${var.prj_name}-subnet-protected-c"
  }
}

resource "aws_subnet" "subnet_protected_d" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3)
  availability_zone = "${var.region}d"

  tags = {
    Name = "${var.prj_name}-subnet-protected-d"
  }
}

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
  subnet_id     = aws_subnet.subnet_protected_c.id

  tags = {
    Name = "${var.prj_name}-natgw-c"
  }
}

resource "aws_nat_gateway" "natgw_d" {
  allocation_id = aws_eip.eip_natgw_d.id
  subnet_id     = aws_subnet.subnet_protected_d.id

  tags = {
    Name = "${var.prj_name}-natgw-d"
  }
}

# Private Segment
resource "aws_subnet" "subnet_private_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 4)
  availability_zone = "${var.region}c"

  tags = {
    Name = "${var.prj_name}-subnet-private-c"
  }
}

resource "aws_subnet" "subnet_private_d" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 5)
  availability_zone = "${var.region}d"

  tags = {
    Name = "${var.prj_name}-subnet-private-d"
  }
}

resource "aws_route_table" "rtb_igw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = aws_subnet.subnet_protected_c.cidr_block
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.subnet_firewall_c.id], 0)
  }
  
  route {
    cidr_block = aws_subnet.subnet_protected_d.cidr_block
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.subnet_firewall_d.id], 0)
  }

  tags = {
    Name = "${var.prj_name}-rtb-igw"
  }
}

resource "aws_route_table_association" "rtb_assoc_igw" {
  gateway_id = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.rtb_igw.id
}

resource "aws_route_table" "rtb_firewall" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.prj_name}-rtb-firewall"
  }
}

resource "aws_route_table_association" "rtb_assoc_firewall_c" {
  route_table_id = aws_route_table.rtb_firewall.id
  subnet_id      = aws_subnet.subnet_firewall_c.id
}

resource "aws_route_table_association" "rtb_assoc_firewall_d" {
  route_table_id = aws_route_table.rtb_firewall.id
  subnet_id      = aws_subnet.subnet_firewall_d.id
}

resource "aws_route_table" "rtb_protected_c" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.subnet_firewall_c.id], 0)
  }

  tags = {
    Name = "${var.prj_name}-rtb-protected-c"
  }
}

resource "aws_route_table" "rtb_protected_d" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.subnet_firewall_d.id], 0)
  }

  tags = {
    Name = "${var.prj_name}-rtb-protected-d"
  }
}
resource "aws_route_table_association" "rtb_assoc_protected_c" {
  route_table_id = aws_route_table.rtb_protected_c.id
  subnet_id      = aws_subnet.subnet_protected_c.id
}

resource "aws_route_table_association" "rtb_assoc_protected_d" {
  route_table_id = aws_route_table.rtb_protected_d.id
  subnet_id      = aws_subnet.subnet_protected_d.id
}

resource "aws_route_table" "rtb_private_c" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_c.id
  }

  tags = {
    Name = "${var.prj_name}-rtb-private-c"
  }
}

resource "aws_route_table" "rtb_private_d" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw_d.id
  }

  tags = {
    Name = "${var.prj_name}-rtb-private-d"
  }
}

resource "aws_route_table_association" "rtb_assoc_private_c" {
  route_table_id = aws_route_table.rtb_private_c.id
  subnet_id      = aws_subnet.subnet_private_c.id
}

resource "aws_route_table_association" "rtb_assoc_private_d" {
  route_table_id = aws_route_table.rtb_private_d.id
  subnet_id      = aws_subnet.subnet_private_d.id
}

output vpc_id { value = aws_vpc.vpc.id }
output vpc_cidr { value = aws_vpc.vpc.cidr_block }
output private_subnet_ids  { value = [ aws_subnet.subnet_private_c.id, aws_subnet.subnet_private_d.id ] }
output protected_subnet_ids  { value = [ aws_subnet.subnet_protected_c.id, aws_subnet.subnet_protected_d.id ] }