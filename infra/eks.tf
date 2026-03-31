###############################################################################
# Amazon EKS Cluster + Managed Node Group (On-Demand for System Workloads)
###############################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = "${local.name}-cluster"
  cluster_version = var.cluster_version

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Public + private endpoint (private-only in hardened setups)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # ── Cluster Add-ons ──
  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType = "ec2"
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  # ── Managed Node Group: System Workloads (On-Demand) ──
  eks_managed_node_groups = {
    system = {
      name            = "${local.name}-system"
      description     = "On-Demand managed node group for system workloads (CoreDNS, LB Controller, Karpenter)"
      instance_types  = var.system_node_instance_types
      capacity_type   = "ON_DEMAND"

      min_size     = var.system_node_min_size
      max_size     = var.system_node_max_size
      desired_size = var.system_node_desired_size

      labels = {
        "node-role" = "system"
      }

      taints = {
        system = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      tags = {
        "karpenter.sh/discovery" = "${local.name}-cluster"
      }
    }
  }

  # ── Fargate Profile (Serverless Compute) ──
  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  # ── Access Management ──
  enable_cluster_creator_admin_permissions = true

  # Allow Karpenter role to join nodes
  node_security_group_tags = {
    "karpenter.sh/discovery" = "${local.name}-cluster"
  }

  tags = local.tags
}

###############################################################################
# IRSA: AWS Load Balancer Controller
###############################################################################

module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name                              = "${local.name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

###############################################################################
# Helm: AWS Load Balancer Controller
###############################################################################

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_controller_irsa.iam_role_arn
  }

  set {
    name  = "region"
    value = local.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  # Tolerate system node taints
  set {
    name  = "tolerations[0].key"
    value = "CriticalAddonsOnly"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "nodeSelector.node-role"
    value = "system"
  }

  depends_on = [module.eks]
}
