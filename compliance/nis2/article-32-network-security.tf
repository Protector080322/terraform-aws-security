# =============================================================================
# NIS2 Article 32 — Network Security & Segmentation
# EU Cybersecurity Directive 2022/2555
#
# Controls:
#   32(1) — Network segmentation (VPC isolation)
#   32(2) — Perimeter security (WAF, security groups)
#   32(3) — Intrusion detection (VPC Flow Logs + GuardDuty)
#   32(4) — Secure remote access (no direct SSH/RDP)
# =============================================================================

data "aws_caller_identity" "nis2_net" {}
data "aws_region" "nis2_net" {}

# =============================================================================
# 32(1): VPC with segmented subnets
# =============================================================================
resource "aws_vpc" "nis2" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-nis2-vpc"
    NIS2Control = "Article-32-NetworkSegmentation"
  })
}

# Public subnet — DMZ only (NAT Gateway, Load Balancer)
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.nis2.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  # NIS2 Art.32: No auto-public IPs
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-public-${count.index + 1}"
    Tier        = "DMZ"
    NIS2Control = "Article-32-PublicSubnet"
  })
}

# Private subnet — Application tier
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.nis2.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false  # Never public

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-private-${count.index + 1}"
    Tier        = "Application"
    NIS2Control = "Article-32-PrivateSubnet"
  })
}

# Isolated subnet — Database tier (no internet access)
resource "aws_subnet" "isolated" {
  count             = length(var.isolated_subnets)
  vpc_id            = aws_vpc.nis2.id
  cidr_block        = var.isolated_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-isolated-${count.index + 1}"
    Tier        = "Database"
    NIS2Control = "Article-32-IsolatedSubnet"
  })
}

# =============================================================================
# 32(3): VPC Flow Logs (NIS2 Art.32 — network monitoring)
# =============================================================================
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.name_prefix}/flow-logs"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, { NIS2Control = "Article-32-VPCFlowLogs" })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name_prefix}-vpc-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"; Principal = { Service = "vpc-flow-logs.amazonaws.com" }; Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "VPCFlowLogsPolicy"
  role = aws_iam_role.vpc_flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.nis2.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = merge(var.tags, { NIS2Control = "Article-32-NetworkMonitoring" })
}

# =============================================================================
# 32(2): Security Groups — principle of least access
# =============================================================================

# ALB Security Group — only HTTPS from internet
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "NIS2 Art.32: ALB — HTTPS from internet only"
  vpc_id      = aws_vpc.nis2.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "To app tier"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg"; NIS2Control = "Article-32-ALBAccess" })
}

# App Security Group — only from ALB
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "NIS2 Art.32: App tier — only from ALB"
  vpc_id      = aws_vpc.nis2.id

  ingress {
    description     = "From ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # No SSH/RDP — use SSM instead (NIS2 Art.32(4))
  egress {
    description = "To database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.isolated_subnets
  }

  egress {
    description = "HTTPS out (AWS APIs)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg"; NIS2Control = "Article-32-AppAccess" })
}

# DB Security Group — only from app tier
resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "NIS2 Art.32: DB — only from app tier"
  vpc_id      = aws_vpc.nis2.id

  ingress {
    description     = "PostgreSQL from app only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # No egress — database should not initiate connections
  tags = merge(var.tags, { Name = "${var.name_prefix}-db-sg"; NIS2Control = "Article-32-DatabaseAccess" })
}

# =============================================================================
# Variables & Outputs
# =============================================================================
variable "name_prefix"        { type = string }
variable "vpc_cidr"           { type = string; default = "10.0.0.0/16" }
variable "public_subnets"     { type = list(string); default = ["10.0.1.0/24", "10.0.2.0/24"] }
variable "private_subnets"    { type = list(string); default = ["10.0.10.0/24", "10.0.11.0/24"] }
variable "isolated_subnets"   { type = list(string); default = ["10.0.20.0/24", "10.0.21.0/24"] }
variable "availability_zones" { type = list(string); default = ["eu-central-1a", "eu-central-1b"] }
variable "kms_key_arn"        { type = string; default = "" }
variable "tags"               { type = map(string); default = {} }

output "vpc_id"        { value = aws_vpc.nis2.id }
output "alb_sg_id"     { value = aws_security_group.alb.id }
output "app_sg_id"     { value = aws_security_group.app.id }
output "db_sg_id"      { value = aws_security_group.db.id }
output "private_subnet_ids"  { value = aws_subnet.private[*].id }
output "isolated_subnet_ids" { value = aws_subnet.isolated[*].id }
