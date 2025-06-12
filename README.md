# Local Kubernetes and Infrastructure as Code (IaC) Learning Lab

👋 **Welcome to the Local Kubernetes and IaC Learning Lab!**

This repository is your gateway to mastering Kubernetes and Infrastructure as Code (IaC) principles right on your local machine. We provide a curated collection of projects that leverage tools like **Terraform, Vagrant, Kind, and Minikube** to automate the deployment and management of Kubernetes clusters, complete with NFS persistent storage.

Whether you're taking your first steps into the world of cloud-native technologies or looking to deepen your understanding of production-like setups, this lab is designed for you. Our core philosophy is **"all configurations as code,"** emphasizing version control, reproducibility, and easy migration of environments across different setups.

## 🌟 Lab Overview & Philosophy

This learning environment is built upon the power of **Terraform**, a premier IaC tool by HashiCorp. Using Terraform, you can:

*   **Automate** the setup of Virtual Machines (VMs) or Docker containers, saving significant time and ensuring consistent, error-free environments.
*   Interact with various local virtualization platforms (like VirtualBox, Docker Desktop) and Kubernetes APIs through Terraform's rich **provider ecosystem**.
*   Manage your entire infrastructure stack—from the underlying VMs to Kubernetes resources—in a unified way.
*   Treat your infrastructure definitions like application code: **version it, review it, and share it**. This dramatically improves reproducibility and portability, allowing you to recreate complex setups on any machine or share them with your team.

Our goal is to provide you with practical, hands-on experience, covering different learning stages from beginner explorations to advanced, near production-grade simulations.

## 📚 Product Specification

For a detailed understanding of the lab's features, target audience, learning objectives for each module, technical stack, and a comprehensive getting started guide, please refer to our **Product Specification**:

➡️ **[View Product Specification](./product_specification.md)**

## 🚀 Quick Navigation: Projects & Documents

This repository is organized to help you easily find what you need:

*   **Conceptual Documents & Reports (Mainly in Chinese):** Located in the root directory, these provide foundational knowledge.
    *   [`product_specification.md`](./product_specification.md): (English) Your primary guide to the learning lab.
    *   [`lac提示词.md`](./lac提示词.md): A template for formulating phased learning questions about deploying Kubernetes and NFS with Terraform (Chinese).
    *   [`使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md`](./使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md): An in-depth technical report detailing various implementation strategies (Chinese). This report heavily informs the `product_specification.md`.
    *   [`安装软件.md`](./安装软件.md): Software installation guide (Chinese).
    *   *Note: The `iac-lab/` directory mentioned in the old README seems to have its contents primarily in the root now or integrated into the main report. Adjusting paths accordingly.*

*   **`k8s-kind-nfs-terraform/`**: **Beginner-Friendly Kubernetes Lab**
    *   **Focus:** Quickly set up single or multi-node Kubernetes clusters using Kind (Kubernetes in Docker).
    *   **Technology:** Terraform manages the Kind cluster lifecycle and configures NFS for persistent storage (PV/PVC).
    *   **Get Started:** See the [`README.md`](./k8s-kind-nfs-terraform/README.md) inside this directory for detailed instructions.

*   **`k8s-vagrant-terraform-nfs/`**: **Intermediate Kubernetes Lab for Multi-Node Simulation**
    *   **Focus:** Simulate a more realistic multi-node cluster environment using Vagrant and VirtualBox (or VMware) to create VMs.
    *   **Technology:** Terraform orchestrates VM creation and configuration. `kubeadm` is used to initialize the Kubernetes cluster, with one node typically hosting the NFS server.
    *   **Get Started:** Check out the [`README.md`](./k8s-vagrant-terraform-nfs/README.md) in this directory for a full guide.

## 🎯 How to Get Started

1.  **Explore the [`product_specification.md`](./product_specification.md)**: This will give you a solid overview of what the lab offers and help you choose the right module for your learning goals.
2.  **Dive into the conceptual documents (root directory)**: For deeper insights into the design choices and technical considerations, browse files like `使用Terraform在本地学习环境中部署Kubernetes集群并配置NFS存储的专家报告.md`.
3.  **Choose Your First Project:**
    *   **New to Kubernetes?** We highly recommend starting with the [`k8s-kind-nfs-terraform/`](./k8s-kind-nfs-terraform/) project for a gentle introduction.
    *   **Ready for a more complex setup?** The [`k8s-vagrant-terraform-nfs/`](./k8s-vagrant-terraform-nfs/) project will guide you through deploying a multi-node cluster.
4.  **Follow the Project-Specific `README.md`**: Each project directory contains a detailed `README.md` with step-by-step deployment instructions, prerequisites, and validation checks.

## 💡 Learning Objectives

Through these hands-on labs, you will:

*   Embrace and apply the **Infrastructure as Code (IaC)** philosophy.
*   Gain proficiency in using tools like **Terraform, Vagrant, and Kind** to automate infrastructure.
*   Develop a strong understanding of **Kubernetes core concepts**: architecture, networking, storage (PVs, PVCs, NFS), and workloads.
*   Become adept at quickly creating, testing, and tearing down complex environments, fostering efficient learning and experimentation.

We hope these projects empower you on your journey to mastering Kubernetes and cloud-native technologies. Happy learning!
