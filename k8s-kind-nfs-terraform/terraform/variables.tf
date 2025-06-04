variable "cluster_name" {
  description = "Kind集群的名称"
  type        = string
  default     = "kind-cluster"
}

variable "kubeconfig_path" {
  description = "kubeconfig文件的路径"
  type        = string
  default     = "~/.kube/config"
}