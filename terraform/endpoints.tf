# App VPC endpoints: three interface endpoints required for Session Manager + S3 gateway endpoint.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.app.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.app.arn,
        "${aws_s3_bucket.app.arn}/*",
        "arn:aws:s3:::al2023-repos-us-east-1-de612dc2",
        "arn:aws:s3:::al2023-repos-us-east-1-de612dc2/*"
      ]
    }]
  })

  tags = { Name = "depi-sec-s3-endpoint" }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-ssm-endpoint" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-ssmmessages-endpoint" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-ec2messages-endpoint" }
}

# The monitoring instance is also private. These endpoints let it use Session Manager
# without adding a NAT Gateway or a public IP.
resource "aws_security_group" "tools_endpoint" {
  name        = "depi-sec-tools-endpoint-sg"
  description = "HTTPS from tools subnet to SSM interface endpoints"
  vpc_id      = aws_vpc.tools.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "depi-sec-tools-endpoint-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "tools_endpoint_https" {
  security_group_id = aws_security_group.tools_endpoint.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "10.1.1.0/24"
}

resource "aws_vpc_endpoint" "tools_s3" {
  vpc_id            = aws_vpc.tools.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.tools.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.app.arn,
        "${aws_s3_bucket.app.arn}/*",
        "arn:aws:s3:::al2023-repos-us-east-1-de612dc2",
        "arn:aws:s3:::al2023-repos-us-east-1-de612dc2/*"
      ]
    }]
  })

  tags = { Name = "depi-sec-tools-s3-endpoint" }
}

resource "aws_vpc_endpoint" "tools_ssm" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_a.id]
  security_group_ids  = [aws_security_group.tools_endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-tools-ssm-endpoint" }
}

resource "aws_vpc_endpoint" "tools_ssmmessages" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_a.id]
  security_group_ids  = [aws_security_group.tools_endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-tools-ssmmessages-endpoint" }
}

resource "aws_vpc_endpoint" "tools_ec2messages" {
  vpc_id              = aws_vpc.tools.id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.tools_a.id]
  security_group_ids  = [aws_security_group.tools_endpoint.id]
  private_dns_enabled = true

  tags = { Name = "depi-sec-tools-ec2messages-endpoint" }
}
