# https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  # set tag
  name = var.project_name

  cidr = "10.0.0.0/16"
  azs  = data.aws_availability_zones.zones.names

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  # rds require at least 2 subnet to launch an instance
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  # /!\ required to create the EKS cluster
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group
resource "aws_default_security_group" "vpc_security_group" {
  vpc_id = module.vpc.vpc_id

  # allow all inbound traffic 
  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  # allow all outbound traffic
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-default-sg"
  }
}

