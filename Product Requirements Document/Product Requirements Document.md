
# 📄 产品需求文档（PRD)

## 项目名称：跨平台学习与测试环境配置同步工具

> 通过 Terraform + Vagrant + Kind 快速搭建本地与云端 Kubernetes 学习环境，支持配置同步与代码化管理

---

## 一、产品概述

**产品目标**：
为学习 Kubernetes、云原生与基础设施即代码（IaC）相关知识的用户，提供一个跨平台、自动化、配置可复用的本地+云端实验环境解决方案，降低环境搭建门槛，加快学习与测试效率。

**核心价值**：

* 一键部署 Kubernetes 本地环境
* 所有配置通过 GitHub 管理与同步
* 跨平台支持（macOS、Linux、Windows/WSL）
* 云端环境支持（Azure 虚拟机、阿里云轻量应用服务器）
* 逐步拓展实验模块，适应初学到中高级阶段学习

---

## 二、目标用户

| 用户类型       | 典型特征                   | 主要诉求                     |
| ---------- | ---------------------- | ------------------------ |
| 学生 / 自学者   | 学习 Kubernetes 与 IaC 初期 | 快速搭建本地实验环境，避免环境问题影响学习    |
| DevOps 工程师 | 渐进式掌握工具链与自动化           | 在本地与云上部署测试环境，练习配置一致性     |
| 教育机构       | 提供课程实验平台               | 环境一致、部署简单、可统一交付          |
| 内部研发团队     | 小规模集成与测试               | 使用 IaC 管理测试环境，支持多人协作共享配置 |

---

## 三、产品目标与愿景

| 目标               | 描述                                                              |
| ---------------- | --------------------------------------------------------------- |
| ✅ 本地环境即代码（IaC）管理 | 使用 Terraform + Vagrant/Kind 管理所有基础设施资源                          |
| ✅ 配置文件统一化        | 使用 GitHub 管理 `.tf`, `.yaml`, `.sh`, `.bashrc`, `.vimrc` 等环境配置文件 |
| ✅ 多平台兼容          | 无论在 macOS、Linux 还是 Windows/WSL，均可统一部署流程                         |
| ✅ 实验模块可扩展        | 支持从单节点 K8s 到多节点集群、云平台对接、CI/CD 等进阶实践                             |
| ✅ 云平台快速创建测试机     | 支持 Azure、阿里云等公有云平台创建虚拟测试主机，构建混合学习环境                             |

---

## 四、用户故事与典型场景

### 🎓 学习者（初级）

> “我在学习 Kubernetes，希望快速搭建一个单节点环境进行实战测试，并通过 GitHub 管理我的配置。”

### 🧪 实践者（中级）

> “我已经熟悉 K8s 部署流程，想要模拟生产环境，构建多节点 VM 集群、部署 NFS，并测试 ArgoCD、Prometheus 等组件。”

### ☁️ 云平台用户（进阶）

> “我希望将本地环境迁移到云端测试，最好能一键用 Terraform 创建一台 Azure VM 或阿里云轻量服务器，并部署好环境。”

---

## 五、功能模块

| 模块编号 | 模块名称          | 描述                                                               |
| ---- | ------------- | ---------------------------------------------------------------- |
| M1   | 本地 Kind 单节点环境 | 使用 Docker + Kind 快速部署单节点 Kubernetes 实验集群，配置 PVC（NFS）             |
| M2   | 多节点虚拟机环境      | 使用 Vagrant + VirtualBox 创建 VM 集群，通过 Kubeadm + Terraform 自动化部署    |
| M3   | 环境配置同步        | 使用 GitHub + chezmoi / devbox / .tool-versions 管理开发工具与 shell 环境配置 |
| M4   | 扩展应用实验模块      | 集成 ArgoCD、Prometheus、Nginx Ingress、Kubernetes Dashboard 等组件      |
| M5   | 云端部署模块（Azure） | 使用 Terraform 创建 Azure Ubuntu 虚拟机，自动安装 K8s/NFS/测试环境               |
| M6   | 云端部署模块（阿里云）   | 使用 Terraform 创建阿里云轻量应用服务器，部署轻量级实验环境（如 K3s）                       |
| M7   | 项目结构标准化与文档    | 标准 GitHub 仓库结构、脚本模板、自动化部署文档、教学模板支持                               |

---

## 六、技术选型

| 类别     | 技术                            | 理由                             |
| ------ | ----------------------------- | ------------------------------ |
| 基础设施管理 | Terraform                     | 最主流的 IaC 工具，支持多云（本地/阿里云/Azure） |
| 虚拟化平台  | Vagrant + VirtualBox / VMware | 快速创建多节点 VM，跨平台可用               |
| 容器集群管理 | Kind + Kubeadm                | 快速入门 Kubernetes 并支持进阶部署        |
| 持久化存储  | NFS                           | 模拟真实场景中的 PVC 使用                |
| 配置同步工具 | GitHub + chezmoi              | 管理 dotfiles 和环境配置，跨平台一致        |
| 云平台    | Azure / 阿里云                   | 支持使用 Terraform API 部署实验虚拟机     |

---

## 七、平台兼容性

| 功能模块            | macOS | Windows（含 WSL） | Linux | Azure | 阿里云 |
| --------------- | ----- | -------------- | ----- | ----- | --- |
| Terraform 部署    | ✅     | ✅              | ✅     | ✅     | ✅   |
| Kind 部署         | ✅     | ✅              | ✅     | ❌     | ❌   |
| Vagrant 虚拟机     | ✅     | ✅              | ✅     | ❌     | ❌   |
| 云虚拟机（Terraform） | -     | -              | -     | ✅     | ✅   |
| 环境配置同步          | ✅     | ✅              | ✅     | -     | -   |

---

## 八、目录结构建议

```bash
iac-lab/
├── README.md
├── iac-lab/                          # IaC 学习文档与模板
│   ├── 提问模板.md
│   ├── Kubernetes + NFS 报告.md
│   └── 推荐方案说明.md
├── k8s-kind-nfs-terraform/          # 初学者实验项目
│   ├── terraform/
│   ├── kind-config.yaml
│   ├── nfs-deploy.yaml
│   └── README.md
├── k8s-vagrant-terraform-nfs/       # 多节点实战项目
│   ├── Vagrantfile
│   ├── terraform/
│   ├── scripts/
│   └── README.md
├── cloud-azure-terraform/           # Azure 云端虚拟机项目
│   ├── main.tf
│   ├── cloud-init.sh
│   └── README.md
├── cloud-alicloud-terraform/        # 阿里云轻量服务器项目
│   ├── main.tf
│   ├── install.sh
│   └── README.md
├── .devcontainer/                   # VSCode 远程开发支持
├── .github/workflows/               # GitHub Actions 自动化
├── .tool-versions                   # 多语言版本控制（ASDF）
└── Makefile                         # 快速部署脚本入口
```

---

## 九、开发计划与版本迭代

| 时间      | 版本   | 功能点                                   |
| ------- | ---- | ------------------------------------- |
| 2025-06 | v0.1 | Kind + Terraform + NFS 本地单节点环境        |
| 2025-07 | v0.2 | Vagrant 多节点部署集群环境                     |
| 2025-08 | v0.3 | 扩展 ArgoCD / Prometheus / Dashboard 模块 |
| 2025-09 | v0.4 | 环境配置同步、.tool-versions 管理、本地 dotfiles  |
| 2025-10 | v0.5 | Azure 虚拟机部署 + 安装环境脚本                  |
| 2025-11 | v0.6 | 阿里云轻量服务器部署 + 实验集群                     |
| 2025-12 | v1.0 | 文档完善、结构优化、开源发布                        |

---

## 十、参考资源与工具

* [Terraform 官网](https://www.terraform.io/)
* [Kind 项目](https://kind.sigs.k8s.io/)
* [Vagrant 官方文档](https://developer.hashicorp.com/vagrant)
* [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
* [阿里云 Terraform Provider](https://registry.terraform.io/providers/aliyun/alicloud/latest)
* [Kubernetes 官方文档](https://kubernetes.io/zh-cn/)

---

✅ 如果你需要，我还可以：

* 自动生成 `cloud-azure-terraform/` 和 `cloud-alicloud-terraform/` 模块；
* 整理完整的 GitHub 项目初始模板（含 Makefile、安装脚本）；
* 提供 VS Code + Devcontainer 配置文件，实现云端或远程开发体验；

只需回复“✅开始生成结构”，我将立即帮你构建开源项目骨架。
