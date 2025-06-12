# 本地 Kubernetes 和基础设施即代码 (IaC) 学习实验室

👋 **欢迎来到本地 Kubernetes 和 IaC 学习实验室！**

本仓库是您在本地机器上掌握 Kubernetes 和基础设施即代码（IaC）原则的门户。我们提供精心策划的项目集合，利用 **Terraform、Vagrant、Kind 和 Minikube** 等工具来自动化部署和管理 Kubernetes 集群，并配备 NFS 持久化存储。

无论您是刚开始接触云原生技术，还是想深入理解类生产环境的设置，本实验室都是为您设计的。我们的核心理念是 **"所有配置皆代码"**，强调版本控制、可重复性以及环境在不同设置之间的轻松迁移。

## 🌟 实验室概述与理念

本学习环境建立在 HashiCorp 的优秀 IaC 工具 **Terraform** 之上。使用 Terraform，您可以：

* **自动化** 虚拟机（VM）或 Docker 容器的设置，节省大量时间并确保环境一致性，避免错误。
* 通过 Terraform 丰富的 **提供商生态系统** 与各种本地虚拟化平台（如 VirtualBox、Docker Desktop）和 Kubernetes API 交互。
* 以统一的方式管理整个基础设施栈——从底层 VM 到 Kubernetes 资源。
* 像对待应用程序代码一样处理基础设施定义：**版本控制、审查和共享**。这极大地提高了可重复性和可移植性，使您能够在任何机器上重新创建复杂的设置或与团队共享。

我们的目标是为您提供实用的动手经验，涵盖从初学者探索到高级的近生产级模拟的不同学习阶段。

## 📚 产品规格说明

要详细了解实验室的功能、目标受众、每个模块的学习目标、技术栈和综合入门指南，请参考我们的 **产品规格说明**：

➡️ **[查看产品规格说明](./product_specification.md)**

## 🚀 快速导航：项目和文档

本仓库的组织方式旨在帮助您轻松找到所需内容：

* **概念文档和报告（主要为中文）：** 位于根目录，提供基础知识。
    * [`product_specification.md`](./product_specification.md)：（英文）您的学习实验室主要指南。
    * [`lac提示词.md`](./lac提示词.md)：关于使用 Terraform 部署 Kubernetes 和 NFS 的分阶段学习问题模板（中文）。
    * [`使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md`](./使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md)：详细说明各种实现策略的深入技术报告（中文）。
    * [`安装软件.md`](./安装软件.md)：软件安装指南（中文）。
    * *注：旧 README 中提到的 `iac-lab/` 目录内容现已主要整合到根目录或主报告中。*

* **`k8s-kind-nfs-terraform/`**：**适合初学者的 Kubernetes 实验室**
    * **重点：** 使用 Kind（Kubernetes in Docker）快速设置单节点或多节点 Kubernetes 集群。
    * **技术：** Terraform 管理 Kind 集群生命周期并配置 NFS 用于持久化存储（PV/PVC）。
    * **开始使用：** 查看此目录中的 [`README.md`](./k8s-kind-nfs-terraform/README.md) 获取详细说明。

* **`k8s-vagrant-terraform-nfs/`**：**面向多节点模拟的中级 Kubernetes 实验室**
    * **重点：** 使用 Vagrant 和 VirtualBox（或 VMware）创建 VM，模拟更真实的多节点集群环境。
    * **技术：** Terraform 编排 VM 创建和配置。使用 `kubeadm` 初始化 Kubernetes 集群，通常一个节点托管 NFS 服务器。
    * **开始使用：** 查看此目录中的 [`README.md`](./k8s-vagrant-terraform-nfs/README.md) 获取完整指南。

## 🎯 如何开始

1. **浏览 [`product_specification.md`](./product_specification.md)**：这将让您对实验室提供的内容有一个全面的了解，并帮助您选择适合您学习目标的模块。
2. **深入研究概念文档（根目录）**：浏览如 `使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md` 等文件，了解更深入的设计选择和技术考虑。
3. **选择您的第一个项目：**
    * **Kubernetes 新手？** 我们强烈建议从 [`k8s-kind-nfs-terraform/`](./k8s-kind-nfs-terraform/) 项目开始，获得温和的入门体验。
    * **准备好更复杂的设置？** [`k8s-vagrant-terraform-nfs/`](./k8s-vagrant-terraform-nfs/) 项目将指导您部署多节点集群。
4. **遵循项目特定的 `README.md`**：每个项目目录都包含详细的 `README.md`，提供逐步部署说明、前提条件和验证检查。

## 💡 学习目标

通过这些动手实验室，您将：

* 接受并应用 **基础设施即代码（IaC）** 理念。
* 熟练使用 **Terraform、Vagrant 和 Kind** 等工具自动化基础设施。
* 深入理解 **Kubernetes 核心概念**：架构、网络、存储（PV、PVC、NFS）和工作负载。
* 擅长快速创建、测试和销毁复杂环境，促进高效学习和实验。

我们希望这些项目能够在您掌握 Kubernetes 和云原生技术的旅程中为您赋能。祝您学习愉快！