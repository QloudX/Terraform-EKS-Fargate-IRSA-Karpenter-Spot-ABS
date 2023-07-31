module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  control_plane_subnet_ids       = var.public_subnets
  cluster_endpoint_public_access = true

  cluster_enabled_log_types = [] # Disable logging
  cluster_encryption_config = {} # Disable secrets encryption

  tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.eks_cluster_name
  })

  # Fargate profiles use the cluster's primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profiles = {
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
  }

  cluster_addons = {
    kube-proxy = {
      most_recent = true

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.deny_all_irsa.iam_role_arn
    }

    vpc-cni = {
      most_recent = true

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.vpc_cni_irsa.iam_role_arn
    }

    coredns = {
      most_recent = true

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = module.deny_all_irsa.iam_role_arn

      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:nodes", "system:bootstrappers"]
    }
    # Add your org roles here to allow them cluster access
  ]
}
