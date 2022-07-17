# https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = var.project_name
  cluster_version = "1.22"

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.subnets_private.ids

  # cluster_endpoint_private_access = true
  # cluster_endpoint_public_access  = true

  eks_managed_node_group_defaults = {
    disk_size      = 8
    instance_types = ["t2.medium"]
  }

  # Add IAM user ARNs to aws-auth configmap to be able to manage EKS from the AWS website

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md#input_create_aws_auth_configmap
  # create_aws_auth_configmap = true

  # /!\ https://github.com/terraform-aws-modules/terraform-aws-eks/issues/911#issuecomment-640702294
  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md#input_manage_aws_auth_configmap
  manage_aws_auth_configmap = true

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md#input_aws_auth_users
  aws_auth_users = [
    {
      "userarn" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      "groups" : ["system:masters"]
    }
  ]

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md#input_aws_auth_accounts
  aws_auth_accounts = [
    data.aws_caller_identity.current.account_id
  ]


  eks_managed_node_groups = {

    green = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t2.medium"]
      capacity_type  = "ON_DEMAND" # SPOT
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

}

# https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md#output_cluster_id
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_id} --region ${var.region}"
  }

  depends_on = [module.eks]
}

/* 
  /!\ Important

  Uncomment the resource below to create a new
  inbound rule to the VPC default security group 
  
*/

/* 

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# allow the pods from the `green` node group to be connected
# with the rds postgreSQL instance (allow inbound port 5432)
resource "aws_security_group_rule" "postgresql_ec2_instances_sg" {
  # this rule is added to the security group defined by `security_group_id`
  # and this id target the `default` security group associated with the created VPC
  security_group_id = data.aws_security_group.default_security_group.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 5432
  to_port   = 5432

  # One of ['cidr_blocks', 'ipv6_cidr_blocks', 'self', 'source_security_group_id', 'prefix_list_ids']
  # must be set to create an AWS Security Group Rule
  source_security_group_id = module.eks.eks_managed_node_groups.green.security_group_id

  lifecycle {
    create_before_destroy = true
  }
}
*/