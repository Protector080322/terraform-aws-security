output "organization_id" {
  value = module.organizations.organization_id
}

output "root_id" {
  value = module.organizations.root_id
}

output "ou_ids" {
  value = module.organizations.ou_ids
}

output "permissions_boundary_arn" {
  value       = try(module.permissions_boundary[0].permissions_boundary_arn, null)
}

output "mfa_policy_arn" {
  value       = try(module.permissions_boundary[0].mfa_policy_arn, null)
}
