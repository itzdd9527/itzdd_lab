# 配置Terraform提供商
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.0.16"
    }
  }
}

# 创建Kind集群
resource "kind_cluster" "k8s_cluster" {
  name = var.cluster_name
  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    # 控制平面节点
    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\""
      ]
      extra_port_mappings {
        container_port = 80
        host_port = 80
        protocol = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port = 443
        protocol = "TCP"
      }
    }
    
    # 两个工作节点
    node {
      role = "worker"
    }
    node {
      role = "worker"
    }
  }
  wait_for_ready = true
}

# 保存 kubeconfig 文件
resource "local_file" "kubeconfig" {
  content  = kind_cluster.k8s_cluster.kubeconfig
  filename = "${path.module}/_kubeconfig/config"
}

# 部署NFS服务器到集群中
resource "null_resource" "deploy_nfs_server" {
  depends_on = [kind_cluster.k8s_cluster]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/nfs-deploy.yaml --kubeconfig=${local_file.kubeconfig.filename}"
  }
}

# 等待NFS Server就绪
resource "null_resource" "wait_for_nfs" {
  depends_on = [null_resource.deploy_nfs_server]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app=nfs-server --timeout=120s --kubeconfig=${local_file.kubeconfig.filename}"
  }
}

# 输出变量已移至 outputs.tf