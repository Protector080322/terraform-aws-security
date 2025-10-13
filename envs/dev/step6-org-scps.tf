module "organizations" {
  source                           = "../../modules/organizations"
  ou_names                         = ["security", "workloads", "sandbox", "infra"]
  allowed_regions                  = ["us-east-1"]
  attach_to_ous                    = false
  enable_protect_security_services = true
  enable_require_mfa_iam           = false
  enable_deny_root_user            = false
}

variable "policies_to_attach" {
  type    = set(string)
  default = ["ProtectSecurityServices", "RestrictRegions", "DenyLeaveOrg"]
}

variable "already_attached_policy_names" {
  type    = set(string)
  default = []
}

locals {
  created_policy_names = toset(keys(module.organizations.policy_ids))
  desired_names        = length(var.policies_to_attach) > 0 ? var.policies_to_attach : local.created_policy_names
  attach_names         = length(var.already_attached_policy_names) > 0 ? toset(setsubtract(local.desired_names, var.already_attached_policy_names)) : local.desired_names
}

resource "aws_organizations_policy_attachment" "root" {
  for_each  = local.attach_names
  policy_id = module.organizations.policy_ids[each.key]
  target_id = module.organizations.root_id
}
