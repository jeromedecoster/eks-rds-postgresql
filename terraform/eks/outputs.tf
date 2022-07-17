output "project_name" {
  value = var.project_name
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "vpc_private_subnets" {
  value = data.aws_subnets.subnets_private.ids
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_iam_role_arn" {
  value = module.eks.cluster_iam_role_arn
}

output "eks_nodegroup_rolearn" {
  value = module.eks.eks_managed_node_groups.green.iam_role_arn
}

output "eks" {
  value = module.eks
}