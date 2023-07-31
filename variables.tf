variable "aws_region" {}
variable "tags" { type = map(string) }

variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "eks_cluster_name" {
  default = "my-cluster"
}
variable "eks_cluster_version" {
  default = "1.27"
}

variable "karpenter_version" {
  description = "https://gallery.ecr.aws/karpenter/karpenter"
  default     = "v0.29.2"
}
