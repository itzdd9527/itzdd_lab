---

# 📄 产品需求文档（PRD）

## 本地学习与测试环境配置同步工具

> 支持 GitHub 同步、IaC 配置化、跨平台部署的学习实验框架

---

## 一、产品概述

**产品名称**：本地跨平台学习与测试环境统一配置项目（简称：`iac-lab`）
**项目目标**：构建一个可持续扩展、代码化、可复用的本地实验环境管理系统，适用于 Kubernetes 及后续各类开发测试学习环境。

**主要特点**：

* ✅ 所有环境通过代码管理（Terraform / 脚本 / 配置）
* ✅ 支持 macOS、Linux、Windows（含 WSL）
* ✅ 基于 GitHub 同步与协作
* ✅ 起始聚焦 Kubernetes 学习，后续可拓展到 DevOps、服务网格、安全测试等方向
* ✅ 使用主流工具如 Terraform、Vagrant、Kind、Docker、NFS

---

## 二、目标用户

| 用户类型       | 典型特征                      | 需求              |
| ---------- | ------------------------- | --------------- |
| 云原生学习者     | 自学者、培训班学生                 | 快速构建学习环境，复用配置   |
| DevOps 实践者 | 小团队或个人运维开发                | 本地模拟真实环境，测试 IaC |
| 教育与培训机构    | 教学交付 Kubernetes/DevOps 内容 | 统一课程环境，一键部署     |
| 企业内部研发团队   | 对测试环境隔离/自动化有需求            | 自定义工作区，版本化配置    |

---

## 三、用户故事

### 📘 初学者故事（K8s入门）

> “我在学习 Kubernetes，网上很多教程都让我手动安装组件，操作很杂乱。我希望有一个本地环境，一键部署好 Kind、NFS，并告诉我配置背后的原理。”

### 🧪 进阶使用者（扩展环境）

> “我已经掌握了基础 Kubernetes，接下来我想测试 Argo CD、Prometheus、ELK。这套环境最好能让我复用以前的配置，随时扩展模块。”

### 👥 团队协作者（多人共享配置）

> “我们小团队用 GitHub 管理代码，但每个人的开发测试环境不一致，经常‘跑不起来’。我希望我们能共享一套 Terraform 配置和部署脚本。”

---

## 四、功能模块与阶段目标

| 阶段         | 模块名称                                    | 描述                              |
| ---------- | --------------------------------------- | ------------------------------- |
| v0 初级学习环境  | `kind` + `terraform` + `nfs`            | 快速创建单节点 K8s 集群，挂载 NFS，理解 PVC    |
| v1 多节点测试环境 | `vagrant` + `terraform` + `kubeadm`     | 使用 VM 模拟生产架构，支持 NFS 持久化存储       |
| v2 环境扩展模块  | ArgoCD / Prometheus / Ingress           | 将实战组件纳入脚本化部署中                   |
| v3 配置与依赖统一 | `chezmoi` / `devbox` / `.tool-versions` | 同步 shell、vim、kubeconfig 等开发环境配置 |
| v4 云端对接准备  | GitHub Actions / DevPod 支持              | 将环境部署脚本自动化，支持远程环境启动（选配）         |

---

## 五、技术选型

| 类别       | 工具                            | 理由                     |
| -------- | ----------------------------- | ---------------------- |
| IaC 工具   | Terraform                     | 统一管理本地资源（VM、Docker、网络） |
| 虚拟机管理    | Vagrant + VirtualBox / VMware | 模拟多节点集群                |
| K8s 入门部署 | Kind (K8s in Docker)          | 快速容器化运行 Kubernetes     |
| 本地持久化    | NFS                           | 模拟 PVC 场景并支持共享         |
| 配置同步     | GitHub + chezmoi              | 同步 dotfiles、配置、脚本等     |
| 脚本工具     | bash + Makefile               | 简化命令，形成可维护执行流程         |

---

## 六、目录结构建议

```bash
iac-lab/
├── iac-lab/                          # IaC 学习笔记 & 模板
│   ├── 提问模板.md
│   ├── Terraform部署K8s+NFS报告.md
│   └── 推荐方案说明.md
├── k8s-kind-nfs-terraform/          # 初学者实验项目
│   ├── README.md
│   ├── terraform/
│   ├── kind-config.yaml
│   └── nfs-deploy.yaml
├── k8s-vagrant-terraform-nfs/       # 中级实战项目
│   ├── Vagrantfile
│   ├── terraform/
│   ├── nfs-setup.sh
│   └── kubeadm-init.sh
├── .devcontainer/                   # VSCode 开发容器支持
├── .github/workflows/               # GitHub Actions 自动化部署
└── Makefile                         # 快捷命令入口
```

---

## 七、平台兼容性与要求

| 工具                    | macOS    | Windows（含 WSL） | Linux |
| --------------------- | -------- | -------------- | ----- |
| Terraform             | ✅        | ✅              | ✅     |
| Docker Desktop + Kind | ✅        | ✅              | ✅     |
| Vagrant + VirtualBox  | ✅        | ✅              | ✅     |
| NFS 服务支持              | ✅（mac自带） | 推荐容器化实现        | ✅     |
| GitHub + Shell        | ✅        | ✅              | ✅     |

---

## 八、交付计划

| 时间      | 版本   | 内容                                         |
| ------- | ---- | ------------------------------------------ |
| 2025-06 | v0.1 | 完成 Kind + Terraform + NFS 单节点环境            |
| 2025-07 | v0.2 | 完成 Vagrant 多节点 VM 环境脚本及部署文档                |
| 2025-08 | v0.3 | 加入 ArgoCD、Ingress、Dashboard 等 K8s 应用部署     |
| 2025-09 | v0.4 | dotfiles 环境统一（chezmoi）+ GitHub Actions 自动化 |
| 2025-10 | v1.0 | 项目文档完善 + 开源发布推广（GitHub/掘金等）                |

---

## 九、未来可扩展方向

* ☁️ 云端对接（可选）：拓展到本地-云混合环境测试（如阿里云 ACK、AWS EKS）
* 🧪 更多实验模块：如 service mesh、Helm Charts、CI/CD
* 🎓 教学平台支持：支持脚本+Web 页面部署教学环境

---

## 十、附录与参考链接

* [Kind 官方文档](https://kind.sigs.k8s.io/)
* [Terraform 官方文档](https://developer.hashicorp.com/terraform)
* [Kubernetes 官方文档](https://kubernetes.io/docs/home/)
* [Vagrant 官方网站](https://www.vagrantup.com/)
* [GitHub Codespaces](https://github.com/features/codespaces)

---

如你愿意，我可以：

* 帮你初始化 GitHub 项目结构并打包为 ZIP；
* 生成 README 和 `.gitignore`；
* 提供 Makefile 自动执行入口（如 `make up-kind`, `make up-vagrant`）；

是否现在就帮你生成开源项目结构并准备启动文件？只需说一声 ✅。
