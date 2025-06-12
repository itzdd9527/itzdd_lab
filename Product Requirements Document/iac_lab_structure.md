iac-lab/
├── README.md
├── iac-lab/
│   ├── 提问模板.md
│   ├── Kubernetes + NFS 报告.md
│   └── 推荐方案说明.md
├── k8s-kind-nfs-terraform/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── kind-config.yaml
│   ├── nfs-deploy.yaml
│   └── README.md
├── k8s-vagrant-terraform-nfs/
│   ├── Vagrantfile
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── scripts/
│   │   ├── kubeadm-init.sh
│   │   └── nfs-setup.sh
│   └── README.md
├── cloud-azure-terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── cloud-init.sh
│   └── README.md
├── cloud-alicloud-terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── install.sh
│   └── README.md
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── .github/
│   └── workflows/
│       └── deploy.yml
├── .tool-versions
├── Makefile
└── scripts/
    ├── deploy_mac_k8s.sh
    ├── deploy_mac_vm.sh
    ├── deploy_azure_vm.sh
    ├── deploy_alicloud_lite.sh
    └── utils.sh


✅ 结构已更新，新增了 `scripts/` 目录与以下自动化部署脚本入口：

| 命令              | 描述                                         |
| --------------- | ------------------------------------------ |
| `make mac k8s`  | 自动部署 macOS 下的 Kind + NFS 单节点 Kubernetes 环境 |
| `make mac vm`   | 启动本地 Vagrant 多节点 VM 集群部署                   |
| `make azure`    | 在 Azure 上创建 VM 并自动安装测试环境                   |
| `make alicloud` | 在阿里云部署轻量服务器并初始化学习环境                        |

我们接下来可以：

* 🔧 编写 `Makefile` 中的命令解析逻辑
* 🧠 填充每个 `deploy_xxx.sh` 的实际部署逻辑
* 🔁 提供 `make help` 输出帮助命令描述

请告诉我现在是否：

* ✅ 先完成 `Makefile` 与 `scripts/utils.sh`
* ✅ 生成 `deploy_mac_k8s.sh` 的具体内容示例
