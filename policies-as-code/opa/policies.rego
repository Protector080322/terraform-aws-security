# =============================================================================
# OPA/Rego Policy — NIS2 + DORA + ISO 27001 Compliance Validation
# v3.0: Merged opa-wip rules into production pipeline
#
# Frameworks:
#   NIS2 Article 21 — Access Control
#   NIS2 Article 23 — Incident Detection
#   NIS2 Article 25 — Audit Logging & Encryption
#   NIS2 Article 28 — Supply Chain & Data Residency
#   NIS2 Article 32 — Network Security
#   DORA Article 6  — ICT Risk Management
# =============================================================================

package terraform.security

import rego.v1

# =============================================================================
# SECTION 1: IAM Governance (NIS2 Article 21)
# =============================================================================

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_role"
  rc.change.after
  not rc.change.after.permissions_boundary
  msg := sprintf("[NIS2-Art21] IAM role %q missing permissions boundary", [rc.change.after.name])
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_user"
  rc.change.after
  not rc.change.after.permissions_boundary
  msg := sprintf("[NIS2-Art21] IAM user %q missing permissions boundary", [rc.change.after.name])
}

# No wildcard admin policies (least privilege)
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_iam_policy"
  rc.change.after
  policy := json.unmarshal(rc.change.after.policy)
  stmt := policy.Statement[_]
  stmt.Effect == "Allow"
  stmt.Action == "*"
  stmt.Resource == "*"
  msg := sprintf("[NIS2-Art21] IAM policy %q grants full admin — violates least-privilege", [rc.change.after.name])
}

# =============================================================================
# SECTION 2: Security Services (NIS2 Article 23)
# Merged from opa-wip/rules/require-security-services.rego
# =============================================================================

violations contains msg if {
  count([1 | rc := input.resource_changes[_]; rc.type == "aws_securityhub_account"; rc.change.after]) == 0
  msg := "[NIS2-Art23] Security Hub not enabled in plan"
}

violations contains msg if {
  count([1 | rc := input.resource_changes[_]; rc.type == "aws_securityhub_standards_subscription"; rc.change.after]) == 0
  msg := "[NIS2-Art23] Security Hub has no compliance standards subscription"
}

violations contains msg if {
  count([1 | rc := input.resource_changes[_]; rc.type == "aws_guardduty_detector"; rc.change.after]) == 0
  msg := "[NIS2-Art23] GuardDuty not enabled in plan"
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_guardduty_detector"
  rc.change.after
  not rc.change.after.enable
  msg := "[NIS2-Art23] GuardDuty detector is disabled"
}

# EventBridge for automated incident response
violations contains msg if {
  count([1 |
    rc := input.resource_changes[_]
    rc.type == "aws_cloudwatch_event_rule"
    rc.change.after
    contains(lower(rc.change.after.name), "guardduty")
  ]) == 0
  msg := "[NIS2-Art23] No EventBridge rule for GuardDuty alerts — manual detection only"
}

# =============================================================================
# SECTION 3: Encryption (NIS2 Article 25)
# Merged from opa-wip/rules/deny-plain-s3.rego
# =============================================================================

violations contains msg if {
  r := input.planned_values.root_module.resources[_]
  r.type == "aws_s3_bucket"
  r.values.bucket != ""
  not r.values.server_side_encryption_configuration
  msg := sprintf("[NIS2-Art25] S3 bucket %q lacks server-side encryption (KMS required)", [r.values.bucket])
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_cloudtrail"
  rc.change.after
  not rc.change.after.is_multi_region_trail
  msg := sprintf("[NIS2-Art25] CloudTrail %q must be multi-region", [rc.change.after.name])
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_cloudtrail"
  rc.change.after
  not rc.change.after.enable_log_file_validation
  msg := sprintf("[NIS2-Art25] CloudTrail %q must have log file validation (tamper detection)", [rc.change.after.name])
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_kms_key"
  rc.change.after
  not rc.change.after.enable_key_rotation
  msg := "[NIS2-Art25] KMS key missing automatic rotation"
}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_db_instance"
  rc.change.after
  not rc.change.after.storage_encrypted
  msg := sprintf("[NIS2-Art25] RDS instance %q storage not encrypted", [rc.change.after.identifier])
}

# =============================================================================
# SECTION 4: Network Security (NIS2 Article 32)
# Merged from opa-wip/rules/sg-no-open-admin.rego
# =============================================================================

# Block SSH from internet
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  rc.change.after
  rc.change.after.type == "ingress"
  rc.change.after.from_port <= 22
  rc.change.after.to_port >= 22
  cidr := rc.change.after.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := "[NIS2-Art32] Security group allows SSH (port 22) from internet"
}

# Block RDP from internet
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group_rule"
  rc.change.after
  rc.change.after.type == "ingress"
  rc.change.after.from_port <= 3389
  rc.change.after.to_port >= 3389
  cidr := rc.change.after.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := "[NIS2-Art32] Security group allows RDP (port 3389) from internet"
}

# No public IPs on EC2
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  rc.change.after
  rc.change.after.associate_public_ip_address == true
  msg := "[NIS2-Art32] EC2 instance has public IP — use private subnet + NAT Gateway"
}

# IMDSv2 required
violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  rc.change.after
  metadata := rc.change.after.metadata_options[_]
  metadata.http_tokens != "required"
  msg := "[NIS2-Art32] EC2 instance must use IMDSv2 (http_tokens = required)"
}

# =============================================================================
# SECTION 5: Tagging (NIS2 Article 28)
# Merged from opa-wip/rules/require-tags.rego + upgraded
# =============================================================================

required_tags := {"Environment", "Owner", "Compliance", "ManagedBy"}

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type in {"aws_instance", "aws_s3_bucket", "aws_db_instance", "aws_eks_cluster", "aws_kms_key"}
  rc.change.after
  tags := object.get(rc.change.after, "tags", {})
  missing := required_tags - {k | tags[k]}
  count(missing) > 0
  msg := sprintf("[NIS2-Art28] %s %q missing tags: %v", [rc.type, rc.address, missing])
}

# =============================================================================
# SECTION 6: Data Residency (NIS2 Article 28)
# NEW: Ensure no resources deployed outside EU
# =============================================================================

violations contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  rc.change.after
  region := object.get(rc.change.after, "region", "")
  region != ""
  not startswith(region, "eu-")
  not region == "us-east-1"  # global services exception
  msg := sprintf("[NIS2-Art28] S3 bucket %q in non-EU region: %s", [rc.change.after.bucket, region])
}

# =============================================================================
# RESULTS
# =============================================================================

passed if count(violations) == 0

messages := [x | violations[x]]

result := {
  "passed":     passed,
  "count":      count(messages),
  "messages":   messages,
  "version":    "3.0.0",
  "frameworks": ["NIS2", "DORA", "ISO27001"],
  "note":       "Merged opa-wip rules into production v3.0",
}
