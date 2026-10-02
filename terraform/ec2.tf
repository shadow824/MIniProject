locals {
  app_user_data = <<-EOF_USERDATA
    #!/bin/bash
    set -euxo pipefail

    dnf install -y nginx amazon-efs-utils
    systemctl enable --now nginx

    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<html><body><h1>DEPI Secure App</h1><p>Served by $AZ</p></body></html>" > /usr/share/nginx/html/index.html

    mkdir -p /mnt/shared

    # EFS mount targets and DNS can take a short time to become reachable.
    # Retry the mount so first-boot timing does not leave the instance without EFS.
    for attempt in $(seq 1 12); do
      if mountpoint -q /mnt/shared; then
        break
      fi

      if mount -t efs -o tls,accesspoint=${aws_efs_access_point.app.id} ${aws_efs_file_system.app.id}:/ /mnt/shared; then
        break
      fi

      echo "EFS mount attempt $attempt failed; retrying in 10 seconds..."
      sleep 10
    done

    mountpoint -q /mnt/shared || {
      echo "ERROR: EFS could not be mounted after 12 attempts." >&2
      exit 1
    }

    echo "Mounted EFS on $AZ" > /mnt/shared/$AZ.txt
  EOF_USERDATA
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = false
  user_data                   = local.app_user_data

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = { Name = "depi-sec-app-a" }

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages,
    aws_efs_mount_target.a
  ]
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = false
  user_data                   = local.app_user_data

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = { Name = "depi-sec-app-b" }

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages,
    aws_efs_mount_target.b
  ]
}

resource "aws_security_group" "tools" {
  name        = "depi-sec-tools-sg"
  description = "Monitoring instance in tools VPC"
  vpc_id      = aws_vpc.tools.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "depi-sec-tools-sg" }
}

resource "aws_instance" "tools" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.tools_a.id
  vpc_security_group_ids      = [aws_security_group.tools.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = false

  user_data = <<-EOF_TOOLS
    #!/bin/bash
    set -euxo pipefail
    echo "Tools monitoring instance ready" > /var/log/depi-tools-ready.log
  EOF_TOOLS

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = { Name = "depi-sec-monitoring" }

  depends_on = [
    aws_vpc_peering_connection.app_tools,
    aws_vpc_endpoint.tools_s3,
    aws_vpc_endpoint.tools_ssm,
    aws_vpc_endpoint.tools_ssmmessages,
    aws_vpc_endpoint.tools_ec2messages
  ]
}
