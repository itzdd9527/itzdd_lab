以下是为你整理的**初学者版本** GitHub 项目结构图，用于通过 **Kind + NFS + PVC + Terraform** 构建本地 Kubernetes 学习环境。该结构设计易于上手，**支持跨平台、易维护、支持版本控制（Git）**，并可作为后续中高级阶段扩展的基础。

---

## 📁 GitHub 项目结构图：`k8s-kind-nfs-terraform`

```
k8s-kind-nfs-terraform/
├── terraform/                            # Terraform 管理入口
│   ├── main.tf                           # 调用 Kind 创建集群 & 配置 PV/PVC
│   ├── variables.tf                      # 变量定义
│   ├── outputs.tf                        # 输出 kubeconfig 等信息
│   ├── kind-cluster.yaml                 # Kind 集群拓扑定义（多节点支持）
│   └── nfs-deploy.yaml                   # NFS Server 部署 YAML（用于 init 容器）
│
├── manifests/                            # Kubernetes 资源清单
│   ├── nfs-pv.yaml                       # NFS 类型 Persistent Volume
│   ├── nfs-pvc.yaml                      # Persistent Volume Claim
│   └── test-pod.yaml                     # 挂载 PVC 的测试 Pod
│
├── scripts/                              # 本地辅助脚本
│   ├── install_nfs_server.sh             # 在 Docker 宿主机上安装 NFS（可选）
│   ├── kind-cleanup.sh                   # 清理 Kind 集群脚本
│   └── apply_all.sh                      # 一键部署：Terraform + kubectl apply
│
├── .gitignore                            # 忽略 terraform.tfstate 等临时文件
├── README.md                             # 使用说明和部署步骤
└── LICENSE                               # 开源协议
```

---

##  Prerequisites (Windows)

在 Windows 平台上运行此项目，您需要确保已安装并配置好以下工具：

1.  **Terraform**: 用于管理基础设施资源。您可以从 [Terraform 官网](https://www.terraform.io/downloads.html) 下载适用于 Windows 的版本，并将其添加到系统 PATH 环境变量中。
2.  **Docker Desktop for Windows**: Kind (Kubernetes in Docker) 依赖 Docker 环境。请从 [Docker 官网](https://www.docker.com/products/docker-desktop/) 下载并安装 Docker Desktop。安装完成后，请确保 Docker Desktop 正在运行，并且已在设置中启用了 WSL 2 后端（推荐）或 Hyper-V 后端。
3.  **kubectl**: Kubernetes 命令行工具，用于与 Kind 集群进行交互。您可以通过以下几种方式安装：
    *   **通过 Docker Desktop**: Docker Desktop 安装时通常会包含 kubectl。
    *   **独立安装**: 您可以从 [Kubernetes 官方文档](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) 下载适用于 Windows 的 kubectl 二进制文件，并将其添加到系统 PATH 环境变量中。
4.  **Git**: 用于克隆本项目仓库和进行版本控制。您可以从 [Git 官网](https://git-scm.com/download/win) 下载并安装。
5.  **WSL 2 (Windows Subsystem for Linux 2)** (推荐): 虽然 Docker Desktop 可以在 Hyper-V 后端运行，但使用 WSL 2 后端通常能提供更好的性能和兼容性，尤其是在运行 Linux 容器时。如果您的 Windows 版本支持，强烈建议安装并启用 WSL 2，并将 Docker Desktop 配置为使用 WSL 2 后端。
    *   您可以参考 [微软官方文档](https://docs.microsoft.com/en-us/windows/wsl/install) 进行 WSL 2 的安装和配置。
6.  **NFS 服务 (针对 NFS on Host 方案)**: 如果您计划在 Windows 主机上直接运行 NFS 服务来提供存储（而不是在 Kind 集群内部署 NFS 服务容器），您可能需要配置 Windows 的 NFS 服务功能，或者使用第三方 NFS 服务器软件。对于初学者，更推荐在 Kind 集群内部署 NFS 服务容器，或者在 WSL 2 环境中配置 NFS 服务，这样可以简化 Windows 平台的配置复杂性。
    *   **注意**: 在 Windows 上直接配置 NFS 服务可能比在 Linux/macOS 上更复杂。项目中的 `scripts/install_nfs_server.sh` 脚本是为 Linux 环境设计的。对于 Windows，如果选择在 Kind 内部署 NFS 容器（如 `nfs-deploy.yaml` 所示），则无需在主机上单独安装 NFS 服务。

请确保在运行项目的 `apply_all.sh` 脚本或 Terraform 命令之前，这些工具都已正确安装和配置。

---

## 🌐 项目功能说明

| 目录 / 文件                         | 说明                                                      |
| ------------------------------- | ------------------------------------------------------- |
| `terraform/main.tf`             | 使用 `null_resource + local-exec` 创建 Kind 集群、部署 NFS 和 PVC |
| `terraform/kind-cluster.yaml`   | 定义 1 控制节点 + 1 或 2 Worker 节点                             |
| `manifests/nfs-pv.yaml`         | 配置使用 NFS 的静态 PV（路径指向宿主机或 NFS Pod）                       |
| `scripts/install_nfs_server.sh` | 安装 NFS Server 到宿主机或容器中（推荐 Linux/macOS）                  |
| `scripts/apply_all.sh`          | 一键执行 Terraform 和资源清单部署                                  |
| `README.md`                     | 引导用户部署环境，说明平台支持、脚本使用方法等                                 |

---

## ✅ 初学者友好设计点

* Kind 原生支持 + Terraform 接管基础生命周期
* NFS Server 可选部署在宿主机或容器中（Linux/macOS 推荐宿主机）
* 全过程 Terraform + YAML + 脚本化，保持最简组合
* 跨平台支持（Terraform + Docker Desktop 可在 Windows/macOS/Linux 使用）
* 集群清理脚本一键销毁，便于反复试验

---

## 🚀 使用示例（命令流程）

```bash
# 1. 初始化并部署 Terraform（创建 Kind 集群 + NFS 容器）
cd terraform
terraform init
terraform apply

# 2. 部署 PV、PVC、测试 Pod
cd ../manifests
kubectl apply -f nfs-pv.yaml
kubectl apply -f nfs-pvc.yaml
kubectl apply -f test-pod.yaml

# 3. 查看测试效果
kubectl get pods
kubectl exec -it test-pod -- sh
```

---

$env:KUBECONFIG="d:\itzdd-lab\k8s-kind-nfs-terraform\terraform\~\.kube\config"

kubectl get nodes
kubectl get pods --all-namespaces
kubectl get pods -l app=nfs-server


## 📦 后续可扩展内容

* 增加 Helm 支持或 NFS 动态 Provisioner（如 `nfs-subdir-external-provisioner`）
* 扩展为多节点结构（修改 `kind-cluster.yaml`）
* 接入 CI（如 GitHub Actions）自动测试 YAML 格式 / Terraform Validate

---

如你需要，我可以为你生成这个项目完整代码，并打包为 `.zip` 或推送到 GitHub 示例仓库（你可以私有化），也可以按你指定结构调整内容。

是否需要我下一步帮你生成完整 `main.tf` + `kind-cluster.yaml` + `nfs-pv.yaml` 示例代码？




          
# 安装 k8s-kind-nfs-terraform 实验所需软件

根据您提供的 `winget search` 结果和 <mcfile name="Install-K8sLabTools.ps1" path="d:\iac-lab\k8s-kind-nfs-terraform\Install-K8sLabTools.ps1"></mcfile> 脚本，以下是安装必要软件的步骤：

## 前提条件

确保您已安装 winget-cli（Windows 程序包管理器）。如果尚未安装，您可以：
- 从 Microsoft Store 安装"应用安装程序"(App Installer)
- 或访问 https://aka.ms/getwinget 获取更多信息

## 安装必要软件

### 1. 安装 Terraform

```powershell
winget install --id Hashicorp.Terraform --source winget -e --accept-package-agreements --accept-source-agreements
```

### 2. 安装 Packer

```powershell
winget install --id Hashicorp.Packer --source winget -e --accept-package-agreements --accept-source-agreements
```

### 3. 安装 Vagrant

```powershell
winget install --id Hashicorp.Vagrant --source winget -e --accept-package-agreements --accept-source-agreements
```

### 4. 安装 Git

```powershell
winget install --id Git.Git --source winget -e --accept-package-agreements --accept-source-agreements
```

### 5. 安装 kubectl

```powershell
winget install --id Kubernetes.kubectl -e --accept-package-agreements --accept-source-agreements
```

### 6. 安装 Docker Desktop

Docker Desktop 需要从官方网站下载安装：
1. 访问 https://www.docker.com/products/docker-desktop/
2. 下载并安装 Docker Desktop for Windows
3. 安装过程中，确保选择启用 WSL 2 后端（如果您的系统支持并已安装 WSL 2），或者 Hyper-V 后端

## 启用 WSL 2（推荐） https://learn.microsoft.com/en-us/windows/wsl/install
## https://learn.microsoft.com/zh-cn/windows/wsl/install 如何使用 WSL 在 Windows 上安装 Linux

以管理员身份运行 PowerShell，执行以下命令：

```powershell
# 启用 Windows Subsystem for Linux 功能
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

# 启用 Virtual Machine Platform 功能
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
```

重启计算机后，执行：

```powershell
# 将 WSL 默认版本设置为 2
wsl --set-default-version 2
```

然后从 Microsoft Store 安装一个 Linux 发行版（例如 Ubuntu）。

## 验证安装

安装完成后，您可以运行以下命令验证各软件是否正确安装：

```powershell
terraform version
packer version
vagrant --version
git --version
kubectl version --client
docker version
```

## 使用脚本自动安装

您也可以直接运行 <mcfile name="Install-K8sLabTools.ps1" path="d:\iac-lab\k8s-kind-nfs-terraform\Install-K8sLabTools.ps1"></mcfile> 脚本来自动安装和检查这些工具。请确保以管理员身份运行此脚本：

```powershell
cd d:\iac-lab\k8s-kind-nfs-terraform
.\Install-K8sLabTools.ps1
```

脚本会检查每个工具是否已安装，如果未安装则尝试使用 winget 安装，或提供手动安装的指导。

## 注意事项

1. 如果通过 winget 安装后某些工具命令不可用，可能需要重启 PowerShell 终端或计算机，或手动将工具的可执行文件路径添加到系统 PATH 环境变量中
2. 对于 Docker Desktop，安装后需要手动启动并确保其正常运行
3. WSL 2 的某些功能更改需要重启计算机才能生效
        当前模型请求量过大，请求排队约 1 位，请稍候或切换至其他模型问答体验更流畅。


        wsl --list --online
以下是可安装的有效分发的列表。
使用 'wsl.exe --install <Distro>' 安装。

NAME                            FRIENDLY NAME
AlmaLinux-8                     AlmaLinux OS 8
AlmaLinux-9                     AlmaLinux OS 9
AlmaLinux-Kitten-10             AlmaLinux OS Kitten 10
Debian                          Debian GNU/Linux
FedoraLinux-42                  Fedora Linux 42
SUSE-Linux-Enterprise-15-SP5    SUSE Linux Enterprise 15 SP5
SUSE-Linux-Enterprise-15-SP6    SUSE Linux Enterprise 15 SP6
Ubuntu                          Ubuntu
Ubuntu-24.04                    Ubuntu 24.04 LTS
archlinux                       Arch Linux
kali-linux                      Kali Linux Rolling
openSUSE-Tumbleweed             openSUSE Tumbleweed
openSUSE-Leap-15.6              openSUSE Leap 15.6
Ubuntu-18.04                    Ubuntu 18.04 LTS
Ubuntu-20.04                    Ubuntu 20.04 LTS
Ubuntu-22.04                    Ubuntu 22.04 LTS
OracleLinux_7_9                 Oracle Linux 7.9
OracleLinux_8_7                 Oracle Linux 8.7
OracleLinux_9_1                 Oracle Linux 9.1


https://learn.microsoft.com/zh-cn/windows/wsl/install-manual#step-4---download-the-linux-kernel-update-package