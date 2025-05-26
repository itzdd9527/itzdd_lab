# 配置 Terraform 提供商
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.0.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}

# 创建 Kind 集群
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

# 配置 Kubernetes Provider
provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

# 配置 Helm Provider
provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

# 创建 NFS 服务器所需的命名空间
resource "kubernetes_namespace" "nfs" {
  depends_on = [local_file.kubeconfig]
  metadata {
    name = "nfs-system"
  }
}

# 部署基础 NFS 服务器
resource "null_resource" "deploy_nfs_server" {
  depends_on = [kubernetes_namespace.nfs]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/nfs-deploy.yaml --kubeconfig=${local_file.kubeconfig.filename}"
  }
}

# 等待 NFS Server 就绪
resource "null_resource" "wait_for_nfs" {
  depends_on = [null_resource.deploy_nfs_server]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pod -l app=nfs-server -n nfs-system --timeout=120s --kubeconfig=${local_file.kubeconfig.filename}"
  }
}

# 部署 NFS 动态供应器
resource "helm_release" "nfs_subdir_external_provisioner" {
  depends_on = [null_resource.wait_for_nfs]
  
  name       = "nfs-subdir-external-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner"
  chart      = "nfs-subdir-external-provisioner"
  namespace  = "nfs-system"
  
  set {
    name  = "nfs.server"
    value = "nfs-server.nfs-system.svc.cluster.local"
  }
  
  set {
    name  = "nfs.path"
    value = "/"
  }
  
  set {
    name  = "storageClass.name"
    value = "nfs-client"
  }
  
  set {
    name  = "storageClass.defaultClass"
    value = "true"
  }
}

# 创建示例 PVC 来测试动态供应
resource "kubernetes_persistent_volume_claim" "test_pvc" {
  depends_on = [helm_release.nfs_subdir_external_provisioner]
  
  metadata {
    name      = "test-pvc"
    namespace = "default"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "nfs-client"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}
