.SILENT:
.PHONY: vote

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-22s\033[0m%s\n", $$1, $$2 }'


pg: # 0) run postgres alpine docker image
	./make.sh pg

seed: # 0) seed postgres instance
	./make.sh seed

vote: # 0) run vote website using npm - dev mode
	./make.sh vote

up: # 0) run the project using docker-compose (same as pg + seed + vote)
	./make.sh up

down: # 0) stop docker-compose + remove volumes
	./make.sh down


rds-ecr-create: # 1) terraform create vpc + rds postgresql db + ecr repo
	./make.sh rds-ecr-create

bastion-ssh-create: # 1) terraform create ec2 bastion for ssh tunnel
	./make.sh bastion-ssh-create

ssh-create: # 1) create ssh tunnel
	./make.sh ssh-create

seed-aws: # 1) seed rds postgresql
	./make.sh seed-aws

vote-aws: # 1) run vote website using npm - dev mode (livereload + nodemon)
	./make.sh vote-aws

ssh-close: # 1) close ssh tunnel
	./make.sh ssh-close

bastion-ssh-destroy: # 1) terraform destroy ec2 bastion for ssh tunnel
	./make.sh bastion-ssh-destroy


ecr-push: # 2) push vote image to ecr
	./make.sh ecr-push

eks-create: # 2) terraform create eks cluster
	./make.sh eks-create

kubectl-vote: # 2) kubectl deploy vote
	./make.sh kubectl-vote

load-balancer: # 2) get load balancer url
	./make.sh load-balancer


eks-destroy: # 3) terraform destroy eks cluster
	./make.sh eks-destroy

rds-ecr-destroy: # 3) terraform destroy vpc + rds postgresql db + ecr repo
	./make.sh rds-ecr-destroy
