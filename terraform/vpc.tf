resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "depi-sec-app-vpc" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = { Name = "depi-sec-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = { Name = "depi-sec-public-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = { Name = "depi-sec-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = { Name = "depi-sec-private-b" }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "depi-sec-app-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  tags = { Name = "depi-sec-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_b.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "depi-sec-private-rt" }
}

resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_a.id
}

resource "aws_route_table_association" "private_b" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_b.id
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "depi-sec-private-nacl" }
}

resource "aws_network_acl_rule" "private_ingress_80" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_ingress_443" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "private_ingress_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_ingress_efs" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 125
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 2049
  to_port        = 2049
}

resource "aws_network_acl_rule" "private_ingress_ssh_deny" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Peering-specific rules are needed because NACLs are stateless.
resource "aws_network_acl_rule" "private_ingress_tools_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.1.1.0/24"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_ingress_tools_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 140
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.1.1.0/24"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_egress_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
}

resource "aws_network_acl_rule" "private_egress_tools" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 105
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.1.1.0/24"
}

resource "aws_network_acl_rule" "private_egress_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_association" "private_a" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_a.id
}

resource "aws_network_acl_association" "private_b" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_b.id
}
