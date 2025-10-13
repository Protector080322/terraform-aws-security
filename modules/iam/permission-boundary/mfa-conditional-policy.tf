

locals {
  mfa_policy_name_effective = var.mfa_policy_name != "" ? var.mfa_policy_name : "${var.name}-mfa-conditional"
}


data "aws_iam_policy_document" "mfa" {
  count = var.create_mfa_policy ? 1 : 0
  statement {
    sid     = "AllowMfaExemptActions"
    effect  = "Allow"
    actions = var.mfa_exempt_actions
    resources = ["*"]
  }

  statement {
    sid     = "DenySensitiveIfNoMFA"
    effect  = "Deny"
    actions = var.mfa_protected_actions
    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa" {
  count  = var.create_mfa_policy ? 1 : 0
  name   = local.mfa_policy_name_effective
  path   = var.path
  policy = data.aws_iam_policy_document.mfa[0].json
}
