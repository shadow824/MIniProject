# Mini Project 1 — Secure AWS Web Platform (Terraform)

## 1. Project overview

A small secure web platform built entirely with Terraform in `us-east-1`.
CloudFront is the HTTPS front door, the ALB is public, and the two EC2 web servers, RDS MySQL database, and EFS file system are private.
The design uses IAM roles and Session Manager instead of SSH keys, VPC endpoints instead of a NAT Gateway, CloudTrail and VPC Flow Logs for visibility, Lambda for auto-remediation, and AWS Backup with a governance-mode Vault Lock.
CloudFront is controlled by the `enable_cloudfront` Terraform variable so the rest of the lab can be deployed even when AWS has not yet verified the account for creating new CloudFront distributions.

## 2. Architecture diagram

```text
Internet
   |
   v
CloudFront (HTTPS)
   | X-Origin-Verify secret header
   v
ALB - public subnets
   |
   +--------------------+
   |                    |
   v                    v
EC2 App A            EC2 App B
private-a            private-b
   | \                / |
   |  \              /  |
   |   +------------+   |
   |        EFS           |
   +------> RDS <---------+

Tools VPC (10.1.0.0/16)
   |
   +-- Monitoring EC2 (10.1.1.0/24)
   |
   +-- VPC Peering --> App VPC

CloudTrail -> S3 + CloudWatch Logs
VPC Flow Logs -> CloudWatch Logs
CloudWatch -> SNS email
EventBridge -> Lambda -> remove public SSH/RDP rule
AWS Backup -> Vault Lock (governance)
```

## 3. Network design table

| Resource | CIDR / AZ | Type | Purpose |
|---|---|---|---|
| depi-sec-app-vpc | 10.0.0.0/16 | VPC | Main application network |
| depi-sec-public-a | 10.0.1.0/24 / us-east-1a | Public | ALB |
| depi-sec-public-b | 10.0.2.0/24 / us-east-1b | Public | ALB |
| depi-sec-private-a | 10.0.11.0/24 / us-east-1a | Private | EC2, RDS, EFS |
| depi-sec-private-b | 10.0.12.0/24 / us-east-1b | Private | EC2, RDS, EFS |
| depi-sec-tools-vpc | 10.1.0.0/16 | VPC | Security/monitoring network |
| depi-sec-tools-a | 10.1.1.0/24 / us-east-1a | Private | Monitoring EC2 |

## 4. Security controls table

| Control | AWS service | What it stops |
|---|---|---|
| Public/private subnet separation | VPC routing | Direct internet reachability to servers |
| ALB SG open on TCP/80 only | Security Groups | Unnecessary public ports |
| App SG accepts HTTP from ALB SG | Security Groups | Direct internet access to EC2 |
| DB SG accepts 3306 from app SG | Security Groups | Direct database access |
| EFS SG accepts 2049 from app SG | Security Groups | Untrusted NFS access |
| No port 22 inbound | SG + NACL | SSH exposure |
| S3 Block Public Access | S3 | Public bucket/object exposure |
| S3 SecureTransport deny | S3 bucket policy | Plain HTTP access |
| EBS/EFS/RDS encryption | EBS/EFS/RDS | Data at rest exposure |
| IAM role + Session Manager | IAM/SSM | Long-lived server credentials and SSH keys |
| VPC endpoints | VPC | Internet dependency for AWS services |
| CloudTrail validation | CloudTrail | Tampering with audit evidence |
| VPC Flow Logs | VPC/CloudWatch | Missing network evidence |
| Lambda remediation | EventBridge/Lambda | Public SSH/RDP rule remaining open |
| Budget action | AWS Budgets/IAM | Uncontrolled expensive resource creation |
| Backup Vault Lock | AWS Backup | Early backup deletion |
| CloudFront secret header | CloudFront/ALB | Direct ALB bypass |

## 5. Prerequisites

- Terraform >= 1.6
- AWS CLI configured with credentials that can create the required lab resources
- An AWS account in `us-east-1`
- Permission to create IAM, VPC, EC2, RDS, EFS, S3, CloudFront, CloudTrail, CloudWatch, Lambda, EventBridge, Backup, Budgets, and related resources
- Before `apply`, provide your alert email with `-var="alert_email=YOUR-EMAIL@example.com"` (or a tfvars file that is excluded by `.gitignore`)
- If AWS returns `403 AccessDenied: Your account must be verified before you can add new CloudFront resources`, leave `enable_cloudfront` at its default `false` until AWS verifies the account

## 6. How to deploy

From the `terraform/` directory:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

`enable_cloudfront` defaults to `false`. This avoids the AWS CloudFront account-verification 403 during the initial lab deployment. After the account is verified, run `terraform apply -var="enable_cloudfront=true"` to create CloudFront and its standard logging delivery resources.

After apply, confirm the SNS subscription email and approve it.

## 7. How to verify

1. When `enable_cloudfront=false`, ALB DNS directly -> page loads normally so the rest of the lab can be tested.
2. After AWS account verification and `enable_cloudfront=true`, ALB DNS directly -> `403 Forbidden`, while the CloudFront URL -> page loads over HTTPS.
3. SSH to a private EC2 IP -> timeout/rejected.
4. RDS from laptop -> timeout.
5. RDS from an app server -> TCP/3306 succeeds.
6. Attempt to make an S3 object public -> refused by Block Public Access.
7. Add `0.0.0.0/0` TCP/22 to `depi-sec-app-sg` -> Lambda removes it and publishes an SNS message.
8. Stop nginx on one server -> one target becomes unhealthy while the other continues serving.
9. From the tools instance, curl an app private IP -> page is returned.
10. Delete a recovery point in the locked vault -> access denied after the governance lock is active.

## 8. Screenshots

Store evidence under `screenshots/NN-task-name/` and keep the AWS Region visible. Never publish credentials, account IDs, or email addresses.

## 9. Cost notes

The project deliberately avoids a NAT Gateway, but ALB, CloudFront, RDS, EFS, S3 storage, CloudWatch Logs, and interface VPC endpoints can incur charges. Destroy the lab when you are not using it. This corrected build includes interface endpoints in both the app and tools VPCs so the private monitoring instance can also use Session Manager without a public IP or NAT Gateway.

## 10. How to destroy

Empty both versioned S3 buckets first if they contain objects. Then:

```bash
terraform destroy
```

Read the destroy plan before confirming. A backup vault with a governance lock can retain recovery points and prevent immediate deletion; follow the assignment rule and document any remaining retention instead of disabling the control just to force deletion.

## 11. What I learned

- A public subnet is defined by routing, not by its name.
- Security Groups are stateful.
- NACLs are stateless and need return traffic rules.
- SG-to-SG references are better than hard-coded subnet CIDRs for tier-to-tier access.
- Session Manager removes the need for SSH keys and inbound port 22.
- S3 Gateway Endpoints can provide private access without a NAT Gateway.
- RDS should remain private and encrypted.
- EFS is useful when two servers need shared files.
- CloudTrail records API activity while Flow Logs record network metadata.
- Detection is different from remediation; EventBridge plus Lambda can automatically remove a dangerous rule.
- A budget action is a preventive cost guardrail.
- Backup Vault Lock protects recovery points from early deletion.

## 12. Known limitations

- This is a learning lab, not a production reference architecture.
- CloudFront uses the default CloudFront certificate because no custom domain is configured.
- The ALB-to-CloudFront origin uses HTTP because that is what the assignment specifies; production should use HTTPS to the origin.
- Terraform local state still contains sensitive values such as the generated RDS password; the state file must never be committed.
- CloudFront is intentionally optional until the AWS account is verified for new CloudFront distributions.
- CloudFront Standard Logging v2 uses a same-account S3 delivery destination, so no `aws_cloudwatch_log_delivery_destination_policy` is created. That policy is for cross-account delivery.
