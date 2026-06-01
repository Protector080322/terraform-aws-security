# AWS Multi-Account Security Architecture

> Complete infrastructure topology for **NIS2, DORA, and ISO 27001 compliance** across AWS accounts.

---

## 📊 Multi-Account Organization Structure

This baseline organizes your AWS environment into **4 specialized accounts**:

```mermaid
graph TB
    ORG["🏢 AWS Organization"]
    
    subgraph MGMT["🔴 Management Account<br/>(Governance & Policy)"]
        OrgPolicy["📋 Organization Policies<br/>(SCPs)"]
        SecurityHub["🔍 Security Hub<br/>(Centralized Findings)"]
        GuardDuty["⚠️ GuardDuty<br/>(Threat Detection)"]
        Config["✅ AWS Config<br/>(Compliance Rules)"]
    end
    
    subgraph PROD["🟢 Production Account<br/>(Workloads)"]
        VPC_Prod["🌐 VPC (172.16.0.0/16)"]
        EKS["☸️ EKS Cluster<br/>(Hardened K8s)"]
        RDS["🗄️ RDS Database<br/>(Encrypted)"]
        S3_App["💾 S3 Buckets<br/>(Versioned)"]
    end
    
    subgraph DEV["🔵 Development Account<br/>(Testing)"]
        VPC_Dev["🌐 VPC Dev (10.0.0.0/16)"]
        Lambda["⚡ Lambda<br/>(Compliance Checks)"]
        ECR["📦 ECR<br/>(Container Registry)"]
    end
    
    subgraph AUDIT["🟡 Audit Account<br/>(Logging)"]
        S3_Logs["📁 S3 Audit Bucket<br/>(Immutable, Encrypted)"]
        CloudTrail["📝 CloudTrail<br/>(API Logging)"]
        Athena["🔎 Athena<br/>(Log Analysis)"]
    end
    
    ORG --> MGMT
    ORG --> PROD
    ORG --> DEV
    ORG --> AUDIT
    
    MGMT -->|Cross-account| PROD
    MGMT -->|Cross-account| DEV
    MGMT -->|Centralize logs| AUDIT
    PROD -->|CloudTrail| CloudTrail
    DEV -->|CloudTrail| CloudTrail
    MGMT -->|CloudTrail| CloudTrail
    
    style MGMT fill:#ffcccc
    style PROD fill:#ccffcc
    style DEV fill:#ccccff
    style AUDIT fill:#ffffcc
```

**Key Design:**
- **Isolation:** Each account is a separate blast radius
- **Centralization:** Audit account collects all logs
- **Governance:** Management account enforces policies
- **Efficiency:** Dev/Prod accounts run workloads independently

---

## 🔐 NIS2 Article 21: Access Control & Authentication

Multi-factor authentication and privilege management flow:

```mermaid
graph LR
    A["👤 User<br/>(on macOS/Windows)"]
    
    A -->|1. Login| B["🔐 AWS Console<br/>(MFA Prompt)"]
    
    B -->|2. TOTP Code| C{✅ MFA<br/>Verified?}
    
    C -->|Yes| D["📌 Assume Role<br/>(Permission Boundary)"]
    
    C -->|No| E["❌ Access Denied<br/>(NIS2 Art. 21.2)"]
    
    D -->|3. Temporary<br/>Credentials| F["🏭 Production<br/>Infrastructure"]
    
    F -->|4. CloudTrail<br/>Logs Action| G["📝 Audit Trail<br/>(Article 25)"]
    
    G -->|5. Alert on<br/>Suspicious Activity| H["⚠️ Security Team<br/>(Article 23)"]
    
    style B fill:#ffcccc
    style C fill:#ffcccc
    style D fill:#ffcccc
    style G fill:#ffffcc
    style H fill:#ffcccc
```

**NIS2 Article 21 Controls:**
- ✅ **21(1):** Multi-factor authentication enforced
- ✅ **21(2):** Role-based access control (RBAC)
- ✅ **21(3):** Privilege escalation restricted
- ✅ **21(4):** Session duration limited (max 1 hour)
- ✅ **21(5):** Access review logs (CloudTrail)

**Implementation Files:**
- `modules/iam/permission-boundary/` - Policy enforcement
- `compliance/nis2/article-21-access-control.tf` - Examples

---

## 🔒 Data Protection: Encryption at Rest & In Transit (Article 25)

Data flow showing encryption at every layer:

```mermaid
graph TB
    A["🌐 User<br/>External"]
    
    A -->|HTTPS only<br/>TLS 1.2+| B["🛡️ AWS WAF<br/>(DDoS Protection)"]
    
    B -->|Encrypted| C["⚖️ Application<br/>Load Balancer"]
    
    C -->|Signed<br/>HTTPS| D["🏭 EC2/EKS<br/>Instances"]
    
    D -->|Encrypted| E["🗄️ Database<br/>(RDS/DynamoDB)"]
    
    E -->|AWS KMS<br/>Encryption| F["🔑 KMS Master Key<br/>(Hardware Backed)"]
    
    D -->|CloudTrail| G["📁 S3 Bucket<br/>(Encrypted)"]
    
    G -->|S3 KMS| F
    
    G -->|Glacier<br/>after 30 days| H["❄️ Long-term<br/>Archive<br/>(Encrypted)"]
    
    H -->|S3 KMS| F
    
    style B fill:#ff9999
    style C fill:#ff9999
    style D fill:#ff9999
    style E fill:#ccffcc
    style F fill:#ffff99
    style G fill:#ccccff
    style H fill:#ccccff
```

**NIS2 Article 25 Controls:**
- ✅ **In Transit:** TLS 1.2+ for all network traffic
- ✅ **At Rest:** AWS KMS encryption for data storage
- ✅ **Key Management:** Hardware-backed master key
- ✅ **Rotation:** Automatic annual key rotation
- ✅ **Access Logging:** All KMS operations logged

**Implementation Files:**
- `modules/logging/main.tf` - KMS key setup
- `envs/prod/main.tf` - S3 bucket encryption
- `compliance/nis2/article-25-audit-logging.tf` - Examples

---

## 🚨 Incident Detection & Response (Article 23)

Automated threat detection and containment workflow:

```mermaid
graph TB
    A["🎯 Threat Event"]
    
    A -->|AWS API Call<br/>Suspicious Activity| B["🔍 GuardDuty<br/>(ML-based Detection)"]
    
    B -->|Finding| C["📊 Security Hub<br/>(Aggregation)"]
    
    C -->|Critical Alert| D["⏰ CloudWatch<br/>Event Rule"]
    
    D -->|Trigger| E["⚡ Lambda<br/>(Auto-response)"]
    
    E -->|Isolate| F{🛑 Containment}
    
    F -->|1. Revoke Keys| G["🔑 IAM Keys<br/>Revoked"]
    
    F -->|2. Block IP| H["🚫 Security Group<br/>Updated"]
    
    F -->|3. Snapshot| I["📸 Evidence<br/>Collected"]
    
    G --> J["👥 Security Team<br/>Notified<br/>(SNS Email)"]
    
    H --> J
    
    I --> J
    
    J -->|Investigation| K["🔎 Analyze Logs<br/>(CloudTrail)"]
    
    K -->|Eradicate| L["✅ Apply Patch<br/>or Update Policy"]
    
    L -->|Recover| M["▶️ Resume<br/>Operations"]
    
    M -->|Document| N["📋 Incident Report<br/>(72-hour deadline)<br/>NIS2 Art. 23"]
    
    style B fill:#ff6666
    style C fill:#ff6666
    style D fill:#ff9999
    style E fill:#ffcc99
    style F fill:#ff0000
    style N fill:#ffff00
```

**NIS2 Article 23 Controls:**
- ✅ **Detection:** GuardDuty + CloudWatch + Config
- ✅ **Analysis:** Automated Lambda functions
- ✅ **Containment:** Immediate access revocation
- ✅ **Recovery:** Infrastructure rollback capability
- ✅ **Reporting:** 72-hour incident notification

**Implementation Files:**
- `compliance/nis2/article-23-incident-response.tf` - Detection setup
- `policies-as-code/opa/` - Automated response policies

---

## 🌐 Network Segmentation (Article 32)

Defense-in-depth network architecture:

```mermaid
graph TB
    Internet["🌍 Internet<br/>(Untrusted)"]
    
    Internet -->|Inbound only<br/>Port 443| WAF["🛡️ AWS WAF<br/>(Malicious traffic blocked)"]
    
    WAF -->|HTTPS| ALB["⚖️ Application<br/>Load Balancer<br/>(Port 443)"]
    
    subgraph VPC["🔒 VPC (172.16.0.0/16)<br/>(Private Network)"]
        
        subgraph PUB["📍 Public Subnet<br/>(DMZ)"]
            NAT["🚪 NAT Gateway<br/>(Outbound only)"]
        end
        
        subgraph PRIV["🔐 Private Subnet<br/>(App Tier)"]
            SG_App["🛑 Security Group<br/>Allow: 8080 from ALB<br/>Allow: 443 to NAT"]
            APP["☸️ EKS Pods<br/>or EC2 Instances"]
        end
        
        subgraph ISO["🔒 Isolated Subnet<br/>(Database Tier)"]
            SG_DB["🛑 Security Group<br/>Allow: 5432 from App<br/>Deny: Internet Access"]
            DB["🗄️ RDS Database<br/>(No Public IP)"]
        end
    end
    
    ALB --> PUB
    PUB -->|All traffic| PRIV
    PRIV -->|Private| ISO
    PRIV -->|Outbound only| NAT
    
    style WAF fill:#ff9999
    style ALB fill:#ff9999
    style VPC fill:#ccffcc
    style PRIV fill:#ffffcc
    style ISO fill:#ffcccc
    style DB fill:#ccccff
```

**NIS2 Article 32 Controls:**
- ✅ **Perimeter:** AWS WAF blocks malicious traffic
- ✅ **DMZ:** Public subnet isolated with NAT Gateway
- ✅ **App Tier:** Private subnet with restricted ingress
- ✅ **Database:** Isolated subnet with no internet access
- ✅ **Monitoring:** VPC Flow Logs on all subnets

**Implementation Files:**
- `envs/prod/main.tf` - VPC setup
- `examples/mittelstand-sme/main.tf` - Network configuration

---

## 📋 Compliance Continuous Monitoring (Article 28)

Automated compliance checking across infrastructure:

```mermaid
graph TB
    A["🚀 Terraform Deploy"]
    
    A -->|Infrastructure Created| B["🏭 AWS Resources<br/>(EC2, RDS, S3, etc)"]
    
    B -->|Config Evaluates| C["✅ AWS Config Rules<br/>(100+ built-in rules)"]
    
    C -->|Policies Applied| D["⏛ OPA/Rego Policies<br/>(Custom compliance)"]
    
    D -->|Results| E{📊 Compliant?}
    
    E -->|Yes ✅| F["✅ Passed<br/>Infrastructure live"]
    
    E -->|No ❌| G["❌ Failed<br/>Block deployment"]
    
    C -->|Ongoing| H["📈 Continuous<br/>Monitoring"]
    
    H -->|Drift Detected| I["⚠️ Alert<br/>Manual remediation needed"]
    
    I -->|Fix| J["🔧 Terraform Apply<br/>(Correct configuration)"]
    
    J --> B
    
    style C fill:#ffff99
    style D fill:#ffff99
    style H fill:#ffff99
    style F fill:#ccffcc
    style G fill:#ffcccc
```

**NIS2 Article 28 Controls:**
- ✅ **As-Code:** Infrastructure defined in Git
- ✅ **Policy Testing:** OPA policies validate before deploy
- ✅ **Continuous Monitoring:** AWS Config watches for drift
- ✅ **Automated Remediation:** Lambda fixes violations
- ✅ **Evidence Trail:** Version-controlled compliance artifacts

**Implementation Files:**
- `policies-as-code/opa/` - Policy definitions
- `modules/config/` - AWS Config setup

---

## 🗂️ Multi-Account Cross-Account Access

How different accounts interact securely:

```mermaid
graph LR
    MGMT["🔴 Management Account<br/>(Policy Authority)"]
    
    MGMT -->|Assume Role<br/>with MFA| PROD["🟢 Production<br/>Account"]
    
    MGMT -->|Assume Role<br/>with MFA| DEV["🔵 Development<br/>Account"]
    
    MGMT -->|Cross-Account<br/>Assume| AUDIT["🟡 Audit Account<br/>(Write Logs Only)"]
    
    PROD -->|Write Logs<br/>to S3| AUDIT
    
    DEV -->|Write Logs<br/>to S3| AUDIT
    
    MGMT -->|Write Logs<br/>to S3| AUDIT
    
    AUDIT -->|CloudTrail Validates<br/>Signature| MGMT
    
    style MGMT fill:#ffcccc
    style PROD fill:#ccffcc
    style DEV fill:#ccccff
    style AUDIT fill:#ffffcc
```

**Cross-Account Best Practices:**
- ✅ **SCP Policies:** Organization policies enforced at root level
- ✅ **Role Assumption:** Always require MFA for cross-account access
- ✅ **Audit Account:** Separate account for immutable logs
- ✅ **Least Privilege:** Minimal permissions per role
- ✅ **CloudTrail Validation:** S3 Object Lock prevents tampering

---

## 🔄 Data Flow: End-to-End

Complete lifecycle of a user request through the secured infrastructure:

```mermaid
graph LR
    A["👤 User Request"]
    B["🛡️ AWS WAF"]
    C["⚖️ ALB"]
    D["📡 TLS Handshake"]
    E["☸️ EKS Pod"]
    F["🔐 Secret Store<br/>(AWS Secrets Manager)"]
    G["🗄️ Encrypted RDS"]
    H["📝 Logs → CloudTrail"]
    I["📁 S3 Bucket<br/>(Encrypted, Versioned)"]
    J["❄️ Glacier<br/>(30+ days)"]
    
    A -->|HTTPS| B
    B -->|Filter| C
    C -->|SSL/TLS| D
    D -->|Decrypt| E
    E -->|Request secrets| F
    E -->|Query| G
    G -->|Result| E
    E -->|Response| A
    E -->|Audit event| H
    H -->|KMS encrypted| I
    I -->|Transition| J
    
    style B fill:#ff9999
    style C fill:#ff9999
    style D fill:#ffcccc
    style E fill:#ccffcc
    style F fill:#ffff99
    style G fill:#ccccff
    style H fill:#ffffcc
    style I fill:#ffffcc
    style J fill:#ccccff
```

---

## 🎯 Compliance Framework Mapping

How each component maps to compliance requirements:

| Component | NIS2 Article | DORA Article | ISO 27001 | Purpose |
|-----------|--------------|--------------|-----------|---------|
| **Multi-Account** | 28, 32 | 13 | A.6.1 | Segregation of duties |
| **IAM + MFA** | 21 | 14 | A.9 | Access control |
| **CloudTrail** | 25 | 10 | A.12.4 | Audit logging |
| **AWS Config** | 28 | - | A.12.6 | Configuration management |
| **GuardDuty** | 23 | 6 | A.12.2 | Threat detection |
| **KMS Encryption** | 25 | 11 | A.10.1 | Cryptography |
| **VPC Isolation** | 32 | 12 | A.13.1 | Network controls |
| **Backup/DR** | 17 | 17 | A.12.3 | Business continuity |

---

## 📚 Architecture Decisions

### Why Multi-Account?

- **Blast Radius:** Compromise in Dev doesn't affect Prod
- **Access Control:** Different IAM policies per account
- **Billing:** Track costs by environment
- **Compliance:** Audit account separate from operations
- **Scaling:** Add accounts for new business units

### Why Terraform?

- **Infrastructure as Code:** Version control for infrastructure
- **Repeatability:** Deploy identical baselines
- **Automation:** GitOps pipelines
- **Compliance:** Code review before deployment
- **Documentation:** Comments explain design decisions

### Why OPA/Rego?

- **Policy as Code:** Compliance rules in code
- **Pre-deployment:** Catch violations before AWS
- **Automation:** No manual approval gates
- **Audit Trail:** Policy changes in Git
- **Extensibility:** Add custom rules easily

---

## 🔧 Customization Points

| Area | Files | Customization |
|------|-------|---------------|
| **Network** | `envs/prod/main.tf` | Change VPC CIDR, add subnets |
| **IAM** | `modules/iam/` | Add roles, adjust permissions |
| **Backup** | `examples/*/terraform.tfvars` | Change retention, RTO/RPO |
| **Logging** | `modules/logging/` | Change S3 prefix, retention |
| **Compliance** | `policies-as-code/opa/` | Add custom policies |
| **Kubernetes** | `kubernetes/k3s-hardened/` | Adjust node count, instance type |

---

## 📖 Related Documentation

- **[README.md](./README.md)** — Feature overview
- **[GETTING_STARTED.md](./GETTING_STARTED.md)** — 5-minute setup
- **[compliance/nis2/README.md](./compliance/nis2/README.md)** — NIS2 details
- **[docs/disaster-recovery.md](./docs/disaster-recovery.md)** — Backup strategy
- **[kubernetes/k3s-hardened/README.md](./kubernetes/k3s-hardened/README.md)** — K8s hardening

---

**Next:** [GETTING_STARTED.md](./GETTING_STARTED.md) — Deploy in 5 minutes 🚀
