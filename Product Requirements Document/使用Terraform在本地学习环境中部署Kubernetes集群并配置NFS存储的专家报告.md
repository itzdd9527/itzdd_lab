# 使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告

## I. 报告引言

本报告旨在详细阐述如何利用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储。报告将针对不同学习阶段（初学者、深入学习、快速测试）提供定制化的解决方案，并着重强调所有配置的代码化、跨平台兼容性以及环境的可迁移性。具体需求涵盖了单节点或多节点Kubernetes集群的部署，将NFS作为持久卷（PV）和持久卷声明（PVC）的存储后端。报告将深入探讨每种方案的优缺点、提供完整的Terraform配置代码示例、详细的验证步骤、推荐方案、版本控制的实现说明，以及主机资源要求、注意事项和相关参考文档链接。

## II. 概述：Terraform在本地Kubernetes环境中的优势

Terraform作为HashiCorp开发的一款基础设施即代码（IaC）工具，通过声明式语言（HashiCorp Configuration Language, HCL）描述基础设施资源及其期望状态 1。在本地Kubernetes学习环境中，使用Terraform进行部署具有显著优势：

首先，Terraform能够自动化虚拟机（VM）或容器的配置过程，从而节省大量手动设置时间，并确保环境的一致性 2。这种自动化对于开发和测试至关重要，因为它消除了手动操作可能引入的配置偏差，保证了每次部署的环境都完全相同。

其次，Terraform通过其丰富的提供商（Provider）生态系统，能够与各种本地虚拟化平台（如VirtualBox、Docker）和Kubernetes API进行交互 1。提供商是Terraform与外部API通信的插件，每个提供商都提供了一组资源类型来管理基础设施对象，例如虚拟机、网络接口或Kubernetes资源 1。这种设计使得Terraform能够统一管理从底层虚拟机到上层Kubernetes资源的整个基础设施栈。

此外，Terraform的配置是代码化的，这意味着基础设施的定义可以像应用程序代码一样进行版本控制、审查和共享 2。这极大地增强了环境的可重复性和可移植性，使得学习者能够轻松地在不同机器或操作系统上重建相同的环境，或者与团队成员共享复杂的设置。通过将基础设施定义为代码，可以清晰地追踪每次更改，并在需要时回滚到先前的状态，从而有效管理基础设施的演变。

## III. 主机资源要求与先决条件

在本地环境中部署Kubernetes集群和NFS存储，对主机资源和预装软件有明确要求。

**通用先决条件：**

所有解决方案都要求主机预装以下核心工具：

- **Terraform**: 作为基础设施即代码工具，Terraform是所有部署方案的基础 2。
- **VirtualBox 或 Docker Desktop**: 根据所选的Kubernetes部署方案，需要安装相应的虚拟化或容器化平台。VirtualBox用于创建虚拟机，而Docker Desktop则为Kind和Minikube提供容器运行时环境 2。
- **kubectl**: Kubernetes命令行工具，用于与Kubernetes集群交互，验证部署和管理资源 5。
- **SSH客户端**: 对于涉及虚拟机（特别是Kubeadm方案）的部署，需要SSH客户端以便Terraform通过`remote-exec`配置远程VM 11。

**针对不同Kubernetes集群类型的资源要求：**

- **Kind集群（Kubernetes IN Docker）**：
  - **Docker Desktop**: Kind集群在Docker容器内运行Kubernetes，因此Docker是其核心依赖 5。
  - **内存与CPU**: Kind集群的资源消耗通常低于基于虚拟机的方案。然而，Docker Desktop本身需要足够的资源分配。官方建议Docker Desktop至少分配8GB的RAM，以获得最佳体验，尤其是在多节点Kind集群场景下 9。如果计划从源代码构建Kind节点镜像，还需要安装Go语言环境 10。
  - Kind的轻量级特性使其适用于资源受限的机器，但如果Docker Desktop的资源配置不足，可能导致性能问题或集群不稳定 10。
- **Minikube集群**：
  - **CPU**: 2个或更多CPU核心 8。
  - **内存**: 2GB或更多可用内存 8。
  - **磁盘空间**: 20GB或更多可用磁盘空间 8。
  - **容器或虚拟机管理器**: 如Docker、VirtualBox、Hyper-V等 8。
  - Minikube的Docker驱动在Linux上运行时，由于不需要额外的虚拟化层，其RAM需求可能更低 13。
- **Kubeadm集群（基于VirtualBox虚拟机）**：
  - **CPU**: 控制平面节点至少需要2个CPU核心 15。工作节点通常建议至少1-2个CPU核心 19。
  - **内存**: 每个机器至少2GB RAM，以确保应用程序有足够的运行空间 15。对于更复杂的集群配置（例如，包含3个主节点和2个工作节点的HA集群），总内存需求可能高达8.25GB或更多 17。
  - **磁盘空间**: 至少20GB的空闲磁盘空间 18。
  - **网络连接**: 集群中所有机器之间需要有完整的网络连接 15。
  - **唯一标识符**: 每个节点必须具有唯一的hostname、MAC地址和`product_uuid` 16。
  - **禁用Swap**: `kubelet`默认情况下会因检测到Swap内存而启动失败，因此需要在所有节点上禁用Swap 22。
  - **开放端口**: Kubernetes组件之间需要开放特定端口进行通信 16。

资源分配是决定本地Kubernetes环境稳定性和性能的关键因素。如果主机资源不足，即使成功部署，也可能导致性能下降、应用程序崩溃或集群组件无法正常运行 24。因此，在选择解决方案之前，评估主机资源并根据所选方案进行适当配置至关重要。

## IV. 方案一：初学者型 - 单节点Kind/Minikube集群与静态NFS存储

### 方案概述与适用场景

此方案专为Kubernetes初学者设计，旨在提供一个快速、轻量且易于管理的本地学习环境。它利用Kind或Minikube在单节点上部署Kubernetes集群，并结合手动配置的主机NFS存储，通过Kubernetes的持久卷（PV）和持久卷声明（PVC）机制实现静态存储。这种方法简化了集群和存储的复杂性，使学习者能够专注于Kubernetes核心概念，如Pod、Deployment、Service以及持久化存储的基本用法。

该方案特别适用于：

- **Kubernetes入门**：快速搭建环境，理解Pod、Service、Deployment等基本概念。
- **持久化存储初探**：学习PV和PVC的静态绑定机制，了解应用程序如何消费持久存储。
- **资源受限环境**：Kind和Minikube相较于虚拟机集群，资源消耗更低，适合配置较低的个人电脑 5。
- **快速原型验证**：需要快速验证应用程序在Kubernetes中与NFS存储的兼容性。

### 优缺点分析

**优点：**

- **部署速度快**：Kind和Minikube集群启动迅速，通常只需几分钟 25。
- **资源占用低**：相较于基于虚拟机的多节点集群，Kind和Minikube对主机资源（CPU、内存）的要求更低，尤其是在单节点配置下 10。
- **易于管理和销毁**：整个环境可以通过简单的Terraform命令快速创建和销毁 2。
- **聚焦核心概念**：简化了底层基础设施的复杂性，使学习者能够专注于Kubernetes的抽象层和存储模型。

**缺点：**

- **非生产级模拟**：单节点集群不具备高可用性，且无法完全模拟多节点集群的复杂交互和调度行为。
- **NFS服务器手动配置**：NFS服务器需要手动在主机操作系统上进行配置，这不符合“所有配置代码化”的严格要求，降低了环境的整体可移植性 28。这种手动配置引入了对特定主机操作系统的依赖，使得环境在不同主机间迁移时需要额外的适配工作。
- **静态存储限制**：仅支持静态PV配置，不涉及动态存储供应，无法体验Kubernetes存储的自动化和按需分配能力。
- **网络配置局限性**：Kind/Minikube集群的网络通常是容器内部网络或通过Docker桥接网络与主机通信，直接依赖主机NFS可能需要额外的网络配置考虑，例如Docker桥接IP地址的识别。

### Terraform配置代码示例

本方案将提供Kind和Minikube两种集群的Terraform配置示例，并统一NFS存储的配置方式。

#### 创建Kind集群

Kind（Kubernetes IN Docker）允许在Docker容器中运行Kubernetes集群 5。`tehcyx/kind`提供商可用于通过Terraform管理Kind集群 30。

Terraform

```
# versions.tf
terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "~> 0.0.16" # 检查最新兼容版本
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0" # 检查最新兼容版本
    }
  }
}

# main.tf for Kind
provider "kind" {}

resource "kind_cluster" "single_node_kind_cluster" {
  name = "beginner-kind-cluster"
  # 可选: 指定Kubernetes版本
  # node_image = "kindest/node:v1.28.0" # 示例，请查阅Kind releases以获取可用镜像
  
  # 单控制平面节点配置 (如果省略nodes块，则为默认配置)
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    nodes {
      role = "control-plane"
    }
    # 可选: 如果需要外部访问（例如Ingress控制器），可映射端口
    # extra_port_mappings {
    #   container_port = 30000
    #   host_port      = 30000
    #   protocol       = "TCP"
    # }
  }
  wait_for_ready = true # 等待控制平面就绪 [30]
}

# 配置Kubernetes提供商以连接到Kind集群
# Kind默认将kubeconfig直接输出到~/.kube/config [7]
# Kubernetes提供商可以从该路径读取配置 [32]
provider "kubernetes" {
  # tehcyx/kind提供商直接暴露kubeconfig属性 [30]
  # 优先使用config_path，因为这是kubectl和其他工具的默认行为
  config_path = "~/.kube/config" # kubectl和许多工具的默认路径 [7, 32]
  # 如果提供商不直接输出kubeconfig路径，则需要使用local-exec来获取kubeconfig内容并写入文件，然后引用该文件。
  # 但对于Kind来说，通常不需要这么复杂。
  host                   = kind_cluster.single_node_kind_cluster.kubeconfig_path!= null? null : kind_cluster.single_node_kind_cluster.endpoint
  client_certificate     = kind_cluster.single_node_kind_cluster.kubeconfig_path!= null? null : kind_cluster.single_node_kind_cluster.client_certificate
  client_key             = kind_cluster.single_node_kind_cluster.kubeconfig_path!= null? null : kind_cluster.single_node_kind_cluster.client_key
  cluster_ca_certificate = kind_cluster.single_node_kind_cluster.kubeconfig_path!= null? null : kind_cluster.single_node_kind_cluster.cluster_ca_certificate
}
```

#### 创建Minikube集群

Minikube允许在本地机器上运行单节点Kubernetes集群，支持多种驱动（如Docker、VirtualBox） 5。`scott-the-programmer/minikube`提供商可用于通过Terraform管理Minikube集群 33。

Terraform

```
# versions.tf (与Kind方案相同，确保minikube提供商已添加)
terraform {
  required_providers {
    minikube = {
      source = "scott-the-programmer/minikube"
      version = "~> 0.4" # 检查最新兼容版本
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0" # 检查最新兼容版本
    }
  }
}

# main.tf for Minikube
provider "minikube" {
  kubernetes_version = "v1.28.0" # 示例，选择一个支持的版本
}

resource "minikube_cluster" "single_node_minikube_cluster" {
  cluster_name = "beginner-minikube-cluster"
  driver       = "docker" # 或 "virtualbox" [35]
  cpus         = 2  # Minikube要求 [8]
  memory       = "4g" # Minikube要求 [8]
  disk_size    = "20g" # Minikube要求 [8]
  addons = [
    "default-storageclass", # 确保为PVC提供默认存储类 [33, 35]
    "storage-provisioner"   # 用于动态供应（如果以后需要），但这里是基本设置
  ]
}

# 配置Kubernetes提供商以连接到Minikube集群
# Minikube提供商直接输出凭据 [33, 35, 36]
provider "kubernetes" {
  host                   = minikube_cluster.single_node_minikube_cluster.host
  client_certificate     = minikube_cluster.single_node_minikube_cluster.client_certificate
  client_key             = minikube_cluster.single_node_minikube_cluster.client_key
  cluster_ca_certificate = minikube_cluster.single_node_minikube_cluster.cluster_ca_certificate
}
```

#### 配置NFS服务器（手动主机设置）

此步骤在运行Terraform之前，需要在主机操作系统上手动完成。这是为了简化初学者的入门流程，但需要注意的是，这种手动配置会牺牲一部分“所有配置代码化”的严格性，从而影响环境的整体可移植性。

1. 安装NFS服务器软件包：

   在主机（例如Ubuntu/Debian）上执行：

   Bash

   ```
   sudo apt update && sudo apt install -y nfs-kernel-server
   ```

   28

2. **创建共享目录**：

   Bash

   ```
   sudo mkdir -p /mnt/nfs_share
   ```

   28

3. 设置目录权限：

   为了让Kubernetes Pod能够写入，需要设置适当的权限。nobody:nogroup通常用于NFS共享，以避免UID/GID不匹配的问题，但对于Kubernetes，no_root_squash有时是必要的，以允许root用户（通常是容器内部进程）在NFS共享上拥有root权限 39。

   Bash

   ```
   sudo chown -R nobody:nogroup /mnt/nfs_share
   sudo chmod 777 /mnt/nfs_share
   ```

   29

4. 配置/etc/exports文件：

   编辑/etc/exports文件，添加以下行。<K8s_Node_IP>应替换为你的Kind/Minikube节点IP。对于Kind/Minikube，这通常是Docker桥接IP（例如172.17.0.1）或主机自身的IP。为了最广泛的访问，可以使用*来允许所有客户端访问，但这在生产环境中不推荐 37。

   ```
   /mnt/nfs_share <K8s_Node_IP>(rw,sync,no_subtree_check,no_root_squash)
   ```

   例如，如果你的Docker桥接IP是`172.17.0.1`，则为：

   ```
   /mnt/nfs_share 172.17.0.1(rw,sync,no_subtree_check,no_root_squash)
   ```

   28

5. **应用导出并重启NFS服务**：

   Bash

   ```
   sudo exportfs -ar
   sudo systemctl restart nfs-kernel-server
   ```

   28

#### 定义Kubernetes PersistentVolume (PV)

在Kubernetes中，PV代表集群中由管理员提供的网络存储 43。这里我们将创建一个静态PV，它直接指向主机上已配置的NFS共享。

Terraform

```
# pv.tf
resource "kubernetes_persistent_volume" "nfs_pv_static" {
  metadata {
    name = "nfs-static-pv"
    labels = {
      type = "nfs-static"
    }
  }
  spec {
    capacity = {
      storage = "5Gi" # 对于NFS，此大小主要是象征性的，不影响实际共享大小 [28]
    }
    access_modes = # 允许多个节点读写 [28, 43, 45, 46, 47, 48]
    persistent_volume_reclaim_policy = "Retain" # PVC删除后保留PV [43, 44, 47, 48, 49, 50]
    nfs {
      server = "<NFS_SERVER_IP>" # 替换为你的主机IP或Docker桥接IP
      path   = "/mnt/nfs_share"  # 主机上导出的路径 [28, 29, 37]
      read_only = false # 允许写入 [43, 44]
    }
    # node_affinity 可以用于特定节点绑定 [43, 49]
    # 对于单节点Kind/Minikube，这可能不是严格必要的，但仍是良好实践。
  }
}
```

#### 定义Kubernetes PersistentVolumeClaim (PVC)

PVC是用户对存储的请求，它将绑定到符合其要求的PV 44。

Terraform

```
# pvc.tf
resource "kubernetes_persistent_volume_claim" "nfs_pvc_static" {
  metadata {
    name = "nfs-static-pvc"
  }
  spec {
    access_modes = # 必须与PV匹配 [45, 46]
    resources {
      requests = {
        storage = "1Gi" # 请求大小，应小于或等于PV容量
      }
    }
    volume_name = kubernetes_persistent_volume.nfs_pv_static.metadata.name # 显式绑定到PV [46, 47]
    storage_class_name = "" # 对于静态供应至关重要 [28, 47]
    wait_until_bound = true # 等待PVC绑定 [46]
  }
}

# 示例Pod使用PVC
resource "kubernetes_pod" "test_pod_static_nfs" {
  metadata {
    name = "test-pod-static-nfs"
  }
  spec {
    container {
      image = "nginx:latest"
      name  = "nginx-container"
      volume_mounts {
        mount_path = "/usr/share/nginx/html"
        name       = "nfs-storage"
      }
    }
    volume {
      name = "nfs-storage"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.nfs_pvc_static.metadata.name
      }
    }
  }
}
```

### 验证步骤

1. Terraform 应用：

   在包含上述.tf文件的目录下，执行以下命令：

   Bash

   ```
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

2. Kubernetes 集群状态检查：

   确认Kind/Minikube集群节点处于Ready状态：

   Bash

   ```
   kubectl get nodes
   ```

   预期输出应显示一个`Ready`状态的节点。

3. NFS 服务器检查：

   在主机上，验证NFS共享是否已正确导出：

   Bash

   ```
   showmount -e <主机IP>
   ```

   预期输出应显示`/mnt/nfs_share`已被导出 29。

4. PV/PVC 状态检查：

   检查PV和PVC是否已成功绑定：

   Bash

   ```
   kubectl get pv nfs-static-pv
   kubectl get pvc nfs-static-pvc
   ```

   预期输出中，`STATUS`列应显示为`Bound` 56。如果PVC长时间处于`Pending`状态，通常表明没有匹配的PV或存储类配置不正确 59。

5. Pod 挂载验证：

   验证Pod是否已成功运行并挂载了NFS共享：

   Bash

   ```
   kubectl get pods test-pod-static-nfs
   ```

   预期输出应显示Pod处于Running状态。

   进入Pod的shell，验证NFS挂载点：

   Bash

   ```
   kubectl exec -it test-pod-static-nfs -- /bin/bash
   ```

   在Pod内部，检查挂载目录：

   Bash

   ```
   ls -l /usr/share/nginx/html/
   ```

   该目录最初应为空或包含Nginx默认文件。创建一个测试文件：

   Bash

   ```
   echo "Hello NFS from Kubernetes Pod" > /usr/share/nginx/html/test.txt
   ```

   退出Pod的shell。回到主机，验证NFS共享目录中是否存在该文件：

   Bash

   ```
   cat /mnt/nfs_share/test.txt
   ```

   预期输出应显示“Hello NFS from Kubernetes Pod”。这确认了NFS共享已正确挂载并实现了持久化存储。

6. 清理：

   完成测试后，销毁Terraform部署的资源：

   Bash

   ```
   terraform destroy --auto-approve
   ```

   手动删除主机上的测试文件：

   Bash

   ```
   sudo rm /mnt/nfs_share/test.txt
   ```

## V. 方案二：深入学习型 - 多节点Kubeadm集群与动态NFS存储

### 方案概述与适用场景

此方案旨在为学习者提供一个更接近生产环境的多节点Kubernetes集群。它使用VirtualBox虚拟机部署Kubeadm集群，并通过Terraform实现虚拟机创建、操作系统配置和Kubernetes组件安装的全程自动化。存储方面，它引入了动态NFS存储，通过部署`nfs-subdir-external-provisioner`来自动化PV的创建，从而更深入地模拟真实世界的存储管理。

该方案特别适用于：

- **深入理解Kubernetes架构**：学习多主节点、多工作节点集群的构建和高可用性概念（尽管本示例为单主节点，但可扩展）。
- **Kubeadm工作原理**：掌握Kubeadm初始化主节点、加入工作节点以及网络插件配置的细节。
- **基础设施即代码高级实践**：利用Terraform的`remote-exec`和`file` provisioner进行复杂的远程配置和文件传输，以及依赖关系管理。
- **动态存储供应**：理解StorageClass、PersistentVolumeClaim和动态PV供应器的工作机制。
- **环境完全可迁移性**：由于整个环境（包括NFS服务器）都封装在Terraform管理的虚拟机中，因此具有高度的可移植性。

### 优缺点分析

**优点：**

- **生产级环境模拟**：多节点Kubeadm集群提供了更真实的Kubernetes部署体验，有助于理解集群内部组件的交互和分布式系统的挑战 15。
- **虚拟机完全IaC**：Terraform全面管理虚拟机的创建、网络配置和操作系统级别软件安装，确保环境的一致性和可重复性 2。这种对整个基础设施栈的IaC覆盖，使得环境在不同主机间迁移时变得高度可控。
- **动态存储供应**：引入了Kubernetes核心的`StorageClass`和自动PV创建机制，这是生产环境中广泛使用的存储模式，极大地提高了存储管理的自动化水平 28。
- **增强学习深度**：涵盖了虚拟机间的网络配置、Kubeadm引导过程以及更高级的存储概念，为学习者提供了宝贵的实践经验。
- **高可移植性**：由于NFS服务器也被部署在Terraform管理的虚拟机中，整个Kubernetes和存储环境是自包含的，可以轻松地将虚拟机镜像或Terraform配置迁移到其他支持VirtualBox的主机上。

**缺点：**

- **高资源要求**：多台VirtualBox虚拟机将消耗大量CPU和RAM资源，可能对主机性能造成显著影响 17。
- **设置复杂性高**：涉及虚拟机配置、操作系统初始化、Kubeadm安装、网络设置以及NFS服务器配置等多个层面，需要精心编排和调试 11。
- **部署时间长**：启动多台虚拟机并执行大量远程脚本需要较长时间，远超基于容器的解决方案。
- **潜在的平台特定问题**：尽管Terraform致力于跨平台兼容，但底层虚拟机镜像和用于Kubeadm/NFS设置的shell命令可能仍存在操作系统特定的细微差别，需要仔细测试和调整。

### Terraform配置代码示例

本方案的Terraform配置将分为多个文件，以提高可读性和模块化。

#### `versions.tf`

Terraform

```
# versions.tf
terraform {
  required_providers {
    virtualbox = {
      source = "alouette/virtualbox"
      version = "~> 1.0" # 检查最新兼容版本
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.0"
    }
    # 用于生成SSH密钥
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
    # 用于将SSH私钥写入本地文件
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
    # 用于从远程VM获取kubeadm join命令
    external = {
      source = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}
```

#### `variables.tf`

Terraform

```
# variables.tf
variable "vm_count" {
  description = "工作节点VM的数量"
  type        = number
  default     = 1 # 示例：1个工作节点，可根据需求增加
}

variable "vm_memory" {
  description = "每台VM的内存大小（MB）"
  type        = number
  default     = 2048 # 2GB [64]
}

variable "vm_cpus" {
  description = "每台VM的CPU核心数"
  type        = number
  default     = 2 # [17, 18]
}

variable "nfs_server_ip" {
  description = "NFS服务器VM的IP地址"
  type        = string
  default     = "192.168.56.10" # 示例：在host-only网络中的IP
}

variable "k8s_master_ip" {
  description = "Kubernetes主节点VM的IP地址"
  type        = string
  default     = "192.168.56.11" # 示例：在host-only网络中的IP
}

variable "k8s_worker_ips" {
  description = "Kubernetes工作节点VM的IP地址列表"
  type        = list(string)
  default     = ["192.168.56.12", "192.168.56.13"] # 示例IP，确保数量与vm_count匹配
}
```

#### `main.tf`

Terraform

```
# main.tf
# 生成SSH密钥对，用于Terraform连接虚拟机
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 将SSH私钥保存到本地文件
resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_openssh
  filename = "id_rsa_kubeadm"
  file_permission = "0600" # 确保私钥文件权限正确
}

# 创建VirtualBox Host-Only网络，用于VMs之间的私有通信
resource "virtualbox_network" "k8s_host_only_network" {
  name = "vboxnet0" # 默认VirtualBox Host-Only网络名称
  ipv4 {
    ip      = "192.168.56.1" # Host-Only网络的网关IP
    netmask = "255.255.255.0"
    dhcp    = false # 我们将分配静态IP
  }
}

# 创建NFS服务器VM
resource "virtualbox_vm" "nfs_server_vm" {
  name        = "nfs-server"
  image       = "ubuntu/jammy64" # 或其他合适的Ubuntu基础镜像
  cpus        = var.vm_cpus
  memory      = var.vm_memory
  network_adapter {
    type            = "hostonly"
    host_only_network = virtualbox_network.k8s_host_only_network.name
    ipv4_address    = var.nfs_server_ip
    ipv4_netmask    = "255.255.255.0"
  }
  # 添加第二个网卡用于互联网访问（NAT或桥接）
  network_adapter {
    type = "nat" # 用于互联网访问
  }
  lifecycle {
    prevent_destroy = false
  }
}

# 创建Kubernetes主节点VM
resource "virtualbox_vm" "k8s_master_vm" {
  name        = "k8s-master"
  image       = "ubuntu/jammy64"
  cpus        = var.vm_cpus
  memory      = var.vm_memory
  network_adapter {
    type            = "hostonly"
    host_only_network = virtualbox_network.k8s_host_only_network.name
    ipv4_address    = var.k8s_master_ip
    ipv4_netmask    = "255.255.255.0"
  }
  network_adapter {
    type = "nat" # 用于互联网访问
  }
  lifecycle {
    prevent_destroy = false
  }
}

# 创建Kubernetes工作节点VMs
resource "virtualbox_vm" "k8s_worker_vms" {
  count       = var.vm_count
  name        = "k8s-worker-${count.index + 1}"
  image       = "ubuntu/jammy64"
  cpus        = var.vm_cpus
  memory      = var.vm_memory
  network_adapter {
    type            = "hostonly"
    host_only_network = virtualbox_network.k8s_host_only_network.name
    ipv4_address    = var.k8s_worker_ips[count.index]
    ipv4_netmask    = "255.255.255.0"
  }
  network_adapter {
    type = "nat" # 用于互联网访问
  }
  lifecycle {
    prevent_destroy = false
  }
}
```

#### 配置Kubeadm（通过Remote-Exec）

此部分使用Terraform的`null_resource`和`remote-exec` provisioner在虚拟机上执行shell脚本，实现Kubernetes的安装和配置。这种方法允许将复杂的操作系统级设置封装在脚本中，并通过Terraform进行编排。

**`scripts/install_k8s_common.sh`** (在所有Kubeadm VM上执行的通用脚本)

Bash

```
#!/bin/bash
set -euo pipefail

# 禁用swap，Kubeadm要求 [22, 23]
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - |
| true

# 启用iptables桥接流量，Kubeadm要求 [22, 23]
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system # 立即应用sysctl参数 [23]

# 安装containerd运行时 [22, 23, 69]
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg2 software-properties-common apt-transport-https

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y containerd.io

# 配置containerd以使用systemd cgroup驱动
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 安装kubeadm, kubelet, kubectl [22, 23, 69]
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl # 锁定版本，防止自动升级 [22]
```

**`scripts/init_master.sh`** (在Kubernetes主节点VM上执行的脚本)

Bash

```
#!/bin/bash
set -euo pipefail

MASTER_IP=$1

# 初始化Kubernetes主节点 [11, 15, 70, 71, 72]
# --pod-network-cidr 用于CNI（例如Calico: 192.168.0.0/16, Flannel: 10.244.0.0/16）
# --apiserver-advertise-address 绑定到私有IP [15, 21]
sudo kubeadm init --pod-network-cidr "192.168.0.0/16" --apiserver-advertise-address="${MASTER_IP}" --cri-socket "unix:///var/run/containerd/containerd.sock"

# 为ubuntu用户配置kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config # [15, 21]

# 安装Calico CNI（示例） [73, 74]
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# 生成工作节点加入命令 [75, 76, 77]
kubeadm token create --print-join-command > /tmp/kubeadm_join_command.sh
chmod +x /tmp/kubeadm_join_command.sh

# 如果需要，允许在主节点上调度Pod（用于单节点测试或特定需求）
# kubectl taint nodes --all node-role.kubernetes.io/control-plane- # [15]
```

**`scripts/join_worker.sh`** (在Kubernetes工作节点VM上执行的脚本)

Bash

```
#!/bin/bash
set -euo pipefail

JOIN_COMMAND=$1

# 工作节点加入集群 [11, 15, 75, 76, 78, 79]
sudo $JOIN_COMMAND --cri-socket "unix:///var/run/containerd/containerd.sock"
```

**`main.tf` (续)**

Terraform

```
# 在主节点VM上安装K8s通用组件
resource "null_resource" "install_common_k8s_master" {
  depends_on = [virtualbox_vm.k8s_master_vm] # 依赖于VM创建完成
  connection {
    type        = "ssh"
    user        = "ubuntu" # Ubuntu云镜像的默认用户
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_master_vm.ipv4_address
    timeout     = "10m"
  }
  provisioner "file" { # 复制脚本到远程VM [80]
    source      = "scripts/install_k8s_common.sh"
    destination = "/tmp/install_k8s_common.sh"
  }
  provisioner "remote-exec" { # 执行远程脚本 [70, 71, 78, 81]
    inline = [
      "chmod +x /tmp/install_k8s_common.sh",
      "sudo /tmp/install_k8s_common.sh"
    ]
  }
}

# 初始化Kubernetes主节点
resource "null_resource" "init_k8s_master" {
  depends_on = [null_resource.install_common_k8s_master] # 依赖于通用组件安装完成
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_master_vm.ipv4_address
    timeout     = "15m"
  }
  provisioner "file" {
    source      = "scripts/init_master.sh"
    destination = "/tmp/init_master.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init_master.sh",
      "sudo /tmp/init_master.sh ${var.k8s_master_ip}",
      # 从主节点提取kubeconfig到远程VM的/tmp，以便后续复制到本地 [82, 83, 84, 85]
      "sudo cat /etc/kubernetes/admin.conf > /tmp/admin.conf"
    ]
  }
  provisioner "file" { # 将kubeconfig从主节点复制到本地机器 [80, 82, 83, 84, 85]
    source      = "/tmp/admin.conf" # 远程VM上的源路径
    destination = "kubeconfig_master.yaml" # 本地机器上的目标路径
    direction   = "download" # 指定为下载操作
  }
}

# 从主节点获取kubeadm join命令
# 使用data "external"资源执行本地命令（ssh到远程VM并获取命令），并将输出解析为JSON [85]
data "external" "kubeadm_join_command" {
  program =
  depends_on = [null_resource.init_k8s_master] # 依赖于主节点初始化完成
}

# 在工作节点VM上安装K8s通用组件
resource "null_resource" "install_common_k8s_workers" {
  count = var.vm_count
  depends_on = [virtualbox_vm.k8s_worker_vms[count.index]]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_worker_vms[count.index].ipv4_address
    timeout     = "10m"
  }
  provisioner "file" {
    source      = "scripts/install_k8s_common.sh"
    destination = "/tmp/install_k8s_common.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k8s_common.sh",
      "sudo /tmp/install_k8s_common.sh"
    ]
  }
}

# 工作节点加入Kubernetes集群
resource "null_resource" "join_k8s_workers" {
  count = var.vm_count
  depends_on = [
    null_resource.install_common_k8s_workers[count.index],
    null_resource.init_k8s_master # 工作节点必须等待主节点初始化和token生成
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_worker_vms[count.index].ipv4_address
    timeout     = "15m"
  }
  provisioner "file" {
    source      = "scripts/join_worker.sh"
    destination = "/tmp/join_worker.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join_worker.sh",
      # 将join命令作为参数传递给脚本
      "sudo /tmp/join_worker.sh ${data.external.kubeadm_join_command.result.join_command}"
    ]
  }
}

# 配置Kubernetes提供商以连接到Kubeadm集群
provider "kubernetes" {
  config_path = "./kubeconfig_master.yaml" # 使用复制到本地的kubeconfig文件 [32]
}
```

#### 部署NFS服务器与NFS Subdir External Provisioner

此部分在专门的NFS服务器VM上部署NFS服务，并在Kubernetes集群中部署动态NFS供应器。

**`scripts/setup_nfs_server.sh`** (在NFS服务器VM上执行的脚本)

Bash

```
#!/bin/bash
set -euo pipefail

NFS_SHARE_PATH="/mnt/k8s_nfs_share"
K8S_MASTER_IP=$1
K8S_WORKER_IPS=$2

sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server rpcbind

sudo mkdir -p ${NFS_SHARE_PATH}
sudo chown -R nobody:nogroup ${NFS_SHARE_PATH}
sudo chmod 777 ${NFS_SHARE_PATH}

# 清除现有导出并添加新的导出配置
sudo cp /etc/exports /etc/exports.bak
sudo sh -c "echo '' > /etc/exports" # 清空内容

# 将主节点和工作节点IP添加到exports配置中
echo "${NFS_SHARE_PATH} ${K8S_MASTER_IP}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
# 遍历工作节点IP列表，逐一添加到exports
IFS=',' read -ra ADDR <<< "$K8S_WORKER_IPS"
for ip in "${ADDR[@]}"; do
  echo "${NFS_SHARE_PATH} ${ip}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
done

sudo exportfs -ar # 重新导出所有共享 [28, 29, 37, 38]
sudo systemctl restart nfs-kernel-server
```

**`scripts/install_nfs_client.sh`** (在K8s主节点和工作节点VM上执行的脚本)

Bash

```
#!/bin/bash
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y nfs-common # 安装NFS客户端工具 [28, 37]
```

**`main.tf` (续)**

Terraform

```
# 在NFS服务器VM上设置NFS服务
resource "null_resource" "setup_nfs_server" {
  depends_on = [virtualbox_vm.nfs_server_vm]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.nfs_server_vm.ipv4_address
    timeout     = "5m"
  }
  provisioner "file" {
    source      = "scripts/setup_nfs_server.sh"
    destination = "/tmp/setup_nfs_server.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_nfs_server.sh",
      # 将主节点和工作节点IP作为参数传递给脚本
      "sudo /tmp/setup_nfs_server.sh ${virtualbox_vm.k8s_master_vm.ipv4_address} \"${join(",", virtualbox_vm.k8s_worker_vms.*.ipv4_address)}\""
    ]
  }
}

# 在Kubernetes主节点上安装NFS客户端
resource "null_resource" "install_nfs_client_master" {
  depends_on = [null_resource.init_k8s_master, null_resource.setup_nfs_server] # 依赖于K8s主节点初始化和NFS服务器设置完成
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_master_vm.ipv4_address
    timeout     = "5m"
  }
  provisioner "file" {
    source      = "scripts/install_nfs_client.sh"
    destination = "/tmp/install_nfs_client.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_nfs_client.sh",
      "sudo /tmp/install_nfs_client.sh"
    ]
  }
}

# 在Kubernetes工作节点上安装NFS客户端
resource "null_resource" "install_nfs_client_workers" {
  count = var.vm_count
  depends_on = [
    null_resource.join_k8s_workers[count.index],
    null_resource.setup_nfs_server
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local_file.private_key_pem.filename)
    host        = virtualbox_vm.k8s_worker_vms[count.index].ipv4_address
    timeout     = "5m"
  }
  provisioner "file" {
    source      = "scripts/install_nfs_client.sh"
    destination = "/tmp/install_nfs_client.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_nfs_client.sh",
      "sudo /tmp/install_nfs_client.sh"
    ]
  }
}

# 使用Helm部署NFS Subdir External Provisioner
resource "helm_release" "nfs_provisioner" {
  depends_on =
  name       = "nfs-subdir-external-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  chart      = "nfs-subdir-external-provisioner"
  namespace  = "nfs-provisioner"
  create_namespace = true
  version    = "4.0.18" # 检查最新兼容版本 [67]

  set {
    name  = "nfs.server"
    value = virtualbox_vm.nfs_server_vm.ipv4_address
  }
  set {
    name  = "nfs.path"
    value = "/mnt/k8s_nfs_share"
  }
  set {
    name  = "storageClass.name"
    value = "nfs-dynamic"
  }
  set {
    name  = "storageClass.defaultClass"
    value = true # 将此设置为默认存储类 [67, 68]
  }
  set {
    name  = "storageClass.reclaimPolicy"
    value = "Delete" # PVC删除时，PV也删除 [67, 68]
  }
  set {
    name  = "storageClass.archiveOnDelete"
    value = "true" # PVC删除后，数据保留在NFS服务器上以供检查
  }
}
```

#### 配置Kubernetes StorageClass实现动态PV

`helm_release`资源部署`nfs-subdir-external-provisioner`时会自动创建一个名为`nfs-dynamic`的StorageClass。因此，这里只需定义一个请求该StorageClass的PVC。

Terraform

```
# pvc_dynamic.tf
resource "kubernetes_persistent_volume_claim" "nfs_pvc_dynamic" {
  metadata {
    name = "nfs-dynamic-pvc"
  }
  spec {
    access_modes = # 必须与NFS的访问模式匹配 [45, 46]
    resources {
      requests = {
        storage = "2Gi" # 请求存储大小
      }
    }
    storage_class_name = helm_release.nfs_provisioner.name # 引用由Helm部署的StorageClass [28, 65, 67]
    wait_until_bound = true # 等待PVC绑定
  }
}

# 示例Pod使用动态供应的PVC
resource "kubernetes_pod" "test_pod_dynamic_nfs" {
  metadata {
    name = "test-pod-dynamic-nfs"
  }
  spec {
    container {
      image = "nginx:latest"
      name  = "nginx-container"
      volume_mounts {
        mount_path = "/usr/share/nginx/html"
        name       = "nfs-storage"
      }
    }
    volume {
      name = "nfs-storage"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.nfs_pvc_dynamic.metadata.name
      }
    }
  }
}
```

### 验证步骤

1. Terraform 应用：

   在包含所有.tf文件的目录下，执行以下命令：

   Bash

   ```
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

   此步骤将需要较长时间，因为它涉及创建多台虚拟机、安装操作系统和Kubernetes组件。

2. 虚拟机状态检查：

   打开VirtualBox管理器，确认所有虚拟机（nfs-server、k8s-master、k8s-worker-1等）都已启动并运行。尝试通过SSH连接到这些VM，验证其可访问性。

3. Kubernetes 集群状态检查：

   确认Kubernetes集群节点处于Ready状态：

   Bash

   ```
   kubectl get nodes
   ```

   预期输出应显示主节点和所有工作节点处于Ready状态。

   检查kube-system命名空间下的核心Pod是否正常运行：

   Bash

   ```
   kubectl get pods -n kube-system
   ```

   预期输出应显示CoreDNS、kube-proxy和Calico（或其他CNI）的Pod处于`Running`状态。

4. NFS 服务器检查：

   通过SSH连接到nfs-server虚拟机，验证NFS共享是否已正确导出：

   Bash

   ```
   showmount -e
   ```

   预期输出应显示`/mnt/k8s_nfs_share`已被导出。

5. NFS 供应器状态检查：

   检查NFS供应器Pod是否正常运行，以及nfs-dynamic存储类是否已创建并设置为默认：

   Bash

   ```
   kubectl get pods -n nfs-provisioner
   kubectl get storageclass
   ```

   预期输出应显示供应器Pod处于`Running`状态，且`nfs-dynamic`存储类存在，并可能被标记为默认。

6. PVC/PV 动态供应验证：

   检查PVC是否已成功绑定，以及是否已动态创建了对应的PV：

   Bash

   ```
   kubectl get pvc nfs-dynamic-pvc
   kubectl get pv
   ```

   预期输出中，`nfs-dynamic-pvc`的`STATUS`应为`Bound`，并且会看到一个新创建的PV，其`STATUS`也为`Bound`。检查PV的详细信息，确认其NFS服务器IP和路径正确：

   Bash

   ```
   kubectl describe pv <动态创建的PV名称>
   ```

7. Pod 挂载验证：

   验证Pod是否已成功运行并挂载了NFS共享：

   Bash

   ```
   kubectl get pods test-pod-dynamic-nfs
   ```

   预期输出应显示Pod处于Running状态。

   进入Pod的shell，在挂载点创建测试文件：

   Bash

   ```
   kubectl exec -it test-pod-dynamic-nfs -- /bin/bash
   ```

   在Pod内部：

   Bash

   ```
   echo "Dynamic NFS Test from Kubernetes Pod" > /usr/share/nginx/html/dynamic_test.txt
   ```

   退出Pod的shell。通过SSH连接到`nfs-server`虚拟机，检查NFS共享目录中是否存在该文件。动态供应器会在NFS共享下为每个PV创建一个子目录，因此文件路径会包含PVC名称和PV的UUID：

   Bash

   ```
   ls -l /mnt/k8s_nfs_share/default-nfs-dynamic-pvc-<PV_UUID>/dynamic_test.txt
   cat /mnt/k8s_nfs_share/default-nfs-dynamic-pvc-<PV_UUID>/dynamic_test.txt
   ```

   预期输出应显示文件存在且包含“Dynamic NFS Test from Kubernetes Pod”。这确认了动态供应和持久化存储的正确性。

8. 清理：

   完成测试后，销毁Terraform部署的所有资源：

   Bash

   ```
   terraform destroy --auto-approve
   ```

## VI. 方案三：快速测试型 - Kind/Minikube集群与简易NFS挂载

### 方案概述与适用场景

此方案旨在提供最快速的Kubernetes集群与NFS存储集成，适用于需要迅速验证应用程序与NFS共享兼容性的场景，或者在主机资源非常有限的情况下。它沿用了方案一中轻量级的Kind或Minikube单节点集群，但为了极致的部署速度，直接在Pod定义中挂载NFS共享，完全跳过了Kubernetes的PV/PVC抽象层。

该方案特别适用于：

- **极速原型验证**：需要立即测试应用程序对NFS读写操作的兼容性。
- **资源极度受限**：当主机资源无法支持更复杂的VM或动态存储设置时。
- **临时性测试**：用于一次性、短期的功能验证，而非长期学习或开发。

### 优缺点分析

**优点：**

- **部署速度极快**：利用Kind/Minikube的快速启动特性，并省略了PV/PVC的创建和绑定过程，使得整个环境启动时间最短。
- **配置极其简洁**：直接在Pod定义中指定NFS服务器地址和路径，配置代码量最少。
- **资源高效**：与方案一类似，Kind/Minikube作为轻量级集群，资源占用较低。

**缺点：**

- **非Kubernetes范式**：此方案绕过了Kubernetes的持久卷（PV）和持久卷声明（PVC）抽象，这与Kubernetes推荐的存储管理方式相悖 48。这使得Pod直接依赖于底层的存储实现，降低了Pod的可移植性和灵活性。
- **可移植性受限**：Pod的配置直接硬编码了NFS服务器的IP地址和导出路径，使得Pod与特定NFS服务器紧密耦合，难以在不同环境中复用。
- **无动态供应能力**：不支持StorageClass和自动PV管理，无法体验Kubernetes存储的自动化特性。
- **手动NFS服务器设置**：NFS服务器仍需在主机上进行手动配置，与方案一的缺点相同。
- **不适用于深入学习**：由于跳过了核心的PV/PVC抽象，不建议用于深入学习Kubernetes的存储管理。

### Terraform配置代码示例

本方案将重用方案一中的Kind或Minikube集群配置，并在此基础上直接在Pod中挂载NFS。

#### 创建Kind/Minikube集群

此步骤与方案一完全相同。请根据你的需求选择Kind或Minikube的配置，并确保其已定义且Kubernetes提供商已配置。

Terraform

```
# 假设已重用方案一中的Kind或Minikube集群配置，
# 并且 `kind_cluster.single_node_kind_cluster` 或 `minikube_cluster.single_node_minikube_cluster`
# 以及 `provider "kubernetes"` 已定义。
# 此外，NFS服务器仍需按照方案一的要求在主机上进行手动设置。
```

#### 直接在Pod中挂载NFS

此部分直接在`kubernetes_pod`资源中定义NFS卷。

Terraform

```
# pod_direct_nfs.tf
resource "kubernetes_pod" "test_pod_direct_nfs" {
  metadata {
    name = "test-pod-direct-nfs"
  }
  spec {
    container {
      image = "busybox:latest" # 使用轻量级busybox镜像进行测试
      name  = "busybox-container"
      # 持续向NFS共享写入时间戳，验证挂载和持久性
      command = ["sh", "-c", "while true; do echo $(date) >> /mnt/nfs/test.txt; sleep 5; done"]
      volume_mounts {
        mount_path = "/mnt/nfs"
        name       = "nfs-volume"
      }
    }
    volume {
      name = "nfs-volume"
      nfs {
        server = "<NFS_SERVER_IP>" # 替换为你的主机IP
        path   = "/mnt/nfs_share"  # 主机上导出的NFS路径
        read_only = false # 允许写入 [29]
      }
    }
  }
}
```

### 验证步骤

1. Terraform 应用：

   在包含.tf文件的目录下，执行以下命令：

   Bash

   ```
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

2. Kubernetes 集群状态检查：

   确认Kind/Minikube集群节点处于Ready状态：

   Bash

   ```
   kubectl get nodes
   ```

3. Pod 状态检查：

   检查Pod是否已成功运行：

   Bash

   ```
   kubectl get pods test-pod-direct-nfs
   ```

   预期输出应显示Pod处于`Running`状态。

4. NFS 服务器检查：

   在主机上，检查NFS共享目录中是否正在生成由Pod写入的test.txt文件：

   Bash

   ```
   cat /mnt/nfs_share/test.txt
   ```

   预期输出应显示不断更新的时间戳，这表明Pod已成功挂载NFS共享并正在写入数据。

5. 清理：

   完成测试后，销毁Terraform部署的资源：

   Bash

   ```
   terraform destroy --auto-approve
   ```

   手动删除主机上生成的`test.txt`文件：

   Bash

   ```
   sudo rm /mnt/nfs_share/test.txt
   ```

## VII. 方案比较与推荐

### 各方案特性对比

下表详细对比了三种解决方案的关键特性，以帮助学习者根据自身需求做出选择。

| **特性**              | **方案一：初学者型 (Kind/Minikube + 静态NFS)** | **方案二：深入学习型 (Kubeadm + 动态NFS)**               | **方案三：快速测试型 (Kind/Minikube + 直接NFS)** |
| --------------------- | ---------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------ |
| **学习阶段**          | 初学者、基础概念学习                           | 深入学习、生产环境模拟                                   | 快速验证、临时测试                               |
| **集群类型**          | 单节点Kind/Minikube                            | 多节点Kubeadm (VirtualBox VM)                            | 单节点Kind/Minikube                              |
| **节点数量**          | 1个控制平面节点                                | 1个控制平面节点 + N个工作节点 + 1个NFS服务器VM           | 1个控制平面节点                                  |
| **基于VM/容器**       | 容器 (Kind) / VM (Minikube可选)                | VM (VirtualBox)                                          | 容器 (Kind) / VM (Minikube可选)                  |
| **NFS供应类型**       | 静态供应 (手动PV/PVC绑定)                      | 动态供应 (NFS Subdir External Provisioner)               | 直接挂载 (Pod Spec中直接定义NFS)                 |
| **Terraform IaC覆盖** | 集群配置、PV/PVC (NFS服务器手动)               | 集群VMs、Kubeadm、NFS服务器VM、动态供应器、PV/PVC (完全) | 集群配置、Pod (NFS服务器手动)                    |
| **资源占用**          | 低                                             | 高                                                       | 低                                               |
| **设置复杂性**        | 低 (NFS服务器手动部分)                         | 高 (VM编排、远程配置、依赖管理)                          | 低 (NFS服务器手动部分)                           |
| **可移植性**          | 有限 (依赖主机NFS手动配置)                     | 高 (整个环境自包含在VM中)                                | 有限 (依赖主机NFS手动配置)                       |
| **最适合**            | 快速入门、基本概念验证、资源有限               | 深入学习Kubernetes架构、IaC高级实践、生产环境模拟        | 快速功能验证、临时性测试                         |

### 针对不同学习阶段的推荐

- 初学者：

  强烈建议从方案一开始。该方案通过Kind或Minikube提供了一个轻量级的Kubernetes环境，并引入了PV/PVC的基本概念。其设置相对简单，允许学习者专注于理解Kubernetes资源定义和基本交互，而无需被复杂的底层基础设施细节所困扰。这种方法能够帮助学习者快速建立起对Kubernetes的初步认知和操作能力。

- 深入学习型：

  当学习者对Kubernetes基础概念有了一定掌握后，应转向方案二。此方案提供了一个更接近生产环境的多节点Kubeadm集群，并引入了动态存储供应。它不仅涵盖了多节点集群的管理和Kubeadm引导过程，还展示了Terraform在复杂基础设施编排中的强大能力（例如，远程执行脚本、管理依赖关系）。虽然资源消耗较高且部署时间较长，但其提供的实践经验对于理解Kubernetes的内部工作原理和构建生产级环境具有不可估量的价值。将NFS服务器也作为Terraform管理的虚拟机，使得整个环境完全自包含，极大地提高了环境的可移植性，这是生产实践中的重要考量。

- 快速测试型：

  方案三适用于需要进行快速原型验证或临时功能测试的场景。它利用Kind或Minikube的快速启动优势，并直接在Pod中挂载NFS，避免了PV/PVC的抽象层。这种方法在追求极致速度时非常有效，但需要注意的是，它绕过了Kubernetes推荐的存储管理范式，因此不建议用于深入学习或生产环境。它更多地是一种实用性的“捷径”，用于快速验证应用程序与NFS的简单交互。

### 跨平台兼容性与环境可迁移性总结

Terraform的声明式特性和丰富的提供商生态系统，在代码层面实现了高度的跨平台兼容性。这意味着Terraform配置文件本身可以在不同操作系统上运行。然而，对于本地环境，实际的跨平台兼容性和环境可迁移性受到底层虚拟化技术（如VirtualBox、Docker）和操作系统特定命令的影响。

- **代码兼容性**：Terraform配置文件（`.tf`文件）本身是文本文件，可以在任何操作系统上编写和运行，这确保了基础设施定义的“代码可移植性”。

- 运行时兼容性

  ：

  - **Kind/Minikube（方案一和方案三）**：这些工具在Linux、macOS和Windows上均有良好支持，主要依赖于Docker运行时 5。然而，NFS服务器的手动配置部分仍然是操作系统特定的，例如Linux上的`apt`命令和`/etc/exports`文件路径 28。这限制了环境的整体可移植性，因为将环境迁移到不同操作系统时，NFS服务器的设置需要重新手动执行。
  - **Kubeadm on VirtualBox（方案二）**：此方案通过Terraform完全管理VirtualBox虚拟机，并在虚拟机内部执行Linux shell脚本来配置Kubernetes和NFS服务。由于整个环境（包括NFS服务器）都被封装在VirtualBox虚拟机中，并且这些虚拟机本身是可移植的，因此该方案实现了**最高的环境可迁移性**。Terraform的`remote-exec` provisioner允许在远程VM上执行脚本，从而抽象了大部分操作系统级配置，使得整个环境可以在任何支持VirtualBox的主机上重建 11。这种设计最大限度地减少了对主机操作系统手动配置的依赖。

总而言之，虽然Terraform文件本身高度可移植，但要实现本地学习环境的真正“环境可迁移性”，需要将所有依赖项（包括存储）都封装在Terraform管理的虚拟化组件中，如方案二所示。这能够确保环境在不同机器或操作系统之间迁移时，能够以最小的额外工作量进行重建。

## VIII. 版本控制与环境迁移最佳实践

在基础设施即代码（IaC）实践中，版本控制不仅仅是代码存储，更是环境管理、协作和安全的关键组成部分。

### Terraform状态文件管理

Terraform通过状态文件（`.tfstate`）来记录其管理的基础设施的实际状态 2。这个文件是Terraform能够进行增量部署和销毁的基础。然而，状态文件通常包含敏感信息（如密码、API密钥、私钥），并且会频繁更新 87。

**最佳实践：**

- 避免提交到Git

  ：Terraform状态文件

  绝不应

  提交到Git版本控制系统 

  87

  。主要原因有二：

  

  - **安全风险**：状态文件可能包含未加密的敏感数据，将其提交到公共或不安全的Git仓库会造成严重的安全漏洞 87。
  - **合并冲突**：状态文件会随着每次`terraform apply`操作而更新，这在团队协作环境中极易导致频繁的合并冲突，且冲突解决过程复杂 87。

- 使用远程后端

  ：对于任何非一次性、单机使用的Terraform项目，都应配置远程后端来存储状态文件 

  87

  。远程后端提供了以下关键优势：

  

  - **版本历史**：大多数远程后端都支持状态文件的版本控制，可以轻松回溯到先前的状态 87。
  - **状态锁定**：远程后端能够实现状态锁定，防止多个用户同时修改基础设施，从而避免竞态条件和状态不一致 87。
  - **加密**：远程后端通常支持对存储在其中的状态文件进行静态加密，增强数据安全性 87。
  - **协作**：支持团队成员共享和管理Terraform状态，促进协同工作 89。
  - **备份**：许多远程后端提供自动备份功能，防止状态文件丢失或损坏 87。

- **加密与安全传输**：即使使用远程后端，也应确保状态文件在传输过程中使用HTTPS等加密协议，并对静态存储进行加密 87。

- **定期维护**：定期使用`terraform state`命令对状态文件进行清理和重构，保持其准确性 87。

### 敏感信息处理：Kubeconfig

`kubeconfig`文件包含了连接和认证Kubernetes集群所需的凭据，例如API服务器地址、客户端证书、密钥和CA证书 32。这些凭据通常授予用户对集群的超级用户权限 15。

**最佳实践：**

- **避免提交到Git**：与Terraform状态文件类似，`kubeconfig`文件**绝不应**提交到源代码管理中 82。其泄露可能导致未经授权的集群访问，造成严重的安全风险。

- 安全处理

  ：

  - **环境变量**：Kubernetes提供商可以从环境变量（如`KUBE_CONFIG_PATH`）中读取`kubeconfig`路径，避免将敏感路径硬编码到Terraform配置中 32。
  - **安全存储**：在生产环境中，应将`kubeconfig`等敏感信息存储在专门的密钥管理系统（如HashiCorp Vault、云服务商的密钥管理服务）中，并在运行时动态获取 88。
  - **本地文件权限**：在本地环境中，确保`~/.kube/config`文件具有严格的访问权限（例如`chmod 600`），只允许所有者读写。
  - **远程提取**：当需要从远程VM中提取`kubeconfig`时，应使用安全的传输协议（如SSH），并确保文件在传输后立即保存到本地受保护的位置 11。

### Git分支策略与工作流

将基础设施视为代码，意味着应采用与应用程序开发相同的版本控制和协作工作流。

**最佳实践：**

- **标准分支策略**：遵循业界标准的Git分支策略，例如使用`main`分支作为主开发分支（受保护），并从其派生功能分支和错误修复分支 88。完成开发后，通过Pull Request（PR）合并回`main`分支。
- **环境分支**：对于部署到不同环境（如开发、测试、生产）的根配置，可以考虑为每个环境设置独立的分支 88。这种策略允许通过在不同环境分支之间合并更改来提升基础设施的变更，确保受控的发布流程。即使是本地学习环境，采用这种模式也能培养良好的IaC实践习惯。
- **广泛可见性**：鼓励在工程组织内部广泛共享和可见Terraform源代码和仓库 88。这有助于基础设施利益相关者更好地理解其所依赖的基础设施，并鼓励他们通过合并请求参与变更过程。
- **CI/CD集成**：将Terraform集成到持续集成/持续部署（CI/CD）管道中 2。这能够自动化基础设施的部署、更新和销毁，确保所有更改都以一致且可审计的方式应用，减少手动错误。CI/CD流程还能在每次代码提交时自动执行`terraform plan`和`terraform apply`，从而实现基础设施的持续交付。

## IX. 注意事项与常见问题排查

在本地学习环境中部署Kubernetes集群和NFS存储，可能会遇到一些常见问题。本节将提供详细的排查指南。

### NFS权限与连接问题

NFS（网络文件系统）在配置不当时，常常会出现权限和连接问题。

- **“Permission denied”（权限被拒绝）**：

  - **检查`/etc/exports`文件**：确保NFS服务器上的`/etc/exports`文件正确配置了共享目录，并为客户端IP（即Kubernetes节点IP）授予了正确的访问权限（例如`rw`代表读写） 39。如果客户端仅有读取权限，则挂载时必须使用`ro`选项。
  - **重新导出共享**：在修改`/etc/exports`后，务必在NFS服务器上运行`sudo exportfs -ar`命令，以确保更改被NFS服务重新读取并应用 39。
  - **验证导出状态**：检查`/proc/fs/nfs/exports`文件（或`/var/lib/nfs/xtab`）以确认共享卷和客户端是否正确列出 39。
  - **服务器识别客户端**：确保NFS服务器正确识别客户端机器的名称或IP地址。有时，`/etc/hosts`中的旧条目或客户端地址不完整可能导致问题。可以尝试从客户端SSH或Telnet到服务器，然后输入`who`命令，查看服务器如何识别客户端，并使用该名称更新`/etc/exports`条目 39。
  - **用户/组ID同步**：如果非root用户遇到权限问题，请在客户端和服务器上运行`id [user]`命令，确保它们具有相同的UID和GID 39。如果不同步，可能是NIS、NIS+或其他用户同步系统的问题。
  - **`no_root_squash`选项**：对于Kubernetes Pod，如果需要以root用户身份在NFS共享上进行写入操作，通常需要在`/etc/exports`中添加`no_root_squash`选项。默认情况下，NFS会“压缩”远程root用户的权限到`nobody`用户，以增强安全性 39。
  - **`rsize`/`wsize`问题**：如果大文件传输导致挂载点卡死，可能是`rsize`和`wsize`挂载选项设置过大，尝试将其减小到1024 39。

- **RPC错误（如“Program Not Registered”）**：

  - **检查NFS服务运行状态**：在NFS服务器上运行`rpcinfo -p`命令，确认`portmapper`、`nfs`和`mountd`服务正在运行 39。
  - **客户端可见性**：从客户端运行`rpcinfo -p <server_ip>`，检查NFS服务是否可从客户端访问。
  - **防火墙**：如果可以ping通服务器但无法进行RPC通信，很可能是防火墙阻止了NFS端口（通常是2049）的流量。检查服务器或任何中间路由器的防火墙规则 39。

- 内核问题：

  某些Linux内核版本可能存在NFS客户端或服务器的已知问题，可能导致NFS响应失败或延迟。建议使用经过验证的稳定内核版本 92。

### PV/PVC绑定问题

持久卷（PV）和持久卷声明（PVC）的绑定问题是Kubernetes中常见的存储故障。通常表现为PVC长时间处于`Pending`状态。

下表列出了常见的PV/PVC问题排查步骤：

| **问题/症状**            | **排查命令**                                                 | **预期输出/检查点**                                          | **潜在原因**                                                 | **解决方案/操作**                                            |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **PVC处于Pending状态**   | `kubectl get pvc`                                            | PVC状态为`Pending`                                           | 没有匹配的PV，或PV已被占用；容量/访问模式不匹配；StorageClass问题；动态供应失败；节点限制 | 检查PV/PVC/StorageClass配置；检查供应器日志；检查节点状态；手动创建PV；删除并重建PVC |
|                          | `kubectl describe pvc <pvc-name>`                            | “Events”部分是否有错误或警告信息                             |                                                              |                                                              |
| **无匹配PV**             | `kubectl get pv`                                             | 没有可用的PV，或现有PV不符合PVC要求                          | PV容量不足；访问模式不兼容；StorageClass不匹配；PV已被其他PVC绑定 | 创建新的PV；调整PV/PVC容量或访问模式；检查StorageClass配置   |
| **StorageClass配置错误** | `kubectl get storageclass`                                   | StorageClass名称不正确或不存在                               | StorageClass名称拼写错误；StorageClass未创建或未设置为默认   | 修正PVC中的`storageClassName`；创建或修正StorageClass        |
|                          | `kubectl describe storageclass <name>`                       | 检查参数、供应器、回收策略等配置是否正确                     |                                                              |                                                              |
| **动态供应失败**         | `kubectl logs -n <provisioner-namespace> <provisioner-pod-name>` | 供应器Pod日志中是否有错误信息（如权限不足、NFS服务器不可达） | 供应器未运行或配置错误；NFS服务器问题；网络问题              | 检查供应器Pod状态；检查NFS服务器连接；检查RBAC权限           |
| **资源容量不足**         | `kubectl get nodes -o json \                                 | jq -r '.items.status.allocatable."ephemeral-storage"'`       | 集群可用存储容量低于PVC请求容量                              | 节点存储空间不足；云提供商存储配额限制                       |
| **节点亲和性/污点**      | `kubectl describe pv <pv-name>`                              | PV的`nodeAffinity`是否限制了调度                             | PV配置了节点亲和性，但没有匹配的节点可用；节点存在阻止Pod调度的污点 | 调整PV的节点亲和性；为Pod添加容忍度；确保有匹配节点          |
|                          | `kubectl describe nodes`                                     | 检查节点状态、污点和可分配资源                               |                                                              |                                                              |

### 资源限制与性能调优

本地环境的资源限制是影响Kubernetes集群性能的关键因素。

- **Kubernetes资源限制与请求**：
  - 在Kubernetes中，Pod和容器可以定义CPU和内存的“请求”（Requests）和“限制”（Limits） 24。请求是调度器用来决定Pod放置位置的最低保证资源量，而限制则是容器可以使用的最大资源量。
  - **影响**：资源请求过高会导致资源浪费和成本增加，而过低则可能导致应用程序性能下降，甚至因内存不足（OOM）而被杀死 24。CPU是可压缩资源，超限会导致节流；内存是不可压缩资源，超限会导致进程被杀死 24。
  - **优化**：根据实际工作负载需求合理设置请求和限制。
- **Docker Desktop/VirtualBox VM资源分配**：
  - **Docker Desktop**：确保为Docker Desktop分配了足够的CPU和RAM。例如，Kind集群的性能直接受Docker Desktop资源配置的影响 10。
  - **VirtualBox VM**：对于Kubeadm方案，需要根据集群规模和节点角色，为每个虚拟机分配足够的CPU和内存 17。例如，主节点通常需要更多CPU和内存来运行控制平面组件。
- **NFS性能调优**：
  - **`/etc/exports`选项**：`sync`选项（同步写入）会确保数据在返回前写入磁盘，但会降低性能；`async`选项（异步写入）可以提高性能，但有数据丢失风险 41。`no_wdelay`选项可以进一步提高写入性能 41。
  - **内核版本**：某些Linux内核版本可能存在影响NFS性能的问题 92。

理解主机资源、虚拟化层和Kubernetes调度器之间的资源分配关系至关重要。任何一层配置不当都可能导致性能瓶颈或集群不稳定。

## X. 结论

本报告详细探讨了使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的三种解决方案，涵盖了从初学者到深入学习和快速测试的不同需求。

**方案一（初学者型）**：利用Kind或Minikube的轻量级和快速部署特性，结合手动配置的主机NFS静态存储，为Kubernetes入门和持久化存储基础概念的学习提供了便捷途径。其优点在于部署速度快、资源占用低，但NFS服务器的手动配置限制了其整体可移植性，且不完全符合“所有配置代码化”的要求。

**方案二（深入学习型）**：通过Terraform全面编排VirtualBox虚拟机、Kubeadm集群部署和动态NFS存储，构建了一个高度接近生产环境的多节点Kubernetes学习平台。该方案的优势在于提供了生产级环境模拟、实现了虚拟机基础设施的完全IaC、支持动态存储供应，并因整个环境自包含在虚拟机中而具有最高的可移植性。然而，其资源消耗和设置复杂性也相对较高。

**方案三（快速测试型）**：同样基于Kind或Minikube，但通过在Pod中直接挂载NFS，追求极致的部署速度和简洁性。它适用于快速原型验证和临时功能测试，但牺牲了Kubernetes的PV/PVC抽象，不符合其推荐的存储管理范式，且可移植性有限。

**综合推荐**：

- **对于初学者**，建议从**方案一**入手，快速建立对Kubernetes的感性认识。
- **对于希望深入理解Kubernetes架构和IaC高级实践的学习者**，**方案二**是最佳选择，尽管它对主机资源和学习投入要求更高。
- **对于需要快速验证特定NFS集成功能的开发者**，**方案三**提供了一个高效的临时解决方案。

**跨平台兼容性与环境可迁移性**是本次任务的核心要求。Terraform的声明式特性确保了配置代码的跨平台兼容性。然而，本地环境的实际可迁移性取决于底层虚拟化和NFS服务器的部署方式。方案二通过将NFS服务器也部署在Terraform管理的虚拟机中，实现了整个环境的自包含，从而提供了最高的环境可迁移性。

最后，无论选择哪种方案，都应遵循**基础设施即代码的最佳实践**。这意味着Terraform状态文件和`kubeconfig`等敏感信息**绝不应**提交到Git版本控制系统，而应使用远程后端进行安全存储和管理。同时，采纳标准的Git分支策略和CI/CD集成，能够确保基础设施变更的自动化、一致性和可审计性，即使在学习环境中，也能培养出专业的DevOps实践习惯。

## XI. 参考文档

- 2 https://backup.education/showthread.php?tid=3152
- 3 https://www.reddit.com/r/Terraform/comments/1aurfpy/terraform_with_virtual_box_provider/
- 1 https://reliasoftware.com/blog/provisioning-a-docker-container-with-terraform
- 94 https://developer.hashicorp.com/terraform/tutorials/docker-get-started/docker-build
- 32 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- 95 https://github.com/hashicorp/terraform-provider-kubernetes
- 33 https://github.com/scott-the-programmer/terraform-provider-minikube/blob/main/README.md
- 34 https://registry.terraform.io/providers/scott-the-programmer/minikube/0.0.3/docs
- 4 https://geraldonit.com/2018/03/26/deploying-a-kubernetes-cluster-with-vagrant-on-virtual-box/
- 23 https://devopscube.com/setup-kubernetes-cluster-kubeadm/
- 5 https://k8sbydijvivek.hashnode.dev/kind-vs-minikube-a-comprehensive-guide-to-choosing-and-setting-up-your-local-kubernetes-cluster
- 25 https://betterstack.com/community/guides/scaling-docker/minikube-vs-kubernetes/
- 28 https://kubedemy.io/kubernetes-storage-part-1-nfs-complete-tutorial
- 29 https://creodias.docs.cloudferro.com/en/latest/kubernetes/Create-and-access-NFS-server-from-Kubernetes-on-Creodias.html
- 43 https://registry.terraform.io/providers/hashicorp/kubernetes/1.10.0/docs/resources/persistent_volume
- 44 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
- 96 https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
- 97 https://learning.scalr.com/mastering-terraforms-local-exec-provisioner-a-practical-guide/
- 81 https://cvw.cac.cornell.edu/jetstream-terraform/provisioning/remoteexec
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 98 https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
- 7 https://kind.sigs.k8s.io/docs/user/quick-start/
- 33 https://github.com/scott-the-programmer/terraform-provider-minikube/blob/main/README.md
- 35 https://registry.terraform.io/providers/scott-the-programmer/minikube/0.4.1/docs/resources/cluster
- 64 https://kmt1.hashnode.dev/create-and-manage-virtualbox-vms-with-vagrant
- 3 https://www.reddit.com/r/Terraform/comments/1aurfpy/terraform_with_virtual_box_provider/
- 23 https://devopscube.com/setup-kubernetes-cluster-kubeadm/
- 11 https://admantium.com/blog/kube14_kubeadm_with_terraform/
- 89 https://infohub.delltechnologies.com/en-us/p/managing-your-on-premises-infrastructure-with-hashicorp-terraform-part-9/
- 99 https://docs.vscentrum.be/cloud/terraform.html
- 49 https://registry.terraform.io/providers/hashicorp/kubernetes/2.22.0/docs/data-sources/persistent_volume_v1
- 43 https://registry.terraform.io/providers/hashicorp/kubernetes/1.10.0/docs/resources/persistent_volume
- 51 https://registry.terraform.io/providers/hashicorp/kubernetes/2.22.0/docs/resources/pod_v1
- 44 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
- 65 https://www.geeksforgeeks.org/kubernetes-volume-provisioning-dynamic-vs-static/
- 100 https://www.reddit.com/r/kubernetes/comments/1krdnnz/nfs_csi_driver_static_provisioning/
- 30 https://registry.terraform.io/providers/tehcyx/kind/latest/docs/resources/cluster
- 9 https://kubeslice.io/documentation/open-source/0.2.0/getting-started-with-kind-clusters/
- 8 https://minikube.sigs.k8s.io/docs/start/
- 14 https://nerc-project.github.io/nerc-docs/other-tools/kubernetes/minikube/
- 19 https://github.com/ashleykleynhans/vagrant-ansible-k8s
- 101 https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/vagrant
- 39 https://nfs.sourceforge.net/nfs-howto/ar01s07.html
- 55 https://docs.oracle.com/cd/E19455-01/806-0916/6ja8539fs/index.html
- 56 https://www.shoreline.io/runbooks/kubernetes/kubernetes-troubleshooting-persistent-volume-claims
- 57 https://learn.microsoft.com/en-us/answers/questions/1917396/kubernetes-pvc-connection-issue
- 102 https://registry.terraform.io/modules/PePoDev/cluster/kind/latest/examples/multi-node-kubernetes-cluster
- 103 https://registry.terraform.io/modules/terraform-ns1-modules/platform/ns1/latest/examples/multi-node-cluster
- 104 https://blog.techiescamp.com/setting-up-kind-cluster/
- 105 https://kind.sigs.k8s.io/docs/user/configuration/
- 106 https://typeshare.co/jake/posts/easy-way-to-use-terraform-to-update-kubeconfig
- 32 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- 33 https://github.com/scott-the-programmer/terraform-provider-minikube/blob/main/README.md
- 35 https://registry.terraform.io/providers/scott-the-programmer/minikube/0.4.1/docs/resources/cluster
- 64 https://kmt1.hashnode.dev/create-and-manage-virtualbox-vms-with-vagrant
- 62 https://backup.education/showthread.php?tid=3187&action=nextoldest
- 23 https://devopscube.com/setup-kubernetes-cluster-kubeadm/
- 69 https://rushiinfotech.in/install-kubeadm-on-ubuntu-22-04/
- 80 https://developer.hashicorp.com/terraform/language/resources/provisioners/file
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 90 https://developer.hashicorp.com/terraform/language/backend/kubernetes
- 107 https://github.com/poseidon/terraform-onprem-kubernetes/blob/master/ssh.tf
- 81 https://cvw.cac.cornell.edu/jetstream-terraform/provisioning/remoteexec
- 108 https://github.com/hashicorp/terraform/issues/17441
- 48 https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- 50 https://github.com/kubesphere/nfs-pv-static-provisioner
- 66 https://github.com/sculley/terraform-kubernetes-nfs-client-provisioner
- 67 https://artifacthub.io/packages/helm/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
- 9 https://kubeslice.io/documentation/open-source/0.2.0/getting-started-with-kind-clusters/
- 10 https://betterstack.com/community/guides/scaling-docker/kind/
- 8 https://minikube.sigs.k8s.io/docs/start/
- 14 https://nerc-project.github.io/nerc-docs/other-tools/kubernetes/minikube/
- 15 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- 16 https://www.civo.com/academy/kubernetes-setup/configure-multi-node-clusters
- 39 https://nfs.sourceforge.net/nfs-howto/ar01s07.html
- 92 https://www.alibabacloud.com/help/en/nas/known-issues-on-nfs-clients
- 58 https://hackernoon.com/troubleshooting-kubernetes-solving-7-common-issues-and-challenges
- 56 https://www.shoreline.io/runbooks/kubernetes/kubernetes-troubleshooting-persistent-volume-claims
- 88 https://cloud.google.com/docs/terraform/best-practices/version-control
- 91 https://circleci.com/blog/manage-kubernetes-dynamic-config/
- 102 https://registry.terraform.io/modules/PePoDev/cluster/kind/latest/examples/multi-node-kubernetes-cluster
- 31 https://www.reddit.com/r/Terraform/comments/10y3mfo/provisioning_cluster_on_laptop_with_kind_and_helm/
- 7 https://kind.sigs.k8s.io/docs/user/quick-start/
- 32 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- 35 https://registry.terraform.io/providers/scott-the-programmer/minikube/0.4.1/docs/resources/cluster
- 36 https://github.com/scott-the-programmer/terraform-provider-minikube
- 63 https://library.tf/modules/masoudbahar/talos/virtualbox/latest
- 103 https://registry.terraform.io/modules/terraform-ns1-modules/platform/ns1/latest/examples/multi-node-cluster
- 11 https://admantium.com/blog/kube14_kubeadm_with_terraform/
- 23 https://devopscube.com/setup-kubernetes-cluster-kubeadm/
- 78 https://learning.scalr.com/terraform-remote-exec-a-concise-guide/
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 82 https://github.com/harvester/harvester/issues/6234
- 83 https://spacelift.io/blog/terraform-kubernetes-deployment
- 80 https://developer.hashicorp.com/terraform/language/resources/provisioners/file
- 109 https://cvw.cac.cornell.edu/jetstream-terraform/provisioning/fileprovisioner
- 37 https://cloudspinx.com/how-to-configure-nfs-server-on-debian/
- 110 https://yandex.cloud/en/docs/tutorials/archive/single-node-file-server/terraform
- 49 https://registry.terraform.io/providers/hashicorp/kubernetes/2.22.0/docs/data-sources/persistent_volume_v1
- 43 https://registry.terraform.io/providers/hashicorp/kubernetes/1.10.0/docs/resources/persistent_volume
- 52 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/persistent_volume_claim
- 46 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim
- 10 https://betterstack.com/community/guides/scaling-docker/kind/
- 12 https://kind.sigs.k8s.io/
- 26 https://minikube.sigs.k8s.io/docs/faq/
- 27 https://minikube.sigs.k8s.io/docs/drivers/docker/
- 20 https://github.com/kodekloudhub/certified-kubernetes-administrator-course/blob/master/kubeadm-clusters/virtualbox/docs/02-compute-resources.md
- 21 https://github.com/sanwill/kubernetes-on-virtualbox
- 39 https://nfs.sourceforge.net/nfs-howto/ar01s07.html
- 40 https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/nfs-server-file-permissions
- 59 https://www.kubernet.dev/troubleshooting-pvc-pending-error-in-kubernetes-a-complete-guide/
- 60 https://portworx.com/blog/pod-has-unbound-immediate-persistent-volume-claims/
- 90 https://developer.hashicorp.com/terraform/language/backend/kubernetes
- 87 https://dev.to/pat6339/best-practices-for-managing-terraform-state-files-a-complete-guide-400m
- 105 https://kind.sigs.k8s.io/docs/user/configuration/
- 102 https://registry.terraform.io/modules/PePoDev/cluster/kind/latest/examples/multi-node-kubernetes-cluster
- 32 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
- 106 https://typeshare.co/jake/posts/easy-way-to-use-terraform-to-update-kubeconfig
- 35 https://registry.terraform.io/providers/scott-the-programmer/minikube/0.4.1/docs/resources/cluster
- 33 https://github.com/scott-the-programmer/terraform-provider-minikube/blob/main/README.md
- 64 https://kmt1.hashnode.dev/create-and-manage-virtualbox-vms-with-vagrant
- 3 https://www.reddit.com/r/Terraform/comments/1aurfpy/terraform_with_virtual_box_provider/
- 23 https://devopscube.com/setup-kubernetes-cluster-kubeadm/
- 11 https://admantium.com/blog/kube14_kubeadm_with_terraform/
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 71 https://enix.io/en/blog/deploying-kubernetes-1-13-openstack-terraform/
- 78 https://learning.scalr.com/terraform-remote-exec-a-concise-guide/
- 75 https://stackoverflow.com/questions/51126164/how-do-i-find-the-join-command-for-kubeadm-on-the-master
- 84 https://spacelift.io/blog/terraform-provisioners
- 85 https://stackoverflow.com/questions/56474709/how-to-store-terraform-provisioner-local-exec-output-in-local-variable-and-use
- 37 https://cloudspinx.com/how-to-configure-nfs-server-on-debian/
- 38 https://ubuntu.com/server/docs/network-file-system-nfs
- 45 https://www.plural.sh/blog/kubernetes-persistent-volume-guide/
- 43 https://registry.terraform.io/providers/hashicorp/kubernetes/1.10.0/docs/resources/persistent_volume
- 46 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim
- 47 https://arun944.hashnode.dev/kubernetes-persistent-volumes-and-persistent-volume-claim-using-nfs-server-static-provisioning
- 111 https://discuss.kubernetes.io/t/hardware-recommendations-for-kubernetes-cluster/30900
- 24 https://sysdig.com/blog/kubernetes-limits-requests/
- 8 https://minikube.sigs.k8s.io/docs/start/
- 13 https://www.reddit.com/r/kubernetes/comments/nss271/hardware_requirements_for_local_kubernetes/
- 17 https://hostman.com/tutorials/kubernetes-cluster-installation-configuration-and-management/
- 18 https://www.redhat.com/en/blog/start-learning-kubernetes
- 41 https://unix.stackexchange.com/questions/789655/nfs-v4-export-is-adding-additional-options-not-specified-in-etc-exports
- 42 https://serverfault.com/questions/1089557/what-does-the-no-all-squash-option-do-in-nfs-exports
- 59 https://www.kubernet.dev/troubleshooting-pvc-pending-error-in-kubernetes-a-complete-guide/
- 61 https://www.kubernet.dev/fixing-kubernetes-pvc-pending-status-a-comprehensive-troubleshooting-guide/
- 90 https://developer.hashicorp.com/terraform/language/backend/kubernetes
- 112 https://spacelift.io/blog/argocd-terraform
- 33 https://github.com/scott-the-programmer/terraform-provider-minikube/blob/main/README.md
- 44 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
- 30 https://registry.terraform.io/providers/tehcyx/kind/latest/docs/resources/cluster
- 113 https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster
- 114 https://registry.terraform.io/providers/alouette/virtualbox/latest/docs
- 115 https://kubernetes.io/docs/tasks/tools/install-kubeadm/
- 116 https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
- 48 https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- 7 https://kind.sigs.k8s.io/docs/user/quick-start/
- 8 https://minikube.sigs.k8s.io/docs/start/
- 98 https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 105 https://kind.sigs.k8s.io/docs/user/configuration/
- 86 https://minikube.sigs.k8s.io/docs/drivers/
- 80 https://developer.hashicorp.com/terraform/language/resources/provisioners/file
- 22 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- 15 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- 39 https://nfs.sourceforge.net/nfs-howto/ar01s07.html
- 48 https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- 44 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
- 46 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim
- 105 https://kind.sigs.k8s.io/docs/user/configuration/
- 86 https://minikube.sigs.k8s.io/docs/drivers/
- 80 https://developer.hashicorp.com/terraform/language/resources/provisioners/file
- 98 https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
- 70 https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- 22 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- 15 https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- 39 https://nfs.sourceforge.net/nfs-howto/ar01s07.html
- 48 https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- 44 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
- 46 https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim
- 117 https://www.virtualbox.org/manual/ch06.html
- 118 https://www.virtualbox.org/manual/ch08.html
- 119 https://www.virtualbox.org/manual/ch09.html
- 120 https://www.virtualbox.org/wiki/Downloads
- 121 https://www.vagrantup.com/docs/installation
- 122 https://www.vagrantup.com/docs/providers/virtualbox/configuration
- 123 https://www.vagrantup.com/docs/provisioning
- 93 https://docs.docker.com/desktop/
- 6 https://docs.docker.com/engine/install/
- 7 https://kind.sigs.k8s.io/docs/user/quick-start/
- 8 https://minikube.sigs.k8s.io/docs/start/
- 124 https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/high-availability/
- 79 https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/
- 