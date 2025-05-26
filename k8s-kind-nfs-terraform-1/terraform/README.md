### 1. Terraform 配置文件

在你的 Terraform 项目中，确保有以下文件结构：

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── nfs-deploy.yaml
```

### 2. `main.tf` 文件

以下是 `main.tf` 文件的内容，包含创建 Kind 集群、NFS 服务器、PV 和 PVC 的配置：

```hcl
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
  }
}

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

resource "kind_cluster" "k8s_cluster" {
  name            = var.cluster_name
  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
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
    
    node {
      role = "worker"
    }
    
    node {
      role = "worker"
    }
  }
  wait_for_ready  = true
  kubeconfig_path = var.kubeconfig_path
}

provider "kubernetes" {
  config_path    = kind_cluster.k8s_cluster.kubeconfig_path
  config_context = "kind-${kind_cluster.k8s_cluster.name}"
}

resource "null_resource" "deploy_nfs_server" {
  depends_on = [kind_cluster.k8s_cluster]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/nfs-deploy.yaml --kubeconfig=${kind_cluster.k8s_cluster.kubeconfig_path}"
  }
}

resource "null_resource" "create_nfs_pv_pvc" {
  depends_on = [null_resource.deploy_nfs_server]

  provisioner "local-exec" {
    interpreter = ["cmd", "/C"]
    command = <<-EOT
      kubectl wait --for=condition=ready pod -l app=nfs-server --timeout=120s --kubeconfig=${kind_cluster.k8s_cluster.kubeconfig_path}
      mkdir -p ${path.module}/../manifests
      
      (echo apiVersion: v1
       echo kind: PersistentVolume
       echo metadata:
       echo   name: nfs-pv
       echo spec:
       echo   capacity:
       echo     storage: 1Gi
       echo   accessModes:
       echo     - ReadWriteMany
       echo   persistentVolumeReclaimPolicy: Retain
       echo   storageClassName: nfs
       echo   nfs:
       echo     server: nfs-server.default.svc.cluster.local
       echo     path: "/") > ${path.module}/../manifests/nfs-pv.yaml
      
      (echo apiVersion: v1
       echo kind: PersistentVolumeClaim
       echo metadata:
       echo   name: nfs-pvc
       echo spec:
       echo   accessModes:
       echo     - ReadWriteMany
       echo   storageClassName: nfs
       echo   resources:
       echo     requests:
       echo       storage: 1Gi) > ${path.module}/../manifests/nfs-pvc.yaml
    EOT
  }
}

resource "kubernetes_manifest" "nfs_provisioner" {
  depends_on = [kind_cluster.k8s_cluster]
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "nfs-subdir-external-provisioner"
      namespace = "default"
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "nfs-subdir-external-provisioner"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "nfs-subdir-external-provisioner"
          }
        }
        spec = {
          serviceAccountName = "nfs-provisioner"
          containers = [{
            name  = "nfs-subdir-external-provisioner"
            image = "registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"
            env = [{
              name = "NFS_SERVER"
              value = "nfs-server.default.svc.cluster.local"
            },{
              name = "NFS_PATH"
              value = "/"
            }]
          }]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "nfs_storageclass" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "nfs"
    }
    provisioner = "cluster.local/nfs-server-nfs-server-provisioner"
    parameters = {
      archiveOnDelete = "false"
    }
    reclaimPolicy = "Delete"
  }
  depends_on = [kubernetes_manifest.nfs_provisioner]
}

resource "kubernetes_manifest" "rbac" {
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "nfs-provisioner"
      namespace = "default"
    }
  }
}

resource "local_file" "kubeconfig" {
  content  = kind_cluster.k8s_cluster.kubeconfig
  filename = "d:/itzdd-lab/k8s-kind-nfs-terraform/terraform/_kubeconfig/config"
}
```

### 3. `nfs-deploy.yaml` 文件

在 `nfs-deploy.yaml` 文件中，定义 NFS 服务器的部署和服务：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  template:
    metadata:
      labels:
        app: nfs-server
    spec:
      containers:
      - name: nfs-server
        image: itsthenetwork/nfs-server-alpine:latest
        ports:
          - name: nfs
            containerPort: 2049
          - name: mountd
            containerPort: 20048
          - name: rpcbind
            containerPort: 111
        securityContext:
          privileged: true
        env:
          - name: SHARED_DIRECTORY
            value: /exports
        volumeMounts:
          - mountPath: /exports
            name: nfs-vol
      volumes:
        - name: nfs-vol
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: nfs-server
spec:
  ports:
  - name: nfs
    port: 2049
  - name: mountd
    port: 20048
  - name: rpcbind
    port: 111
  selector:
    app: nfs-server
```

### 4. 运行 Terraform

在你的项目目录中，运行以下命令来初始化 Terraform、创建 Kind 集群并部署 NFS 服务器：

```bash
terraform init
terraform apply
```

### 5. 验证

完成后，你可以使用以下命令验证 PV 和 PVC 是否已成功创建：

```bash
kubectl get pv
kubectl get pvc
```

这将显示你创建的 Persistent Volume 和 Persistent Volume Claim 的状态。

### 总结

以上步骤将帮助你创建一个使用 NFS StorageClass 的 Kind Kubernetes 集群项目，并自动创建 Persistent Volume 和动态 Persistent Volume Claim。确保根据你的环境和需求调整配置。