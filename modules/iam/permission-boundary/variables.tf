variable "name" {
  type        = string
  description = "Name for the permissions boundary policy"
}

variable "allowed_kms_key_arns" {
  type        = list(string)
  default     = []
  description = "KMS keys allowed for S3 PutObject."
}

variable "path" {
  type    = string
  default = "/permissions-boundary/"
}

# mfa-conditional-policy

variable "create_mfa_policy" {
  type        = bool
  default     = true
  description = "If true, create an identity policy that denies sensitive actions when MFA is not present."
}

variable "mfa_policy_name" {
  type        = string
  default     = ""
}

variable "mfa_protected_actions" {
  type = list(string)
  default = [
    "iam:*",
    "organizations:*",
    "kms:*",
    "cloudtrail:*",
    "config:*",
    "s3:PutBucketPolicy",
    "s3:DeleteBucketPolicy",
    "s3:PutEncryptionConfiguration",
    "s3:DeleteObject",
    "ec2:AuthorizeSecurityGroupIngress",
    "ec2:RevokeSecurityGroupIngress",
    "sts:AssumeRole",
    "guardduty:*",
    "securityhub:*"
  ]
}
variable "mfa_exempt_actions" {
  type = list(string)
  default = [
    "iam:ListMFADevices",
    "iam:CreateVirtualMFADevice",
    "iam:EnableMFADevice",
    "iam:ListAccountAliases",
    "iam:ListUsers",
    "sts:GetCallerIdentity"
  ]
}
