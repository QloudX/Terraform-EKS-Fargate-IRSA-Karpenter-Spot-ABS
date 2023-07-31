data "aws_ecrpublic_authorization_token" "ecr_auth_token" {}

module "karpenter" {
  source       = "terraform-aws-modules/eks/aws//modules/karpenter"
  tags         = var.tags
  cluster_name = module.eks_cluster.cluster_name

  irsa_oidc_provider_arn       = module.eks_cluster.oidc_provider_arn
  iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  repository_username = data.aws_ecrpublic_authorization_token.ecr_auth_token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.ecr_auth_token.password

  lifecycle {
    ignore_changes = [repository_password]
  }

  set {
    name  = "settings.aws.clusterName"
    value = module.eks_cluster.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks_cluster.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}
