output "aws_vpc_id" {
  value = data.aws_vpc.vpc.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
output "aws_subnets_private_ids" {
  value = data.aws_subnets.subnets_private.ids
}

output "aws_subnets_public_ids" {
  value = data.aws_subnets.subnets_public.ids
}

output "aws_default_security_group_id" {
  value = data.aws_security_group.default_security_group.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#id
output "bastion_security_group_id" {
  value = aws_security_group.bastion_security_group.id
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}