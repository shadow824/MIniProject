# Security Controls

| Control | Service | Threat stopped | Evidence |
|---|---|---|---|
| Public/private routing | VPC | Direct internet access to private tiers | `04-public-private-route-tables.png` |
| ALB ingress TCP/80 only | Security Group | Unnecessary public exposure | `05-sg-rules.png` |
| ALB -> App SG reference | Security Group | Direct EC2 web access | `05-sg-rules.png` |
| App -> DB SG reference | Security Group | Untrusted DB access | `05-sg-rules.png` |
| App -> EFS SG reference | Security Group | Untrusted NFS access | `05-sg-rules.png` |
| No inbound TCP/22 | SG/NACL | SSH exposure | `06-nacl-rules.png` |
| S3 Block Public Access | S3 | Public bucket/object access | `10-s3-public-block.png` |
| SecureTransport deny | S3 policy | HTTP access | `10-s3-policy.png` |
| Encrypted EBS | EBS | Disk disclosure | `09-encrypted-volumes.png` |
| Encrypted EFS | EFS | Shared-file disclosure | `09-efs.png` |
| Private RDS | RDS | Internet database exposure | `11-rds-private.png` |
| Session Manager | Systems Manager | SSH keys and inbound management ports | `08-session-manager.png` |
| CloudTrail | CloudTrail/S3/CloudWatch | Missing API audit trail | `14-cloudtrail-event.png` |
| Flow Logs | VPC/CloudWatch | Missing network evidence | `15-flowlog-reject.png` |
| Lambda remediation | EventBridge/Lambda | Open SSH/RDP rule persistence | `17-lambda-rule-removed.png` |
| VPC Peering | VPC | Unapproved public path between VPCs | `18-peering-curl.png` |
| Backup Vault Lock | AWS Backup | Early recovery-point deletion | `19-vault-lock.png` |
| Budget action | AWS Budgets/IAM | Cost abuse | `02-budget-action.png` |
