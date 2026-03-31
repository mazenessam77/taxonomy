###############################################################################
# VPC — 2 AZs, Public + Private + Database Subnets, NAT Gateways
###############################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  # ── Public Subnets (ALB, NAT Gateways) ──
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # ── Private Subnets (EKS Nodes — Managed + Spot) ──
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"         = local.name
  }

  # ── Database Subnets (RDS — isolated, no public route) ──
  database_subnets                   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 20)]
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  database_subnet_group_name         = "${local.name}-db"

  # ── NAT Gateway (one per AZ for HA) ──
  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  # ── DNS ──
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}
