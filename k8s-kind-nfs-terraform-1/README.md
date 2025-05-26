### 1. Terraform 配置文件

创建一个名为 `main.tf` 的文件，并将以下内容粘贴到其中：

```hcl
# 配置Terraform提供商
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

# 创建Kind集群
resource "kind_cluster" "k8s_cluster" {
  name            = "kind-cluster"
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
    
    # 第一个工作节点
    node {
      role = "worker"
    }
    
    # 第二个工作节点
    node {
      role = "worker"
    }
  }
  wait_for_ready  = true
  kubeconfig_path = "~/.kube/config"
}

# 配置Kubernetes提供商以连接到Kind集群
provider "kubernetes" {
  config_path    = kind_cluster.k8s_cluster.kubeconfig_path
  config_context = "kind-${kind_cluster.k8s_cluster.name}"
}

# 部署NFS服务器到集群中
resource "null_resource" "deploy_nfs_server" {
  depends_on = [kind_cluster.k8s_cluster]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/nfs-deploy.yaml --kubeconfig=${kind_cluster.k8s_cluster.kubeconfig_path}"
  }
}

# 创建NFS PV和PVC的资源
resource "null_resource" "create_nfs_pv_pvc" {
  depends_on = [null_resource.deploy_nfs_server]

  provisioner "local-exec" {
    interpreter = ["cmd", "/C"]
    command = <<-EOT
      @REM 等待NFS服务器就绪
      kubectl wait --for=condition=ready pod -l app=nfs-server --timeout=120s --kubeconfig=${kind_cluster.k8s_cluster.kubeconfig_path}
      
      @REM 创建NFS PV和PVC的目录
      mkdir -p ${path.module}/../manifests
      
      @REM 创建NFS PV配置
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
      
      @REM 创建NFS PVC配置
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

# 部署 NFS 动态 Provisioner
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

# 创建 StorageClass
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
}

# 创建必要的 RBAC 权限
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

### 2. NFS 服务器部署文件

创建一个名为 `nfs-deploy.yaml` 的文件，并将以下内容粘贴到其中：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-server-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi  # 这里定义了NFS服务器使用的存储空间
---
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

### 3. 初始化和应用 Terraform 配置

在终端中，导航到包含 `main.tf` 和 `nfs-deploy.yaml` 文件的目录，并运行以下命令：

```bash
# 初始化 Terraform
terraform init

# 应用 Terraform 配置
terraform apply
```

### 4. 验证

应用完成后，你可以使用以下命令验证 NFS 服务器和 PVC 是否已成功创建：

```bash
kubectl get pods
kubectl get pvc
kubectl get pv
```

### 结论

以上步骤将创建一个 Kind Kubernetes 集群，部署 NFS 服务器，并自动创建 Persistent Volume 和动态 Persistent Volume Claim。确保在运行 Terraform 之前已安装并配置好 Kind 和 kubectl。