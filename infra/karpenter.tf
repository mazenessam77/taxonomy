###############################################################################
# Karpenter — Spot Instance Node Provisioner
###############################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.8"

  cluster_name = module.eks.cluster_name

  # Create IAM role for Karpenter controller (IRSA)
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  # Create the node IAM role that Karpenter-provisioned nodes will use
  create_node_iam_role = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

###############################################################################
# Helm: Karpenter Controller (runs on On-Demand system nodes)
###############################################################################

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.35.2"

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }

  set {
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
  }

  # Schedule Karpenter on the On-Demand system node group
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

  depends_on = [module.eks, module.karpenter]
}

###############################################################################
# Karpenter NodePool — EC2 Spot Instances for Application Workloads
###############################################################################

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
        Project: ${var.project_name}
        Environment: ${var.environment}
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: application-spot
    spec:
      template:
        metadata:
          labels:
            node-role: application
        spec:
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r", "t"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["4"]
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["medium", "large", "xlarge"]
            - key: topology.kubernetes.io/zone
              operator: In
              values: ${jsonencode(local.azs)}
          nodeClassRef:
            name: default
      limits:
        cpu: "100"
        memory: 200Gi
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}
