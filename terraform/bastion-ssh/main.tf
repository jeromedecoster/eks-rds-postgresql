provider "aws" {
  region = var.region
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "bastion_public_dns" {
  content = aws_instance.bastion.public_dns

  filename = "${path.module}/../../.env_BASTION_PUBLIC_DNS"
}

resource "local_file" "bastion_key_file" {
  # https://www.terraform.io/language/functions/abspath
  content = abspath(local_file.rsa_key_file.filename)

  filename = "${path.module}/../../.env_BASTION_KEY_FILE"
}