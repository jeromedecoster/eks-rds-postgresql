/**/
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "db" {
  allocated_storage = 5
  engine            = "postgres"
  #   engine_version       = "5.7"
  instance_class = "db.t3.micro"

  db_name    = var.postgres_database
  identifier = var.postgres_database
  username   = var.postgres_username
  password   = var.postgres_password
  #   parameter_group_name = "default.mysql5.7"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#db_subnet_group_name
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#vpc_security_group_ids
  vpc_security_group_ids = [aws_default_security_group.vpc_security_group.id]

  publicly_accessible = false
  skip_final_snapshot = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = var.project_name
  }
}
