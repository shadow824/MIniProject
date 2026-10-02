resource "random_password" "db" {
  length           = 24
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#$%^&*()-_=+"
}

resource "aws_db_subnet_group" "app" {
  name       = "depi-sec-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "depi-sec-db-subnet-group" }
}

resource "aws_secretsmanager_secret" "db" {
  name = "depi-sec/rds/mysql"
  tags = { Name = "depi-sec-rds-secret" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "appadmin"
    password = random_password.db.result
  })
}

resource "aws_db_instance" "mysql" {
  identifier             = "depi-sec-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type            = "gp3"
  db_name                = "appdb"
  username               = "appadmin"
  password               = random_password.db.result
  port                   = 3306
  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  storage_encrypted      = true
  multi_az               = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = { Name = "depi-sec-rds-mysql" }
}
