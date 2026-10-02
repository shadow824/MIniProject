resource "aws_vpc" "tools" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "depi-sec-tools-vpc" }
}

resource "aws_subnet" "tools_a" {
  vpc_id                  = aws_vpc.tools.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = { Name = "depi-sec-tools-a" }
}

resource "aws_route_table" "tools" {
  vpc_id = aws_vpc.tools.id
  tags   = { Name = "depi-sec-tools-rt" }
}

resource "aws_route_table_association" "tools_a" {
  route_table_id = aws_route_table.tools.id
  subnet_id      = aws_subnet.tools_a.id
}

resource "aws_vpc_peering_connection" "app_tools" {
  vpc_id      = aws_vpc.app.id
  peer_vpc_id = aws_vpc.tools.id
  auto_accept = true

  tags = { Name = "depi-sec-app-tools-peering" }
}

resource "aws_route" "app_to_tools" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}

resource "aws_route" "tools_to_app" {
  route_table_id            = aws_route_table.tools.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.app_tools.id
}
