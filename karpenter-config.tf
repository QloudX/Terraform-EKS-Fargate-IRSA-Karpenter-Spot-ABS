resource "kubectl_manifest" "karpenter_provisioner" {
  depends_on = [helm_release.karpenter]
  yaml_body  = file("${path.module}/karpenter-provisioner.yaml")
}

resource "kubectl_manifest" "karpenter_node_template" {
  depends_on = [helm_release.karpenter]

  yaml_body = templatefile("${path.module}/karpenter-node-template.yaml", {
    tags             = var.tags
    eks_cluster_name = module.eks_cluster.cluster_name
  })
}
