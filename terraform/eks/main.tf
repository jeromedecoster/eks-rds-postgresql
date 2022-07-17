provider "aws" {
  region = var.region
}

# /!\ provider declared because declaring "manage_aws_auth_configmap = true" in "terraform-aws-modules/eks/aws" module
# throwan error if provider "kubernetes" is not defined
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/911#issuecomment-640702294
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}