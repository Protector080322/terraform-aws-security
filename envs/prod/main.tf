# =============================================================================
# envs/prod/main.tf — Production Environment
# NIS2/DORA: Stricter settings than dev
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }

  backend "s3" {
    bucket       = "cybercheck-terraform-state-prod"
    key          = "envs/prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Owner         = "Protector080322"
      Environment   = "production"
      Project       = var.project
      ManagedBy     = "terraform"
      Compliance    = "NIS2,DORA,ISO27001"
      DataResidency = "EU-DE"
      Repository    = "github.com/Protector080322/terraform-aws-security"
    }
  }
}

locals {
  name_prefix = "${var.project}-prod"
  tags = {
    Environment = "production"
    Owner       = "Protector080322"
    Project     = var.project
    ManagedBy   = "terraform"
    Compliance  = "NIS2,DORA,ISO27001"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# Step 2: Logging (NIS2 Art.25 — stricter than dev)
# =============================================================================
module "logging" {
  source = "../../modules/logging"

  name_prefix       = local.name_prefix
  env               = "prod"
  enable_cloudtrail = true
  tags              = local.tags
}

# =============================================================================
# Step 3: AWS Config
# =============================================================================
module "config" {
  source = "../../modules/config"

  name_prefix             = local.name_prefix
  enable_aws_config       = true
  conformance_pack_name   = "nis2-prod"
  enable_conformance_pack = true
  tags                    = local.tags
}

# =============================================================================
# Step 4: Security Services (NIS2 Art.23)
# =============================================================================
module "security_services" {
  source = "../../modules/security-services"

  name_prefix                      = local.name_prefix
  tags                             = local.tags
  enable_security_hub              = true
  enable_security_hub_cis          = true
  cis_version                      = "1.4.0"
  enable_security_hub_afsbp        = true
  afsbp_version                    = "1.0.0"
  enable_security_hub_nist         = true
  enable_guardduty                 = true
  gd_enable_s3_protection          = true
  gd_enable_eks_audit_logs         = true
  gd_enable_malware_protection_ebs = true
}

# =============================================================================
# Step 5: IAM Permission Boundaries (NIS2 Art.21)
# =============================================================================
module "permissions_boundary" {
  source = "../../modules/iam/permission-boundary"
  name   = "${local.name_prefix}-boundary"
  path   = "/"
}

# =============================================================================
# Step 6: Organization SCPs (NIS2 Art.21 + Art.32)
# Production: Stricter region controls
# =============================================================================
module "organizations" {
  source = "../../modules/organizations"

  ou_names = ["security", "workloads", "sandbox", "infra"]

  allowed_regions = [
    "eu-central-1",   # Frankfurt (primary)
    "eu-west-1",      # Ireland (DR only)
    "us-east-1",      # AWS global services only
  ]

  enable_deny_root_user            = true
  enable_require_mfa_iam           = true
  enable_protect_security_services = true
  attach_to_ous                    = false
}

# =============================================================================
# AWS Backup (NIS2 Art.17 — Business Continuity)
# Production: Stricter RTO/RPO
# =============================================================================
resource "aws_backup_vault" "prod" {
  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = module.logging.kms_key_arn

  tags = merge(local.tags, { NIS2Control = "Article-17-BusinessContinuity" })
}

resource "aws_backup_plan" "prod" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "hourly-critical"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 * * * ? *)"  # Hourly

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:eu-west-1:${data.aws_caller_identity.current.account_id}:backup-vault:cross-region-dr"
      lifecycle { delete_after = 365 }
    }
  }

  rule {
    rule_name         = "daily-full"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      cold_storage_after = 90
      delete_after       = 2555  # 7 years
    }
  }
}

resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"; Principal = { Service = "backup.amazonaws.com" }; Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# =============================================================================
# Outputs
# =============================================================================
output "environment"   { value = "production" }
output "region"        { value = data.aws_region.current.name }
output "account_id"    { value = data.aws_caller_identity.current.account_id }
output "backup_vault"  { value = aws_backup_vault.prod.arn }

output "compliance" {
  value = {
    nis2_articles = ["21", "23", "25", "28", "32"]
    dora_articles = ["16"]
    iso_27001     = "35+ controls mapped"
    environment   = "production"
    region        = "eu-central-1"
    data_residency = "EU-DE (Germany)"
  }
}
