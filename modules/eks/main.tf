module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project}-${var.env}-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = true

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  addons = {
    vpc-cni = {
      addon_version  = var.vpc_cni_version
      most_recent    = var.vpc_cni_version == null
      before_compute = true
    }
    kube-proxy = {
      addon_version = var.kube_proxy_version
      most_recent   = var.kube_proxy_version == null
    }
    coredns = {
      addon_version = var.coredns_version
      most_recent   = var.coredns_version == null
    }
    eks-pod-identity-agent = {
      addon_version = var.pod_identity_agent_version
      most_recent   = var.pod_identity_agent_version == null
    }
  }

  eks_managed_node_groups = {
    main = {
      kubernetes_version             = var.node_group_kubernetes_version
      ami_type                       = var.node_group_ami_type
      ami_release_version            = var.node_group_ami_release_version
      use_latest_ami_release_version = var.node_group_ami_release_version == null
      instance_types                 = var.instance_types
      min_size                       = var.min_size
      max_size                       = var.max_size
      desired_size                   = var.desired_size
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}