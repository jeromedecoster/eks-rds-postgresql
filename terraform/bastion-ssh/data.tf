# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones#attributes-reference
data "aws_availability_zones" "zones" {}

# get VPC data. Find VPC by Name via tag
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc#tags
data "aws_vpc" "vpc" {
  # defined in rds-ecr/vpc.tf
  tags = {
    Name = var.project_name
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "subnets_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  # target a specific subnet by exact tag name
  # /!\ case sensitive : attribute is `Name` not `name`
  # tags = {
  #   Name = "eks-rds-private-eu-west-3a"
  # }

  # /!\ tag name are automatically created
  # by the module `terraform-aws-modules/vpc/aws`
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "subnets_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group
data "aws_security_group" "default_security_group" {
  vpc_id = data.aws_vpc.vpc.id
  # /!\ the `name` attribute target the `Security group name` column in the website page
  #     not the `Name` column, which is the `tag:Name` value
  # https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroups.html
  name = "default"
}

data "http" "my_ip" {
  url = "https://ifconfig.me"
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type (first line of Amazon Linux AMI)
    values = ["amzn2-ami-kernel-5*-x86_64-gp2"]

    # Amazon Linux 2 AMI (HVM) - Kernel 4.14, SSD Volume Type (second line of Amazon Linux AMI)
    # values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}