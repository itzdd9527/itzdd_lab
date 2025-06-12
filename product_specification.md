# Product Specification: Local Kubernetes and IaC Learning Lab

## 1. Introduction/Overview

The "Local Kubernetes and IaC Learning Lab" is a project designed to provide a comprehensive, hands-on learning environment for individuals looking to understand and master Kubernetes and Infrastructure as Code (IaC) principles. Utilizing Terraform, this lab enables users to automatically deploy various Kubernetes cluster configurations along with NFS storage solutions directly on their local machines. The core philosophy is to make all configurations code-based, ensuring reproducibility, version control, and easy migration across different development setups. This lab aims to bridge the gap between theoretical knowledge and practical implementation by offering scalable scenarios that cater to different learning curves.

## 2. Target Audience

This learning lab is structured to accommodate a wide range of learners:

*   **Beginners:** Individuals new to Kubernetes and IaC. The lab offers simple, quick-to-deploy setups to grasp fundamental concepts like Pods, Services, Deployments, and basic persistent storage.
*   **Intermediate Learners:** Users who have a basic understanding of Kubernetes and want to explore more complex scenarios, such as multi-node clusters, automated deployments with Kubeadm, and dynamic storage provisioning.
*   **Advanced Learners:** Experienced users aiming to simulate near production-grade environments, including high-availability setups, custom Kubernetes component installations, and in-depth network configuration.

## 3. Features/Modules

The lab is organized into distinct modules, each representing a different approach to deploying Kubernetes and NFS storage locally:

*   **Module 1: Beginner - Kind/Minikube with Static NFS Storage**
    *   **Description:** Utilizes Kind (Kubernetes IN Docker) or Minikube for a single-node Kubernetes cluster. NFS storage is configured manually on the host and accessed via static PersistentVolume (PV) and PersistentVolumeClaim (PVC) definitions in Kubernetes.
    *   **Focus:** Rapidly understanding Kubernetes basics and static persistent storage concepts.

*   **Module 2: Intermediate - Multi-Node Kubeadm Cluster with Dynamic NFS Storage**
    *   **Description:** Employs Terraform to provision multiple VirtualBox virtual machines. A multi-node Kubernetes cluster is then deployed using `kubeadm`. NFS storage is also hosted on a dedicated VM and integrated with a dynamic provisioner (e.g., `nfs-subdir-external-provisioner`) to automate PV creation.
    *   **Focus:** Simulating a more realistic multi-node environment, mastering `kubeadm`, and learning about dynamic storage provisioning and advanced IaC practices.

*   **Module 3: Quick Test - Kind/Minikube with Direct NFS Mount**
    *   **Description:** Leverages Kind or Minikube for a quick Kubernetes setup. NFS storage (manually configured on the host) is mounted directly within Pod specifications, bypassing the PV/PVC abstraction.
    *   **Focus:** Extremely fast validation of application compatibility with NFS, suitable for resource-constrained environments or temporary tests.

## 4. Learning Objectives

Each module is designed with specific learning outcomes:

*   **Module 1 (Beginner):**
    *   Understand the core components of a Kubernetes cluster (Control Plane, Worker Nodes).
    *   Learn to deploy applications using Pods, Deployments, and Services.
    *   Grasp the concept of persistent storage with NFS.
    *   Understand static provisioning of PVs and PVCs.
    *   Get introduced to IaC using Terraform with `local-exec` for simple Kind/Minikube deployments.

*   **Module 2 (Intermediate):**
    *   Master the deployment of multi-node Kubernetes clusters using `kubeadm`.
    *   Understand the roles of master and worker nodes in a distributed setup.
    *   Learn to configure and manage virtual machines using Terraform and VirtualBox.
    *   Implement dynamic NFS storage provisioning using a StorageClass and an external provisioner.
    *   Deepen understanding of IaC with Terraform, including `remote-exec`, file provisioners, and managing dependencies between resources for complex setups.
    *   Gain insights into network configurations for VM-based clusters.

*   **Module 3 (Quick Test):**
    *   Quickly test application behavior with NFS shared storage.
    *   Understand the trade-offs of bypassing Kubernetes storage abstractions for speed.

## 5. Technical Stack

The learning lab utilizes the following key technologies:

*   **Terraform:** The core IaC tool for defining and managing all infrastructure components (VMs, containers, Kubernetes resources, NFS configurations).
*   **Kind (Kubernetes IN Docker):** A tool for running local Kubernetes clusters using Docker container “nodes.” Ideal for fast startup and testing.
*   **Minikube:** Another tool for running single-node Kubernetes clusters locally, supporting various drivers like Docker and VirtualBox.
*   **Vagrant:** Used in conjunction with Terraform (or as an alternative for VM management) to create and configure virtual machine environments.
*   **VirtualBox/VMware Workstation:** Virtualization platforms for running multi-node Kubernetes clusters on local machines.
*   **Kubeadm:** A Kubernetes official tool for bootstrapping best-practice Kubernetes clusters.
*   **NFS (Network File System):** The chosen storage solution for providing persistent storage to Kubernetes applications.
*   **Docker:** As a container runtime, primarily for Kind and potentially for Minikube or containerized NFS servers.
*   **kubectl:** The Kubernetes command-line tool for interacting with clusters.
*   **Shell Scripting (Bash):** Used for automation tasks within VMs, executed via Terraform's provisioners.

## 6. Getting Started Guide

To begin using the Local Kubernetes and IaC Learning Lab:

1.  **Prerequisites:**
    *   Install Terraform: [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/docker-get-started/install-cli)
    *   Install Docker Desktop (for Kind/Minikube with Docker driver): [Docker Desktop](https://docs.docker.com/desktop/)
    *   Install VirtualBox (for Kubeadm/Vagrant modules): [VirtualBox Downloads](https://www.virtualbox.org/wiki/Downloads)
    *   Install kubectl: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    *   (Optional) Install Vagrant: [Vagrant Installation](https://www.vagrantup.com/docs/installation)

2.  **Clone the Repository:**
    *   Obtain the project files from the designated Git repository.
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

3.  **Choose a Module:**
    *   Navigate to the directory corresponding to the desired learning module (e.g., `module-1-beginner-kind/`, `module-2-intermediate-kubeadm/`). Each module will have its own `README.md` with specific instructions.

4.  **Review Configuration:**
    *   Examine the Terraform files (`.tf`) to understand the infrastructure being defined.
    *   Adjust any variables (e.g., in `variables.tf` or `terraform.tfvars`) as needed for your local setup (e.g., IP addresses, VM resource allocations).

5.  **Deploy the Environment:**
    *   Initialize Terraform (downloads necessary providers):
        ```bash
        terraform init
        ```
    *   (Optional) Preview the changes Terraform will make:
        ```bash
        terraform plan
        ```
    *   Apply the configuration to create the resources:
        ```bash
        terraform apply --auto-approve
        ```

6.  **Verify and Use:**
    *   Follow the specific validation steps in the module's `README.md` to ensure the cluster and NFS storage are working correctly.
    *   Use `kubectl` (with the Kubeconfig file often generated or specified by Terraform output) to interact with your Kubernetes cluster.

7.  **Clean Up:**
    *   When finished, destroy the created resources to free up system resources:
        ```bash
        terraform destroy --auto-approve
        ```

*Refer to the main `README.md` of the project and the individual `README.md` files within each module directory for detailed step-by-step guides and troubleshooting tips.*

## 7. Future Enhancements (Optional)

*   **Advanced Kubeadm Module:** Include a module for deploying a high-availability (HA) Kubernetes cluster using Kubeadm with stacked control plane nodes or external etcd.
*   **Alternative CNI Plugins:** Provide options to deploy clusters with different CNI plugins (e.g., Cilium, Flannel) beyond the default or Calico.
*   **Integration with CI/CD:** Demonstrate how to integrate the Terraform configurations with a CI/CD pipeline (e.g., GitLab CI, GitHub Actions) for automated environment provisioning.
*   **Alternative IaC Tools:** Explore modules using other IaC tools like Ansible for configuration management post-provisioning.
*   **Monitoring and Logging Stack:** Add a module to deploy a basic monitoring (Prometheus, Grafana) and logging (EFK stack) solution within the Kubernetes cluster.
*   **Packer for VM Images:** Introduce Packer for creating custom VM base images to speed up Kubeadm deployments.
*   **More Storage Solutions:** Explore other local storage solutions or CSI drivers.
```
