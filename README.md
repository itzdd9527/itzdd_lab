# 本地 Kubernetes 与基础设施即代码 (IaC) 学习实验环境

欢迎来到本地 Kubernetes 与 IaC 学习实验环境仓库！

本仓库旨在提供一系列使用 Terraform、Vagrant、Kind 等工具在本地计算机上搭建和管理 Kubernetes 集群，并配置 NFS 作为持久化存储的实验项目。这些项目覆盖了从初学者到中级实战的不同阶段，帮助您理解和实践云原生技术和基础设施即代码的核心概念。

## 仓库结构与项目概览

本仓库主要包含以下几个部分：

*   **`iac-lab/`**: 存放与 IaC 相关的学习笔记、提问模板和方案报告。
    *   <mcfile name="lac提示词.md" path="d:\itzdd_lab\iac-lab\lac提示词.md"></mcfile>: 关于如何使用 Terraform 部署 Kubernetes + NFS 的分阶段提问模板。
    *   <mcfile name="使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md" path="d:\itzdd_lab\iac-lab\使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md"></mcfile>: 详细的技术报告，阐述了不同方案的实现细节。
    *   <mcfile name="推荐方案：Vagrant + VirtualBox + Terraform.md" path="d:\itzdd_lab\iac-lab\推荐方案：Vagrant + VirtualBox + Terraform.md"></mcfile>: 推荐使用 Vagrant 和 VirtualBox 结合 Terraform 进行本地环境搭建的方案说明。

*   **`k8s-kind-nfs-terraform/`**: 初学者友好的 Kubernetes 实验项目。
    *   使用 Kind (Kubernetes in Docker) 快速搭建单节点或多节点集群。
    *   通过 Terraform 管理 Kind 集群生命周期，并配置 NFS 作为持久卷声明 (PVC) 的后端存储。
    *   详情请查阅该目录下的 <mcfile name="README.md" path="d:\itzdd_lab\k8s-kind-nfs-terraform\README.md"></mcfile>。

*   **`k8s-vagrant-terraform-nfs/`**: 面向中级实战的 Kubernetes 实验项目。
    *   使用 Vagrant 和 VirtualBox (或 VMware) 创建多台虚拟机，模拟更真实的集群环境。
    *   通过 Terraform 编排虚拟机的创建和配置，使用 Kubeadm 初始化 Kubernetes 集群，并在一台节点上部署 NFS 服务器。
    *   详情请查阅该目录下的 <mcfile name="README.md" path="d:\itzdd_lab\k8s-vagrant-terraform-nfs\README.md"></mcfile>。

## 如何开始

1.  **浏览 `iac-lab/`**：了解不同方案的设计思路和技术选型。
2.  **选择一个项目开始实践**：
    *   如果您是 Kubernetes 初学者，建议从 <mcfolder name="k8s-kind-nfs-terraform" path="d:\itzdd_lab\k8s-kind-nfs-terraform"></mcfolder> 项目开始。
    *   如果您希望体验更接近生产环境的多节点集群部署，可以尝试 <mcfolder name="k8s-vagrant-terraform-nfs" path="d:\itzdd_lab\k8s-vagrant-terraform-nfs"></mcfolder> 项目。
3.  **遵循各项目中的 `README.md`**：每个项目都有详细的部署步骤和说明。

## 目标

*   学习并实践基础设施即代码 (IaC) 的理念。
*   掌握使用 Terraform、Vagrant、Kind 等工具自动化部署和管理基础设施的能力。
*   深入理解 Kubernetes 的核心组件、网络、存储等概念。
*   能够在本地环境中快速搭建、测试和销毁实验环境，方便学习和调试。

希望这些实验项目能帮助您更好地学习和掌握 Kubernetes 及相关云原生技术！