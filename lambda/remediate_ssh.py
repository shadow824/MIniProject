import json
import os
import boto3


ec2 = boto3.client("ec2")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):
    detail = event.get("detail", {})
    request_parameters = detail.get("requestParameters") or {}
    group_id = request_parameters.get("groupId")

    if not group_id:
        return {"status": "ignored", "reason": "no security group id in event"}

    response = ec2.describe_security_groups(GroupIds=[group_id])
    group = response["SecurityGroups"][0]
    revoked = []

    for permission in group.get("IpPermissions", []):
        if permission.get("IpProtocol") not in ("tcp", "-1"):
            continue

        from_port = permission.get("FromPort")
        to_port = permission.get("ToPort")
        if from_port is None or to_port is None:
            continue

        if not ({22, 3389} & set(range(from_port, to_port + 1))):
            continue

        public_ipv4 = [
            r for r in permission.get("IpRanges", [])
            if r.get("CidrIp") == "0.0.0.0/0"
        ]
        public_ipv6 = [
            r for r in permission.get("Ipv6Ranges", [])
            if r.get("CidrIpv6") == "::/0"
        ]

        if not public_ipv4 and not public_ipv6:
            continue

        revoke_permission = {
            "IpProtocol": permission["IpProtocol"],
            "FromPort": from_port,
            "ToPort": to_port,
        }

        if public_ipv4:
            revoke_permission["IpRanges"] = [{"CidrIp": "0.0.0.0/0"}]
        if public_ipv6:
            revoke_permission["Ipv6Ranges"] = [{"CidrIpv6": "::/0"}]

        ec2.revoke_security_group_ingress(
            GroupId=group_id,
            IpPermissions=[revoke_permission],
        )
        revoked.append(revoke_permission)

    if revoked:
        message = json.dumps({"security_group": group_id, "revoked": revoked})
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="DEPI security remediation: public SSH/RDP rule removed",
            Message=message,
        )

    return {"status": "ok", "security_group": group_id, "revoked": revoked}
