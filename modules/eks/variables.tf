variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster (control plane)"
  type        = string
  default     = "1.34"
}

variable "node_group_kubernetes_version" {
  description = "Kubernetes version for the managed node group. Null falls back to var.kubernetes_version. Set explicitly to hold the node group on an older version while the control plane upgrades ahead of it."
  type        = string
  default     = null
}

variable "node_group_ami_type" {
  description = "AMI type for the managed node group (e.g. BOTTLEROCKET_x86_64, AL2023_x86_64_STANDARD). Null uses the module default (AL2023_x86_64_STANDARD)."
  type        = string
  default     = null
}

variable "node_group_ami_release_version" {
  description = "Explicit AMI/Bottlerocket release version for the node group, e.g. from the SSM path for the chosen node_group_ami_type + node_group_kubernetes_version. Null floats to the latest available release for that type/version."
  type        = string
  default     = null
}

variable "vpc_cni_version" {
  description = "Explicit vpc-cni addon version (e.g. v1.22.3-eksbuild.1). Null uses most_recent."
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Explicit kube-proxy addon version. Null uses most_recent."
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Explicit coredns addon version. Null uses most_recent."
  type        = string
  default     = null
}

variable "pod_identity_agent_version" {
  description = "Explicit eks-pod-identity-agent addon version. Null uses most_recent."
  type        = string
  default     = null
}

variable "instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}