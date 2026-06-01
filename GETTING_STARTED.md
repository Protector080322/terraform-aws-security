# Getting Started (5 Minutes)

This guide walks you through deploying your first multi-account AWS security baseline in **5 minutes**.

---

## ✅ Prerequisites (1 minute)

### Install Required Tools

**macOS (via Homebrew):**
```bash
brew install terraform aws-cli jq git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y terraform awscli jq git
```

**Windows (via Chocolatey):**
```powershell
choco install terraform awscli jq git
```

### Verify Installation

```bash
terraform -v      # Should show: Terraform v1.5.0 or higher
aws --version      # Should show: aws-cli/2.13.0 or higher
jq --version       # Should show: jq-1.6 or higher
```

---

## 🔐 AWS Setup (2 minutes)

### Step 1: Create AWS Organization

This is a **one-time setup**. If you already have an AWS Organization, skip to Step 2.

```bash
# Create AWS Organization
aws organizations create-organization --feature-set ALL

# You should see:
# {
#   "Organization": {
#     "Arn": "arn:aws:organizations::123456789012:organization/o-xxxxxxxxxx",
#     "Id": "o-xxxxxxxxxx",
#     "MasterAccountId": "123456789012",
#     "MasterAccountEmail": "your-email@example.com"
#   }
# }
```

### Step 2: Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Enter your:
# - AWS Access Key ID: AKIA...
# - AWS Secret Access Key: (hidden)
# - Default region: eu-central-1  (Frankfurt for EU data residency)
# - Default output format: json
```

### Step 3: Verify AWS Access

```bash
# Check your account identity
aws sts get-caller-identity

# Should show your account number:
# {
#   "UserId": "AIDA...",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/your-user"
# }
```

---

## 🚀 Deploy Baseline (2 minutes)

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/Protector080322/terraform-aws-security-multi-account
cd terraform-aws-security-multi-account

# Check current directory
pwd
# /your/path/terraform-aws-security-multi-account
```

### Step 2: Choose Your Scenario

Choose ONE of the pre-built examples:

**For German Mittelstand (SME):**
```bash
cp examples/mittelstand-sme/terraform.tfvars .
cat terraform.tfvars | head -20  # Preview configuration
```

**For Healthcare (GDPR + NIS2):**
```bash
cp examples/healthcare/terraform.tfvars .
```

**For Automotive (VDA/ASIL):**
```bash
cp examples/automotive/terraform.tfvars .
```

### Step 3: Customize (Optional)

Edit `terraform.tfvars` if needed:

```bash
# Open in your editor
nano terraform.tfvars

# Key settings to customize:
# - aws_region: "eu-central-1"      (Frankfurt for EU data residency)
# - aws_organization_name: "acme"    (Your organization name)
# - budget_usd_monthly: 5000         (Set your budget)
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform (downloads modules, configures backend)
terraform init

# You should see:
# Terraform has been successfully configured!
```

### Step 5: Plan & Review

```bash
# Show what will be created (without making changes)
terraform plan -out=tfplan

# Review the output. Key resources created:
# - aws_s3_bucket (audit logs)
# - aws_kms_key (encryption)
# - aws_iam_role (IAM governance)
# - aws_cloudtrail (compliance logging)
# - aws_securityhub (centralized findings)
# - aws_guardduty_detector (threat detection)
```

### Step 6: Apply (Deploy)

```bash
# Create all resources in AWS
terraform apply tfplan

# Terraform will show:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

**⏱️ Expected deployment time: 3–5 minutes**

---

## ✨ Verify Deployment (1 minute)

### Check Terraform Outputs

```bash
# Show all created resources
terraform output -json | jq .

# Key outputs to verify:
terraform output kms_key_id
terraform output audit_bucket_name
terraform output cloudtrail_name
```

### Check AWS Console

1. **AWS Organizations:** https://console.aws.amazon.com/organizations/
   - Verify your organization is created
   - Check accounts (management, production, development, audit)

2. **CloudTrail:** https://console.aws.amazon.com/cloudtrail/
   - Verify trail is logging
   - Check S3 bucket for logs

3. **Security Hub:** https://console.aws.amazon.com/securityhub/
   - View compliance standards
   - Check findings (should be empty initially)

4. **GuardDuty:** https://console.aws.amazon.com/guardduty/
   - Verify threat detection is enabled
   - Check findings (should be empty for new accounts)

### Run Compliance Validation

```bash
# Run OPA compliance tests
cd policies-as-code/opa
opa test -v .

# You should see:
# PASS: all tests passed
```

---

## 🎯 Next Steps

### 1. Review Architecture

Understand what you just deployed:
```bash
cat ARCHITECTURE.md
```

Diagrams include:
- Multi-account organization topology
- NIS2 Article 21 (Access Control) flow
- Network segmentation
- Incident response workflow

### 2. Explore Compliance Examples

View NIS2, DORA, and ISO 27001 implementations:
```bash
ls -la compliance/
cat compliance/nis2/README.md
cat compliance/nis2/article-21-access-control.tf
```

### 3. Deploy Kubernetes (Optional)

If you want containerized workloads:
```bash
cd kubernetes/k3s-hardened
terraform apply
```

### 4. Set Up Disaster Recovery

Review and implement backup/DR:
```bash
cat docs/disaster-recovery.md
```

### 5. Add Your Own Resources

Extend the baseline with your applications:
```bash
# Create your own Terraform module
mkdir -p envs/dev/your-app
cat > envs/dev/your-app/main.tf << 'EOF'
# Your infrastructure code here
EOF
```

---

## 🔧 Customization Examples

### Change AWS Region

```bash
# Edit terraform.tfvars
aws_region = "eu-west-1"  # Ireland
# or
aws_region = "us-east-1"  # US (if not EU-only)
```

### Enable Kubernetes

```bash
# Add to terraform.tfvars
kubernetes = {
  enable_eks        = true
  node_count        = 3
  instance_type     = "t3.large"
}
```

### Adjust Backup/DR Settings

```bash
# Add to terraform.tfvars
disaster_recovery = {
  rto_hours = 4    # Recovery Time Objective
  rpo_hours = 1    # Recovery Point Objective
  backup_retention_days = 30
}
```

### Add Your Tags

```bash
# Add to terraform.tfvars
tags = {
  Environment = "production"
  Owner       = "Your-Team"
  CostCenter  = "00123"
  Compliance  = "NIS2,GDPR,ISO27001"
}
```

---

## 🐛 Troubleshooting

### Issue: "terraform init" fails with "bucket not found"

**Solution:** Remove existing Terraform state if upgrading:
```bash
rm -rf .terraform
rm -f .terraform.lock.hcl
terraform init
```

### Issue: "Access Denied" error

**Solution:** Verify AWS credentials:
```bash
aws sts get-caller-identity
aws iam get-user
```

### Issue: "Organization already exists"

**Solution:** AWS accounts can only have one organization:
```bash
# List existing organization
aws organizations describe-organization
```

### Issue: "Module not found"

**Solution:** Re-initialize Terraform:
```bash
terraform init -upgrade
terraform plan
```

### Issue: OPA tests fail

**Solution:** Check your Terraform code:
```bash
cd policies-as-code/opa
opa test -v .
# Review failing tests and fix accordingly
```

### Need Help?

Check the documentation:
```bash
cat ARCHITECTURE.md           # Architecture diagrams
cat compliance/nis2/README.md # NIS2 details
cat docs/disaster-recovery.md # Backup/DR setup
```

Or open an issue:
```
https://github.com/Protector080322/terraform-aws-security-multi-account/issues
```

---

## 📊 What You Just Created

| Component | Purpose | Cost |
|-----------|---------|------|
| **S3 Bucket** | Immutable audit logs | ~$1/month |
| **KMS Key** | Encryption management | ~$1/month |
| **CloudTrail** | API logging | ~$2/month |
| **Config Rules** | Compliance checking | ~$0.50/rule/month |
| **Security Hub** | Centralized findings | ~$0.30/month |
| **GuardDuty** | Threat detection | $0 (first 30 days free) |

**Total monthly cost: ~$5–10 for baseline** (if no compute resources)

---

## ✅ Checklist: You're Done!

- [ ] AWS Organization created
- [ ] Terraform initialized
- [ ] Baseline deployed
- [ ] Compliance tests passing
- [ ] CloudTrail logging
- [ ] Security Hub active
- [ ] GuardDuty detecting threats
- [ ] Audit bucket has S3 logs
- [ ] Architecture documented

---

## 🎯 Popular Next Steps

1. **Add Production Workloads**
   ```bash
   # Deploy applications to production account
   cd envs/prod
   ```

2. **Enable Kubernetes**
   ```bash
   # Deploy k3s or EKS cluster
   cd kubernetes/k3s-hardened
   ```

3. **Implement Disaster Recovery**
   ```bash
   # Set up backups and failover
   cat docs/disaster-recovery.md
   ```

4. **Customize for Your Industry**
   ```bash
   # Healthcare: cp examples/healthcare/terraform.tfvars .
   # Automotive: cp examples/automotive/terraform.tfvars .
   # Finance: cp examples/finance/terraform.tfvars .
   ```

5. **Integrate with SIEM**
   ```bash
   # Forward CloudTrail logs to your SIEM
   # See: docs/siem-integration.md
   ```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[README.md](./README.md)** | Overview & features |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Diagrams & topology |
| **[compliance/nis2/README.md](./compliance/nis2/README.md)** | NIS2 implementation |
| **[compliance/dora/README.md](./compliance/dora/README.md)** | DORA compliance |
| **[kubernetes/k3s-hardened/README.md](./kubernetes/k3s-hardened/README.md)** | Kubernetes setup |
| **[docs/disaster-recovery.md](./docs/disaster-recovery.md)** | Backup & DR |

---

**Ready? → [Deploy now](#-deploy-baseline-2-minutes) 🚀**

Need help? → [Troubleshooting](#-troubleshooting)
