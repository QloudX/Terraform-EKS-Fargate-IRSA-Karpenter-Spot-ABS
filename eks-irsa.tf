# This IRSA is for service accounts which don't need any AWS access at all.
# If you don't apply an IRSA to such service accounts...
# their pods can assume the node IAM role & use the AWS permissions defined therein.

module "deny_all_irsa" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.eks_cluster_name}-EKS-IRSA-DenyAll"
  tags      = var.tags

  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AWSDenyAll"
  }

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn = module.eks_cluster.oidc_provider_arn

      # It's safe to allow all service accounts to assume this IRSA...
      # because it denies all AWS permissions anyway.
      namespace_service_accounts = []
    }
  }
}

module "vpc_cni_irsa" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "${var.eks_cluster_name}-EKS-IRSA-VPC-CNI"
  tags      = var.tags

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    cluster-oidc-provider = {
      provider_arn               = module.eks_cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
