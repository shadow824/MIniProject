# Testing

| # | Test | Expected result | Actual result | Screenshot |
|---|---|---|---|---|
| 1 | Open ALB DNS directly | `403 Forbidden` | Fill after apply | `01-alb-403.png` |
| 2 | Open CloudFront URL | HTTPS page loads | Fill after apply | `13-cloudfront-ok.png` |
| 3 | SSH to private instance | Timeout / REJECT | Fill after apply | `15-flowlog-reject.png` |
| 4 | RDS from laptop | Timeout | Fill after apply | `11-rds-private.png` |
| 5 | RDS from app server | Connection succeeds | Fill after apply | `11-rds-connectivity.png` |
| 6 | Make S3 object public | Refused | Fill after apply | `10-s3-public-block.png` |
| 7 | Add public SSH rule | Lambda removes it | Fill after apply | `17-lambda-rule-removed.png` |
| 8 | Stop nginx on one server | One unhealthy, site still works | Fill after apply | `12-alb-unhealthy.png` |
| 9 | Tools VPC curl -> app | Page returned | Fill after apply | `18-peering-curl.png` |
| 10 | Delete locked recovery point | Access denied | Fill after apply | `19-vault-lock.png` |

## Clean-up

Before destroy, take final screenshots, empty both S3 buckets including old versions if needed, then run `terraform destroy`. Governance Vault Lock may intentionally retain recovery points; document the remaining retention instead of bypassing the control.
