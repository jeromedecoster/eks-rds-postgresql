#!/bin/bash

#
# variables
#
# AWS variables
export AWS_PROFILE=default
export AWS_REGION=eu-west-3
# project variables
export PROJECT_NAME=eks-rds
export POSTGRES_DATABASE=vote
export POSTGRES_USERNAME=master
export POSTGRES_PASSWORD=masterpass
# the directory containing the script file
export PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"

#
# overwrite TF variables
#
export TF_VAR_project_name=$PROJECT_NAME
export TF_VAR_region=$AWS_REGION
export TF_VAR_postgres_database=$POSTGRES_DATABASE
export TF_VAR_postgres_username=$POSTGRES_USERNAME
export TF_VAR_postgres_password=$POSTGRES_PASSWORD

log() { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }          # $1 uppercase background white
info() { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }       # $1 uppercase background green
warn() { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; }  # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red

# export functions : https://unix.stackexchange.com/a/22867
export -f log info warn error

# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

# 0) run postgres alpine docker image
pg() {
  # stop previous
  ID=$(docker stop $(docker ps -a -q -f name=postgres) 2>/dev/null)
  if [[ -n "$ID" ]]; then
    docker rm --force $ID 2>/dev/null
  fi

  docker run \
    --rm \
    --name postgres \
    --env POSTGRES_PASSWORD=password \
    --publish 5432:5432 \
    postgres:14.3-alpine
    # --env POSTGRES_USER=postgres \
    # --env POSTGRES_DATABASE=postgres \
}

# 0) seed postgres instance
seed() {
  psql postgresql://postgres:password@0.0.0.0:5432/postgres < sql/create.sql
}

# 0) run vote website using npm - dev mode
vote() {
  cd vote
  # https://unix.stackexchange.com/a/454554
  command npm install
  npx livereload . --wait 200 --extraExts 'njk' & \
    NODE_ENV=development \
    VERSION=od1s2faz \
    WEBSITE_PORT=4000 \
    POSTGRES_DATABASE=postgres \
    POSTGRES_PASSWORD=password \
    npx nodemon --ext js,json,njk index.js
    # POSTGRES_USER=postgres \
    # POSTGRES_HOST=127.0.0.1 \
}

# 0) run the project using docker-compose (same as postgres + vote + ...)
up() {
  export COMPOSE_PROJECT_NAME=eks_rds
  docker-compose \
      --file docker-compose.dev.yml \
      up \
      --remove-orphans \
      --force-recreate \
      --build \
      --no-deps 
}

# 0) stop docker-compose + remove volumes
down() {
  export COMPOSE_PROJECT_NAME=eks_rds
  docker-compose \
    --file docker-compose.dev.yml \
    down \
    --volumes
}


# 1) terraform create vpc + rds postgresql db + ecr repo
rds-ecr-create() {
    export CHDIR="$PROJECT_DIR/terraform/rds-ecr"
    scripts/terraform-init.sh
    scripts/terraform-validate.sh
    scripts/terraform-apply.sh
}

# 1) terraform create ec2 bastion for ssh tunnel
bastion-ssh-create() {
    export CHDIR="$PROJECT_DIR/terraform/bastion-ssh"
    scripts/terraform-init.sh
    scripts/terraform-validate.sh
    scripts/terraform-apply.sh
}

# 1) create ssh tunnel
ssh-create() {
  bash scripts/ssh-create.sh
}

# 1) seed rds postgresql
seed-aws() {
  psql postgresql://$POSTGRES_USERNAME:$POSTGRES_PASSWORD@127.0.0.1:5433/$POSTGRES_DATABASE?sslmode=require < sql/create.sql
}

# 1) run vote website using npm - dev mode (livereload + nodemon)
vote-aws() {
  cd vote
  # https://unix.stackexchange.com/a/454554
  command npm install
  npx livereload . --wait 750 --extraExts 'njk' & \
    NODE_ENV=development \
    VERSION=od1s2faz \
    WEBSITE_PORT=4000 \
    POSTGRES_HOST=127.0.0.1 \
    POSTGRES_DATABASE=$POSTGRES_DATABASE \
    POSTGRES_USER=$POSTGRES_USERNAME \
    POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    POSTGRES_PORT=5433 \
    npx nodemon --ext js,json,njk index.js
}

# 1) close ssh tunnel
ssh-close() {
  bash scripts/ssh-close.sh
}

# 1) terraform destroy ec2 bastion for ssh tunnel
bastion-ssh-destroy() {
    terraform -chdir=$PROJECT_DIR/terraform/bastion-ssh destroy -auto-approve
}



build() {
  cd "$PROJECT_DIR/vote"
  docker image build \
    --file Dockerfile \
    --tag vote \
    .
}

# 2) push vote image to ecr
ecr-push() {
    info MAKE build
    build

    AWS_ACCOUNT_ID=$(cat $PROJECT_DIR/.env_AWS_ACCOUNT_ID)
    log AWS_ACCOUNT_ID $AWS_ACCOUNT_ID

    REPOSITORY_URL=$(cat $PROJECT_DIR/.env_REPOSITORY_URL)
    log REPOSITORY_URL $REPOSITORY_URL

    # add login data into /home/$USER/.docker/config.json (create or update authorization token)
    aws ecr get-login-password \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        | docker login \
        --username AWS \
        --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    # https://docs.docker.com/engine/reference/commandline/tag/
    docker tag vote $REPOSITORY_URL:vote
    # https://docs.docker.com/engine/reference/commandline/push/
    docker push $REPOSITORY_URL:vote
}

# 2) terraform create eks cluster
eks-create() {
    export CHDIR="$PROJECT_DIR/terraform/eks"
    scripts/terraform-init.sh
    scripts/terraform-validate.sh
    scripts/terraform-apply.sh
}

# 2) kubectl deploy vote
kubectl-vote() {
    REPOSITORY_URL=$(cat $PROJECT_DIR/.env_REPOSITORY_URL)
    log REPOSITORY_URL $REPOSITORY_URL

    DB_ADDRESS=$(cat $PROJECT_DIR/.env_DB_ADDRESS)
    log DB_ADDRESS $DB_ADDRESS
    
    kubectl apply --filename k8s/namespace.yaml
    kubectl apply --filename k8s/service.yaml

    # https://github.com/frigus02/kyml#kyml-tmpl---inject-dynamic-values
    kyml tmpl \
        -v DOCKER_IMAGE=$REPOSITORY_URL:vote \
        -v POSTGRES_HOST=$DB_ADDRESS \
        -v POSTGRES_DATABASE=$POSTGRES_DATABASE \
        -v POSTGRES_USER=$POSTGRES_USERNAME \
        -v POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        < k8s/deployment.yaml \
        | kubectl apply -f -
}

# 2) get load balancer url
load-balancer() {
    LOAD_BALANCER=$(kubectl get svc vote \
        --namespace vote \
        --output json \
        | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
    log LOAD_BALANCER $LOAD_BALANCER
}


# 3) terraform destroy eks cluster
eks-destroy() {
    kubectl delete ns vote --ignore-not-found --wait

    AWS_ACCOUNT_ID=$(cat $PROJECT_DIR/.env_AWS_ACCOUNT_ID)
    log AWS_ACCOUNT_ID $AWS_ACCOUNT_ID

    terraform -chdir=$PROJECT_DIR/terraform/eks destroy -auto-approve

    kubectl config delete-context $PROJECT_NAME
    kubectl config delete-cluster arn:aws:eks:$AWS_REGION:$AWS_ACCOUNT_ID:cluster/$PROJECT_NAME
    # kubectl config unset current-context
}

# 3) terraform destroy vpc + rds postgresql db + ecr repo
rds-ecr-destroy() {
    terraform -chdir=$PROJECT_DIR/terraform/rds-ecr destroy -auto-approve
}



# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && {
    info execute $1
    eval $1
} || usage
exit 0
