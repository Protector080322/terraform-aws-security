[![terraform-security-checks](https://github.com/Protector080322/terraform-aws-security-multi-account/actions/workflows/plan.yml/badge.svg)](https://github.com/Protector080322/terraform-aws-security-multi-account/actions/workflows/plan.yml)

# Terraform AWS Security Multi-Account Baseline

> **Enterprise-grade AWS infrastructure-as-code** for multi-account security governance with **NIS2, DORA, and ISO 27001** compliance automation.
>
> *Fork of Global Compliance Code framework, customized for German Mittelstand and critical infrastructure.*

---

## ⚡ Quick Start (5 minutes)

### Prerequisites

```bash
# macOS
brew install terraform aws-cli jq

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y terraform awscli jq

# Windows (via Chocolatey)
choco install terraform awscli jq

# Verify installation
terraform -v    # >= 1.5.0
aws --version   # >= 2.13.0
```

### Deploy Baseline

```bash
# Clone repository
git clone https://github.com/Protector080322/terraform-aws-security-multi-account
cd terraform-aws-security-multi-account

# Choose your environment
cp examples/mittelstand-sme/terraform.tfvars .

# Initialize & Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Verify compliance
./scripts/validate-compliance.sh
```

**Done!** ✅ Your multi-account AWS baseline is ready.

→ **See [GETTING_STARTED.md](./GETTING_STARTED.md) for detailed step-by-step guide**

---

## 🎯 What This Does

This repository automates **identity, access control, and compliance governance** across AWS multi-account environments:

- ✅ **Multi-account organization setup** (management, production, development, audit accounts)
- ✅ **Centralized security & logging** (CloudTrail, GuardDuty, Security Hub, AWS Config)
- ✅ **IAM hardening** (permission boundaries, MFA enforcement, least-privilege policies)
- ✅ **Network segmentation** (VPC, NACLs, security groups, WAF)
- ✅ **Encryption at rest & in transit** (AWS KMS, TLS 1.2+)
- ✅ **Compliance automation** (OPA/Rego policies, Terraform validation)
- ✅ **Audit & evidence generation** (CloudWatch, Config rules, custom scripts)

---

## 📊 Supported Compliance Frameworks

| Framework | Coverage | Status |
|-----------|----------|--------|
| **NIS2** (EU Cybersecurity Directive) | Articles 21–32 | ✅ Full coverage |
| **DORA** (Digital Operational Resilience) | Articles 6–21 | ✅ Implemented |
| **ISO 27001** | Controls A.5–A.18 | ✅ 80+ controls mapped |
| **GDPR** | Data protection essentials | ✅ Included |
| **BSI IT-Grundschutz** | German baseline standard | ✅ Aligned |

---

## 🏗️ Architecture Overview

```
AWS Organization
├── Management Account
│   ├── Organization Policies (SCPs)
│   ├── Security Hub (centralized findings)
│   └── GuardDuty (threat detection)
│
├── Production Account
│   ├── VPC (hardened networking)
│   ├── EKS/k3s (Kubernetes cluster)
│   └── RDS/DynamoDB (encrypted databases)
│
├── Development Account
│   ├── Sandbox VPC (non-production testing)
│   └── Lambda (compliance checks)
│
└── Audit Account
    ├── S3 (immutable audit logs)
    ├── CloudTrail (API logging)
    └── AWS Config (compliance database)
```

→ **See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed diagrams**

---

## 📁 Repository Structure

```
terraform-aws-security-multi-account/
├── README.md (you are here)
├── GETTING_STARTED.md (5-minute setup guide)
├── ARCHITECTURE.md (diagrams + topology)
│
├── envs/
│   ├── dev/                 # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   │
│   └── prod/                # Production environment
│       ├── main.tf
│       └── terraform.tfvars
│
├── modules/
│   ├── logging/             # CloudTrail, S3, KMS
│   ├── iam/                 # Permission boundaries, roles
│   ├── config/              # AWS Config compliance
│   └── org/                 # Organization SCPs
│
├── compliance/              # NEW: Compliance examples
│   ├── nis2/               # NIS2 Article mappings
│   ├── dora/               # DORA implementation
│   └── iso27001/           # ISO 27001 controls
│
├── kubernetes/             # NEW: K8s hardening
│   ├── k3s-hardened/       # k3s deployment
│   └── eks-security/       # EKS hardening
│
├── examples/               # NEW: Real-world scenarios
│   ├── mittelstand-sme/    # German SME (~500 employees)
│   ├── automotive/         # VDA/ASIL compliance
│   └── healthcare/         # GDPR + NIS2
│
├── policies-as-code/       # OPA/Rego compliance policies
│   ├── opa/               # Production policies
│   └── opa-wip/           # Work-in-progress
│
├── docs/                   # NEW: Extended documentation
│   ├── compliance-mapping.md
│   ├── disaster-recovery.md
│   └── troubleshooting.md
│
└── scripts/                # NEW: Automation scripts
    ├── validate-compliance.sh
    ├── audit-noncompliance.sh
    └── generate-report.sh
```

---

## 🚀 Key Features

### 1. **NIS2 Compliance Automation** (EU Cybersecurity Directive)

Article mappings for **essential operators** and **important entities**:

- **Article 21** (Access Control) → IAM permission boundaries + MFA enforcement
- **Article 23** (Incident Detection & Response) → GuardDuty + Lambda automations
- **Article 25** (Audit Logging) → CloudTrail immutable logging + encryption
- **Article 28** (Supply Chain Risk) → Third-party access restrictions
- **Article 32** (Network Segmentation) → VPC isolation + security groups

```bash
# View NIS2 implementation examples
ls compliance/nis2/
cat compliance/nis2/article-21-access-control.tf
```

### 2. **DORA Compliance** (Digital Operational Resilience)

Incident reporting & operational resilience:

- Article 16: Incident reporting (72-hour SLA)
- Article 17: Incident classification
- Article 18: Major incident response
- DMA (Digital Markets Act) resilience patterns

### 3. **Multi-Account Security**

Organize AWS accounts by function with central logging:

```bash
# Create AWS Organization (one-time)
aws organizations create-organization

# Deploy multi-account baseline
cd envs/prod
terraform apply
```

### 4. **Policy-as-Code** (OPA/Rego)

Automated compliance validation using Open Policy Agent:

```bash
# Test OPA policies
cd policies-as-code/opa
opa test -v .

# Validate Terraform plan
opa eval -d rules/ data.terraform
```

### 5. **Real-World Examples**

Ready-to-deploy infrastructure for common scenarios:

```bash
# Mittelstand SME (German manufacturing)
cp examples/mittelstand-sme/terraform.tfvars .
terraform apply

# Automotive (VDA/ASIL compliance)
cp examples/automotive/terraform.tfvars .
terraform apply

# Healthcare (GDPR + NIS2)
cp examples/healthcare/terraform.tfvars .
terraform apply
```

---

## 📋 Compliance Mapping Sample

| Control ID | Article | Description | Implementation |
|---|---|---|---|
| **GCC-IAM-001** | NIS2 Art. 21 | Multi-factor authentication | `modules/iam/permission-boundary/` |
| **GCC-LOG-002** | NIS2 Art. 25 | Centralized audit logging | `modules/logging/main.tf` |
| **GCC-INC-003** | NIS2 Art. 23 | Incident detection | GuardDuty + CloudWatch alarms |
| **GCC-NET-004** | NIS2 Art. 32 | Network segmentation | `examples/*/main.tf` (VPC setup) |
| **GCC-ISO-005** | ISO 27001 A.12.4.1 | Secure logging | S3 + KMS encryption |
| **GCC-DORA-006** | DORA Art. 16 | Incident reporting | Lambda automation |

→ **Full mapping: [docs/compliance-mapping.md](./docs/compliance-mapping.md)**

---

## 🔧 Customization

### Change AWS Region

```bash
# Edit terraform.tfvars
aws_region = "eu-west-1"  # Ireland (instead of eu-central-1/Frankfurt)
```

### Enable Kubernetes

```bash
# In examples/{scenario}/terraform.tfvars
kubernetes = {
  enable_eks        = true
  node_count        = 3
  instance_type     = "t3.large"
  security = {
    enable_pod_security_policy = true
    enable_network_policies     = true
  }
}
```

### Adjust Backup/DR Parameters

```bash
# Disaster recovery SLAs
disaster_recovery = {
  rto_hours = 4    # Recovery Time Objective
  rpo_hours = 1    # Recovery Point Objective
  backup_retention_days = 30
}
```

---

## 📚 Documentation

- **[GETTING_STARTED.md](./GETTING_STARTED.md)** — 5-minute quick start
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** — Topology diagrams & design
- **[compliance/nis2/README.md](./compliance/nis2/README.md)** — NIS2 article mappings
- **[compliance/dora/README.md](./compliance/dora/README.md)** — DORA implementation
- **[kubernetes/k3s-hardened/README.md](./kubernetes/k3s-hardened/README.md)** — Kubernetes hardening
- **[examples/mittelstand-sme/README.md](./examples/mittelstand-sme/README.md)** — SME scenario walkthrough

---

## 🧪 CI/CD Pipeline

All commits trigger automated compliance checks:

```yaml
terraform validate  → terraform fmt
    ↓
   tfsec           → Checkov
    ↓
OPA Policy Tests    → Custom validation
    ↓
Deploy to Dev       (if all pass)
```

**View pipeline:** [.github/workflows/plan.yml](.github/workflows/plan.yml)

---

## ✅ Pre-Deployment Checklist

Before `terraform apply`:

- [ ] AWS Organization created (`aws organizations create-organization`)
- [ ] Correct AWS region selected in `terraform.tfvars`
- [ ] Terraform initialized (`terraform init`)
- [ ] Plan reviewed (`terraform plan -out=tfplan`)
- [ ] Compliance checks passed (`opa test`)
- [ ] Backup plan documented (see [docs/disaster-recovery.md](./docs/disaster-recovery.md))

---

## 🤝 Support & Contributing

**Found an issue?**
→ Open [GitHub Issue](https://github.com/Protector080322/terraform-aws-security-multi-account/issues)

**Want to contribute?**
→ See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines

**Need professional help?**
→ Contact: solutions@cybercheck-infra.de

---

## 📜 License

This repository contains a fork of **Global Compliance Code™** framework:

- **Public open-core baseline:** MIT License
- **Extended mappings & controls:** Proprietary (Global Compliance Code OÜ)
- **Protector080322 customizations:** MIT License

See [LICENSE](./LICENSE) for details.

---

## 👤 Author & Maintenance

**Original:** [GlobalComplianceCode](https://www.globalcompliancecode.com/) (Amina Jiyu An)

**Fork & Customization:** [Protector080322](https://github.com/Protector080322)
- Focus: NIS2 + German Mittelstand + Critical Infrastructure
- Location: Berlin, Germany
- Expertise: Infrastructure, Security, Compliance Automation

**Last Updated:** June 2026

---

## 🎯 Roadmap (H2 2026)

- [ ] Terraform Registry publishing
- [ ] Helm chart for Kubernetes deployments
- [ ] AWS CloudFormation support (alongside Terraform)
- [ ] Multi-cloud support (Azure, GCP)
- [ ] Automated evidence collection & reporting
- [ ] Integration with SOAR platforms (incident response)
- [ ] Budget tracking & cost optimization

---

## ⚡ Quick Links

| What | Link |
|------|------|
| **Get Started** | [GETTING_STARTED.md](./GETTING_STARTED.md) |
| **Architecture** | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| **NIS2 Guide** | [compliance/nis2/README.md](./compliance/nis2/README.md) |
| **Examples** | [examples/](./examples/) |
| **Issues** | [GitHub Issues](https://github.com/Protector080322/terraform-aws-security-multi-account/issues) |
| **Discussions** | [GitHub Discussions](https://github.com/Protector080322/terraform-aws-security-multi-account/discussions) |

---

**Ready to get started? → [GETTING_STARTED.md](./GETTING_STARTED.md)** 🚀
