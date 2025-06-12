# 📄 产品需求文档（PRD）

## 项目名称：iac-lab — 跨平台学习与测试环境配置同步工具

---

## 一、产品概述

**项目目标**：
构建一个跨平台、本地与云端统一的 IaC 学习与测试环境系统，覆盖 Kubernetes 入门、运维实践、环境配置同步、云端实验支持等，支持通过 GitHub 管理所有配置与部署流程，帮助用户高效学习云原生与 DevOps 技术。

**核心价值**：

* ✅ 所有环境配置和部署脚本可 GitHub 同步
* ✅ 支持 macOS、Windows（含 WSL）、Linux 跨平台部署
* ✅ 支持本地（Kind/Vagrant）与云端（Azure/阿里云）环境一键部署
* ✅ 配置即代码，部署即学习，便于迭代与迁移

---

## 二、目标用户

| 用户类型       | 特征说明                  | 主要诉求               |
| ---------- | --------------------- | ------------------ |
| 初学者        | 正在学习 K8s/IaC          | 快速搭建本地实验环境         |
| DevOps 实践者 | 想练习 Terraform + 自动化部署 | 多节点集群部署、NFS 实践     |
| 教育机构       | 教学 Kubernetes/云原生课程   | 配套统一环境与作业模板        |
| 企业小团队      | 需要一致的本地测试环境           | 一键部署、自助调试、可 Git 管理 |

---

## 三、产品功能模块

| 模块 | 名称                   | 描述                                              |
| -- | -------------------- | ----------------------------------------------- |
| M1 | Kind 单节点环境           | 使用 Terraform + Kind 搭建 Kubernetes 学习集群          |
| M2 | 多节点虚拟机环境             | 使用 Vagrant + VirtualBox/Vmware + Kubeadm 构建集群   |
| M3 | 持久化存储配置              | 使用 NFS 部署 PVC 演练环境                              |
| M4 | 开发配置同步               | 通过 GitHub + chezmoi 管理 .zshrc/.vimrc 等 dotfiles |
| M5 | 云端部署（Azure）          | 使用 Terraform 创建 Azure VM 并部署测试环境                |
| M6 | 云端部署（阿里云）            | 使用 Terraform 部署阿里云轻量应用服务器并配置环境                  |
| M7 | 自动化部署脚本              | 一键执行：`make mac k8s` / `make azure` 等命令部署完整环境    |
| M8 | DevContainer 环境      | 提供远程 VSCode 开发体验（如 Codespaces）                  |
| M9 | GitHub Actions CI/CD | 支持自动部署、格式校验等基本流水线功能                             |

---

## 四、功能路径与结构

```bash
iac-lab/
├── k8s-kind-nfs-terraform/           # M1 + M3
├── k8s-vagrant-terraform-nfs/        # M2 + M3
├── cloud-azure-terraform/            # M5
├── cloud-alicloud-terraform/         # M6
├── scripts/                          # M7
├── .devcontainer/                    # M8
├── .github/workflows/                # M9
├── .tool-versions                    # M4
├── Makefile                          # M7
└── iac-lab/                          # 说明文档和学习模板
```

---

## 五、使用方式与场景举例

### 本地 K8s 实验部署

```bash
make mac k8s
# 执行 Kind + NFS + Pod 测试部署
```

### 本地多节点虚拟集群

```bash
make mac vm
# 使用 Vagrant 启动 Ubuntu VM，Terraform 安装 K8s + NFS
```

### 云端部署（Azure）

```bash
make azure
# 在 Azure 创建虚拟机并自动配置 Kubernetes + NFS
```

### 阿里云部署轻量服务器

```bash
make alicloud
# 创建阿里云轻量 ECS，安装 K3s + NFS + 实验环境
```

---

## 六、任务分拆（建议使用 GitHub Issues、项目管理工具拆分）

### 🧱 架构与结构搭建

* [x] 初始化项目结构与目录划分（已完成）
* [ ] 编写顶层 README 介绍项目功能、结构与使用方式
* [ ] 配置 GitHub `.gitignore`、LICENSE 等基础文件

### 🐳 M1 Kind + NFS

* [ ] 编写 Kind 的 `main.tf`
* [ ] 提供 `kind-config.yaml` 与 `nfs-deploy.yaml`
* [ ] 编写初学者文档与图解部署流程

### 💻 M2 Vagrant 多节点集群

* [ ] Vagrantfile 编写（2 master + 1 node）
* [ ] Terraform 生成 K8s 安装计划
* [ ] Kubeadm 脚本 + NFS 部署脚本完成

### ☁️ M5/M6 云平台 Terraform 脚本

* [ ] Azure 虚拟机 `main.tf` 脚本配置（B1s + Ubuntu）
* [ ] 阿里云轻量服务器配置（选择香港或杭州区域）
* [ ] 云端环境自动执行 shell 脚本安装 K3s + NFS

### 🧪 M7 一键部署入口

* [ ] 编写 `Makefile` 命令入口
* [ ] 提供 `scripts/` 中的 `deploy_xxx.sh` 执行逻辑
* [ ] 编写 `scripts/utils.sh`（检测平台、依赖安装）

### 🧰 M4 开发配置同步

* [ ] 初始化 `.tool-versions` 示例（Node.js, Go, Python）
* [ ] 创建 `chezmoi` 示例配置（.zshrc/.vimrc）

### ⚙️ M8 VSCode DevContainer

* [ ] `devcontainer.json` 中预设 terraform, kubectl, helm 等
* [ ] 提供 Dockerfile 或使用基础镜像（如 `mcr.microsoft.com/devcontainers/base:ubuntu`）

### 🔁 M9 GitHub Actions 自动化

* [ ] 添加 `terraform fmt` 校验流水线
* [ ] 脚本部署预览
* [ ] 计划发布版本打包流程

---

## 七、版本迭代计划

| 版本   | 功能                            | 时间目标    |
| ---- | ----------------------------- | ------- |
| v0.1 | 完成 Kind + NFS 单节点学习环境         | 2025-06 |
| v0.2 | 支持多节点虚拟机环境 + Kubeadm 部署       | 2025-07 |
| v0.3 | 扩展 ArgoCD/Ingress/Grafana 模块  | 2025-08 |
| v0.4 | Azure 云环境部署支持                 | 2025-09 |
| v0.5 | 阿里云轻量服务器部署支持                  | 2025-10 |
| v0.6 | 自动化一键部署、Makefile、DevContainer | 2025-11 |
| v1.0 | 项目开源发布、整理教程                   | 2025-12 |

---

## 八、附录

* 官方参考：

  * [Terraform 官网](https://www.terraform.io/)
  * [Kind 项目](https://kind.sigs.k8s.io/)
  * [Vagrant 官网](https://www.vagrantup.com/)
  * [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
  * [阿里云 Terraform Provider](https://registry.terraform.io/providers/aliyun/alicloud)
* 云平台文档：

  * [Azure 免费账户](https://azure.microsoft.com/zh-cn/free/)
  * [阿里云轻量服务器产品说明](https://www.aliyun.com/product/swas)
