# ZenPharma Dev Environment — managed via GitHub Actions CI/CD
locals {
  project = "pharma"
  env     = "dev"
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  project               = local.project
  env                   = local.env
  region                = local.region
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
}


module "eks" {
  source = "../../modules/eks"

  project    = local.project
  env        = local.env
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # Staged 1.34 -> 1.35 upgrade: control plane, then node group, then add-ons, one apply each.
  # Stage 1 (current): control plane moves to 1.35; node group and add-ons pinned at their
  #   current 1.34 versions below, so this apply touches only the control plane.
  # Stage 2: once the control plane is healthy, move the node group to 1.35 and switch it to
  #   Bottlerocket in the same apply (both force a node replacement, so bundle them):
  #     node_group_kubernetes_version  = "1.35"
  #     node_group_ami_type            = "BOTTLEROCKET_x86_64"
  #     node_group_ami_release_version = "1.63.0-d4932ff8"
  #       (from SSM /aws/service/bottlerocket/aws-k8s-1.35/x86_64/latest/image_version -
  #       re-check this value at apply time, it may have moved on)
  # Stage 3: once the node group is healthy, bump the add-on versions to their 1.35 defaults
  #   (confirm via `aws eks describe-addon-versions --addon-name <name> --kubernetes-version 1.35`):
  #     kube_proxy_version = "v1.35.3-eksbuild.17"
  #     coredns_version    = "v1.13.2-eksbuild.11"
  #   (vpc_cni_version and pod_identity_agent_version are unchanged between 1.34 and 1.35)
  kubernetes_version            = "1.34"
  node_group_kubernetes_version = "1.34"
  vpc_cni_version               = "v1.22.3-eksbuild.1"
  kube_proxy_version            = "v1.34.6-eksbuild.17"
  coredns_version               = "v1.12.4-eksbuild.18"
  pod_identity_agent_version    = "v1.3.10-eksbuild.3"

  instance_types = ["t3.small"]
  min_size       = 1
  max_size       = 3
  desired_size   = 3
}

module "rds" {
  source = "../../modules/rds"

  project                    = local.project
  env                        = local.env
  username                   = "pharmaadmin"
  password                   = var.db_password
  vpc_id                     = module.vpc.vpc_id
  db_subnet_group_name       = module.vpc.database_subnet_group_name
  eks_node_security_group_id = module.eks.node_security_group_id
}

module "ecr" {
  source = "../../modules/ecr"

  project = local.project
  env     = local.env
  repositories = [
    "api-gateway",
    "auth-service",
    "drug-catalog-service",
    "inventory-service",
    "manufacturing-service",
    "notification-service",
    "pharma-ui",
    "supplier-service",
    "qc-service",
  ]
}

module "iam" {
  source = "../../modules/iam"

  project           = local.project
  env               = local.env
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  aws_account_id    = data.aws_caller_identity.current.account_id
  github_org        = var.github_org
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project     = local.project
  env         = local.env
  db_username = "pharmaadmin"
  db_password = var.db_password
  db_host     = module.rds.db_instance_address
  jwt_secret  = var.jwt_secret
}