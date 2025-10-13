resource "aws_iam_user" "dev" {
  count                = var.enable_permissions_boundary ? 1 : 0
  name                 = "dev-user"
  permissions_boundary = module.permissions_boundary[0].permissions_boundary_arn
}

resource "aws_iam_user_policy_attachment" "dev_mfa" {
  count      = var.enable_permissions_boundary ? 1 : 0
  user       = aws_iam_user.dev[0].name
  policy_arn = module.permissions_boundary[0].mfa_policy_arn
}

resource "aws_iam_user_policy" "dev_min_allow" {
  count = var.enable_permissions_boundary ? 1 : 0
  name  = "dev-min-allow"
  user  = aws_iam_user.dev[0].name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid      = "ReadWhoAmI",
      Effect   = "Allow",
      Action   = ["sts:GetCallerIdentity", "iam:ListMFADevices"],
      Resource = "*"
    }]
  })
}
