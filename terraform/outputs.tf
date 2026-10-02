output "app_vpc_id" {
  value = aws_vpc.app.id
}

output "tools_vpc_id" {
  value = aws_vpc.tools.id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "cloudfront_domain_name" {
  value = try(aws_cloudfront_distribution.app[0].domain_name, null)
}

output "app_bucket_name" {
  value = aws_s3_bucket.app.bucket
}

output "logs_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "ec2_app_private_ips" {
  value = {
    app_a = aws_instance.app_a.private_ip
    app_b = aws_instance.app_b.private_ip
  }
}

output "tools_private_ip" {
  value = aws_instance.tools.private_ip
}

output "backup_vault_name" {
  value = aws_backup_vault.main.name
}
