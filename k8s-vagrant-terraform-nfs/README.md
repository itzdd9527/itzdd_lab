以下是为你量身设计的“**中级实战阶段 GitHub 代码仓库结构图**”，用于使用 **Terraform + Vagrant + VMware Workstation Pro / VirtualBox** 搭建**多节点 Kubernetes 学习集群**，并通过一台节点部署 NFS Server，支持 PVC 持久化挂载。

该方案适合深入理解 K8s 组件部署、多节点调度、NFS 存储绑定等中实战技能，架构清晰、可复用性强。

---

## 📁 GitHub 项目结构图：`k8s-vagrant-terraform-nfs`

```
k8s-vagrant-terraform-nfs/
├── terraform/                              # Terraform 管理虚拟机生命周期
│   ├── main.tf                             # 使用 null_resource 或 vagrant-exec 创建虚拟机
│   ├── variables.tf                        # 虚拟机参数配置（数量、内存等）
│   ├── outputs.tf                          # 输出 SSH 信息、kubeconfig 等
│   └── provision.sh                        # 虚拟机初始化脚本入口（触发 kubeadm、NFS 安装）
│
├── vagrant/                                # Vagrant 多节点虚拟机配置
│   ├── Vagrantfile                         # 支持多节点（如 1 Master + 2 Node）
│   └── scripts/
│       ├── install_k8s.sh                  # 在每个节点上安装 Kubernetes 组件
│       ├── setup_nfs_server.sh            # 安装并配置 NFS 服务（在其中一个节点）
│       ├── init_master.sh                 # Master 节点 kubeadm init + 网络插件
│       └── join_node.sh                   # Node 节点加入集群
│
├── manifests/                              # Kubernetes 存储和测试资源清单
│   ├── nfs-pv.yaml                         # 使用 NFS 的 PV
│   ├── nfs-pvc.yaml                        # PVC 绑定测试
│   └── test-pod.yaml                       # 挂载 PVC 的测试 Pod
│
├── scripts/                                # 辅助脚本
│   ├── apply_all.sh                        # 一键部署：Terraform + K8s Init + PV/PVC
│   └── destroy_all.sh                      # 一键销毁环境
│
├── .gitignore                              # 忽略中间文件
├── README.md                               # 安装说明、平台支持、部署流程
└── LICENSE
```

---

## 🧱 节点示例架构（默认）

* `k8s-master-1`: Kubernetes Control Plane + NFS Server
* `k8s-node-1`, `k8s-node-2`: Worker 节点（通过 kubeadm join 加入集群）

> 所有节点通过 Vagrant 创建，并用 VirtualBox/VMware Workstation 启动
> 所有安装步骤通过 `provision.sh` 和子脚本执行（自动 ssh、安装依赖、加入集群）

---

## ⚙️ 技术栈组件

| 技术                                      | 用途                            |
| --------------------------------------- | ----------------------------- |
| **Terraform**                           | 管理虚拟机生命周期、调用 Vagrant          |
| **Vagrant**                             | 创建可控虚拟机（VMware/VirtualBox 驱动） |
| **VirtualBox / VMware Workstation Pro** | 虚拟化运行环境                       |
| **Kubeadm**                             | 快速初始化多节点 Kubernetes 集群        |
| **NFS Server**                          | 配置共享存储，支持 PVC                 |
| **Shell 脚本**                            | 自动化安装 kubelet、kubeadm、NFS 等   |

---

## 🚀 运行步骤简述

```bash
# 1. 初始化 Terraform
cd terraform
terraform init
terraform apply

# 2. Terraform 触发 Vagrant 创建虚拟机 & 远程执行安装脚本
# master 节点执行 kubeadm init
# node 节点自动 join
# node-1 上配置 NFS 共享

# 3. 登录 master，部署 PV/PVC 测试
cd ../manifests
kubectl apply -f nfs-pv.yaml
kubectl apply -f nfs-pvc.yaml
kubectl apply -f test-pod.yaml

# 4. 查看挂载效果
kubectl exec -it test-pod -- sh
df -h
```

---

## ✅ 特点与优势

| 项目设计        | 优势               |
| ----------- | ---------------- |
| 多节点结构       | 模拟调度、服务部署、Pod 网络 |
| 自带 NFS      | 实践共享存储挂载 PVC     |
| 全脚本化部署      | 避免手动安装，易于重建      |
| 可扩展         | 修改变量即可变更节点数量、资源  |
| 支持 Git 版本控制 | 跨电脑复现环境一致性高      |

---

## 🧩 可选扩展方向

* 使用 Packer 构建基础镜像（带 Docker/K8s）
* 改用 `remote-exec` 实现远程部署更细粒度控制
* 加入 Helm / Ingress / Prometheus 等学习模块
* 加入 GitHub Actions 验证 `kubeadm init` 成功并测试 NFS PVC 可读写

---

如果你需要：

* ✅ 生成这套目录结构 + 所有核心文件
* ✅ 帮你补全 `main.tf` / `Vagrantfile` / `provision.sh` 内容
* ✅ 创建 GitHub 示例仓库或打包成 zip 下载

请告诉我，我可以立即生成并交付你可以直接用的工程模板。是否现在开始？你打算用 **VirtualBox** 还是 **VMware Workstation Pro** 进行虚拟机创建？
