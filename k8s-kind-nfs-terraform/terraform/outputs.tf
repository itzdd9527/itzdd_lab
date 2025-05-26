output "kubeconfig_path" {
  description = "Kind集群的kubeconfig文件路径"
  value       = local_file.kubeconfig.filename
}

output "cluster_name" {
  description = "Kind集群的名称"
  value       = kind_cluster.k8s_cluster.name
}

output "kubectl_command" {
  description = "用于连接到集群的kubectl命令示例"
  value       = "kubectl --kubeconfig=${local_file.kubeconfig.filename} get nodes"
}