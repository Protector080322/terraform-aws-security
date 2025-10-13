
output "permissions_boundary_arn" {
  value       = aws_iam_policy.boundary.arn
}

output "mfa_policy_arn" {
  value       = try(aws_iam_policy.mfa[0].arn, null)
}
