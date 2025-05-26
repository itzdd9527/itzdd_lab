# PowerShell Script to Install Necessary Tools for k8s-kind-nfs-terraform Lab on Windows

Write-Host "开始安装 k8s-kind-nfs-terraform 实验所需工具..." -ForegroundColor Green
Write-Host "请确保以管理员身份运行此脚本。" -ForegroundColor Yellow

# --- 检查 Winget 是否可用 ---
Write-Host "正在检查 Winget (Windows 程序包管理器)..." -ForegroundColor Cyan
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetPath) {
    Write-Host "Winget 未找到。Winget 是推荐的安装方式之一。" -ForegroundColor Yellow
    Write-Host "您可以从 Microsoft Store 安装 '应用安装程序' (App Installer) 来获取 Winget," -ForegroundColor Yellow
    Write-Host "或者访问 https://aka.ms/getwinget 获取更多信息。" -ForegroundColor Yellow
    Write-Host "脚本将尝试其他方式,但 Winget 可以简化某些安装。" -ForegroundColor Yellow
} else {
    Write-Host "Winget 已找到。" -ForegroundColor Green
}

# --- 1. 安装/检查 Terraform ---
Write-Host "`n--- 1. 安装/检查 Terraform ---" -ForegroundColor Cyan
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    Write-Host "Terraform 已安装：" -ForegroundColor Green
    terraform version
} else {
    Write-Host "Terraform 未安装。尝试使用 Winget 安装..." -ForegroundColor Yellow
    if ($wingetPath) {
        Write-Host "正在执行: winget install --id Hashicorp.Terraform --source winget -e --accept-package-agreements --accept-source-agreements"
        winget install --id Hashicorp.Terraform --source winget -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            # 即使 winget 退出码为 0，也需要再次检查 terraform 命令是否可用，因为 winget 可能只是下载了安装程序
            # 或者在某些情况下，winget install 成功了，但 PATH 可能需要新的终端会话才能更新
            if (Get-Command terraform -ErrorAction SilentlyContinue) {
                Write-Host "Terraform 安装成功 (通过 Winget)。" -ForegroundColor Green
                terraform version
            } else {
                Write-Host "Winget 安装命令已执行，但 Terraform 命令仍然不可用。" -ForegroundColor Yellow
                Write-Host "Terraform 可能已安装，但其可执行文件路径需要手动添加到系统 PATH 环境变量中。" -ForegroundColor Yellow
                Write-Host "Terraform 通常安装在 C:\Program Files\HashiCorp\Terraform 或类似路径。" -ForegroundColor Yellow
                Write-Host "您可能需要重启 PowerShell 终端或计算机才能识别新的 PATH 变量。" -ForegroundColor Yellow
            }
        } else {
            Write-Host "使用 Winget 安装 Terraform 失败。Winget 退出码: $LASTEXITCODE" -ForegroundColor Red
            Write-Host "请从官方网站手动下载并安装 Terraform: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
            Write-Host "下载后,请解压并将 terraform.exe 所在目录添加到系统 PATH 环境变量。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Winget 不可用。请从官方网站手动下载并安装 Terraform: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
        Write-Host "下载后,请解压并将 terraform.exe 所在目录添加到系统 PATH 环境变量。" -ForegroundColor Yellow
    }
}

# --- 2. 安装/检查 Docker Desktop ---
Write-Host "`n--- 2. 安装/检查 Docker Desktop ---" -ForegroundColor Cyan
# Docker Desktop 的安装通常需要用户交互,并且最好从官方网站下载最新版本。
Write-Host "Docker Desktop 是运行 Kind 的核心依赖。" -ForegroundColor Yellow
Write-Host "请从官方网站下载并安装 Docker Desktop for Windows: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
Write-Host "安装过程中,请确保选择启用 WSL 2 后端 (如果您的系统支持并已安装 WSL 2),或者 Hyper-V 后端。" -ForegroundColor Yellow
Write-Host "安装完成后,请启动 Docker Desktop 并确保其正常运行。" -ForegroundColor Yellow
# 检查 Docker 是否正在运行 (这只是一个基本检查,不能保证 Docker Desktop 完全配置正确)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker version --format '{{.Server.Version}}'
        Write-Host "Docker 守护进程似乎正在运行。" -ForegroundColor Green
    } catch {
        Write-Host "Docker 命令可用,但无法连接到 Docker 守护进程。请确保 Docker Desktop 已启动并正常运行。" -ForegroundColor Yellow
    }
} else {
    Write-Host "Docker 命令未找到。请在安装 Docker Desktop 后再试。" -ForegroundColor Yellow
}

# --- 3. 安装/检查 kubectl ---
Write-Host "`n--- 3. 安装/检查 kubectl ---" -ForegroundColor Cyan
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Host "kubectl 已安装：" -ForegroundColor Green
    kubectl version --client
} else {
    Write-Host "kubectl 未安装。尝试使用 Winget 安装..." -ForegroundColor Yellow
    if ($wingetPath) {
        try {
            winget install --id Kubernetes.kubectl -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "kubectl 安装成功 (通过 Winget)。" -ForegroundColor Green
                Write-Host "您可能需要重启 PowerShell 终端才能识别新的 PATH 变量。" -ForegroundColor Green
            } else {
                Write-Host "使用 Winget 安装 kubectl 失败。Winget 退出码: $LASTEXITCODE" -ForegroundColor Red
                Write-Host "您可以从 Docker Desktop 设置中启用 Kubernetes,它通常会附带 kubectl。" -ForegroundColor Yellow
                Write-Host "或者,从官方网站手动下载并安装 kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
                Write-Host "下载后,请将 kubectl.exe 所在目录添加到系统 PATH 环境变量。" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "使用 Winget 安装 kubectl 失败。错误: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "您可以从 Docker Desktop 设置中启用 Kubernetes,它通常会附带 kubectl。" -ForegroundColor Yellow
            Write-Host "或者,从官方网站手动下载并安装 kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
            Write-Host "下载后,请将 kubectl.exe 所在目录添加到系统 PATH 环境变量。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Winget 不可用。您可以从 Docker Desktop 设置中启用 Kubernetes,它通常会附带 kubectl。" -ForegroundColor Yellow
        Write-Host "或者,从官方网站手动下载并安装 kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
        Write-Host "下载后,请将 kubectl.exe 所在目录添加到系统 PATH 环境变量。" -ForegroundColor Yellow
    }
}

# --- 4. 安装/检查 Git ---
Write-Host "`n--- 4. 安装/检查 Git ---" -ForegroundColor Cyan
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git 已安装：" -ForegroundColor Green
    git --version
} else {
    Write-Host "Git 未安装。尝试使用 Winget 安装..." -ForegroundColor Yellow
    if ($wingetPath) {
        try {
            winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Git 安装成功 (通过 Winget)。" -ForegroundColor Green
                Write-Host "您可能需要重启 PowerShell 终端才能识别新的 PATH 变量。" -ForegroundColor Green
            } else {
                Write-Host "使用 Winget 安装 Git 失败。Winget 退出码: $LASTEXITCODE" -ForegroundColor Red
                Write-Host "请从官方网站手动下载并安装 Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
                Write-Host "安装过程中,建议选择将 Git 添加到 PATH,并选择推荐的选项。" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "使用 Winget 安装 Git 失败。错误: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "请从官方网站手动下载并安装 Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
            Write-Host "安装过程中,建议选择将 Git 添加到 PATH,并选择推荐的选项。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Winget 不可用。请从官方网站手动下载并安装 Git for Windows: https://git-scm.com/download/win" -ForegroundColor Yellow
        Write-Host "安装过程中,建议选择将 Git 添加到 PATH,并选择推荐的选项。" -ForegroundColor Yellow
    }
}

# --- 5. 安装/检查 Kind ---
Write-Host "`n--- 5. 安装/检查 Kind ---" -ForegroundColor Cyan
if (Get-Command kind -ErrorAction SilentlyContinue) {
    Write-Host "Kind 已安装：" -ForegroundColor Green
    kind version
} else {
    Write-Host "Kind 未安装。尝试使用 Winget 安装..." -ForegroundColor Yellow
    if ($wingetPath) {
        try {
            winget install --id Kubernetes.kind -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Kind 安装成功 (通过 Winget)。" -ForegroundColor Green
                Write-Host "您可能需要重启 PowerShell 终端才能识别新的 PATH 变量。" -ForegroundColor Green
            } else {
                Write-Host "使用 Winget 安装 Kind 失败。尝试使用 Chocolatey 或手动安装..." -ForegroundColor Yellow
                Write-Host "您可以使用以下命令手动安装 Kind:" -ForegroundColor Yellow
                Write-Host "curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64" -ForegroundColor Yellow
                Write-Host "Move-Item .\kind-windows-amd64.exe C:\Windows\kind.exe" -ForegroundColor Yellow
                Write-Host "或者访问 https://kind.sigs.k8s.io/docs/user/quick-start/#installation 获取更多信息。" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "使用 Winget 安装 Kind 失败。错误: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "您可以使用以下命令手动安装 Kind:" -ForegroundColor Yellow
            Write-Host "curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64" -ForegroundColor Yellow
            Write-Host "Move-Item .\kind-windows-amd64.exe C:\Windows\kind.exe" -ForegroundColor Yellow
            Write-Host "或者访问 https://kind.sigs.k8s.io/docs/user/quick-start/#installation 获取更多信息。" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Winget 不可用。您可以使用以下命令手动安装 Kind:" -ForegroundColor Yellow
        Write-Host "curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64" -ForegroundColor Yellow
        Write-Host "Move-Item .\kind-windows-amd64.exe C:\Windows\kind.exe" -ForegroundColor Yellow
        Write-Host "或者访问 https://kind.sigs.k8s.io/docs/user/quick-start/#installation 获取更多信息。" -ForegroundColor Yellow
    }
}

# --- 6. 启用 WSL 2 (推荐) ---
Write-Host "`n--- 6. 启用 WSL 2 (Windows Subsystem for Linux 2) ---" -ForegroundColor Cyan
Write-Host "WSL 2 为 Docker Desktop 提供了更好的性能和兼容性。" -ForegroundColor Yellow
Write-Host "检查 WSL 功能状态..."

$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

if ($wslFeature.State -ne "Enabled") {
    Write-Host "正在启用 Windows Subsystem for Linux 功能..." -ForegroundColor Yellow
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Write-Host "Windows Subsystem for Linux 功能已请求启用。" -ForegroundColor Green
    } catch {
        Write-Host "启用 Windows Subsystem for Linux 功能失败。请以管理员身份运行此脚本。" -ForegroundColor Red
        Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Windows Subsystem for Linux 功能已启用。" -ForegroundColor Green
}

if ($vmPlatformFeature.State -ne "Enabled") {
    Write-Host "正在启用 Virtual Machine Platform 功能..." -ForegroundColor Yellow
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        Write-Host "Virtual Machine Platform 功能已请求启用。" -ForegroundColor Green
    } catch {
        Write-Host "启用 Virtual Machine Platform 功能失败。请以管理员身份运行此脚本。" -ForegroundColor Red
        Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Virtual Machine Platform 功能已启用。" -ForegroundColor Green
}

if (($wslFeature.State -ne "Enabled") -or ($vmPlatformFeature.State -ne "Enabled")) {
    Write-Host "`n重要提示: WSL 2 的某些功能更改需要重启计算机才能生效。" -ForegroundColor Yellow
    Write-Host "请在脚本执行完毕后,根据系统提示重启计算机。" -ForegroundColor Yellow
    Write-Host "重启后,您需要执行以下步骤:" -ForegroundColor Yellow
    Write-Host "1. 下载并安装 WSL 2 Linux 内核更新包: https://aka.ms/wsl2kernel" -ForegroundColor Yellow
    Write-Host "2. 运行 'wsl --set-default-version 2' 命令将 WSL 默认版本设置为 2" -ForegroundColor Yellow
    Write-Host "3. 从 Microsoft Store 安装一个 Linux 发行版 (例如 Ubuntu)" -ForegroundColor Yellow
} else {
    Write-Host "WSL 2 所需的基本功能已启用。" -ForegroundColor Green
    Write-Host "如果尚未设置,请执行以下步骤:" -ForegroundColor Green
    Write-Host "1. 下载并安装 WSL 2 Linux 内核更新包: https://aka.ms/wsl2kernel" -ForegroundColor Green
    Write-Host "2. 运行 'wsl --set-default-version 2' 命令将 WSL 默认版本设置为 2" -ForegroundColor Green
    Write-Host "3. 从 Microsoft Store 安装一个 Linux 发行版 (例如 Ubuntu)" -ForegroundColor Green
}

# --- 7. NFS 服务说明 ---
Write-Host "`n--- 7. NFS 服务说明 ---" -ForegroundColor Cyan
Write-Host "对于 Windows 平台,推荐在 Kind 集群内部署 NFS 服务容器,而不是在主机上配置 NFS 服务。" -ForegroundColor Yellow
Write-Host "项目中的 terraform/nfs-deploy.yaml 文件将在 Kind 集群中部署 NFS 服务容器。" -ForegroundColor Yellow
Write-Host "如果您仍然希望在 Windows 上配置 NFS 服务,可以:" -ForegroundColor Yellow
Write-Host "1. 在 WSL 2 Linux 发行版中安装和配置 NFS 服务" -ForegroundColor Yellow
Write-Host "2. 使用第三方 NFS 服务器软件,如 Hanewin NFS Server 或 WinNFSd" -ForegroundColor Yellow
Write-Host "3. 启用 Windows 的 'NFS 服务器' 功能 (仅适用于某些 Windows 版本)" -ForegroundColor Yellow

Write-Host "`n--- 工具安装检查/引导完成 ---" -ForegroundColor Green
Write-Host "请手动验证所有工具是否已正确安装并配置到系统 PATH 环境变量中:" -ForegroundColor Cyan
Write-Host "1. Terraform: terraform version" -ForegroundColor Cyan
Write-Host "2. Docker Desktop: docker version" -ForegroundColor Cyan
Write-Host "3. kubectl: kubectl version --client" -ForegroundColor Cyan
Write-Host "4. Git: git --version" -ForegroundColor Cyan
Write-Host "5. Kind: kind version" -ForegroundColor Cyan
Write-Host "如果通过 Winget 安装后某些工具命令不可用,您可能需要:" -ForegroundColor Cyan
Write-Host "- 重启 PowerShell 终端或计算机" -ForegroundColor Cyan
Write-Host "- 手动将工具的可执行文件路径添加到系统 PATH 环境变量中" -ForegroundColor Cyan
Write-Host "对于 WSL 2,请确保已完成所有配置步骤,包括安装 Linux 发行版和设置默认版本。" -ForegroundColor Cyan
Write-Host "完成后,您应该可以继续进行 k8s-kind-nfs-terraform 实验了。" -ForegroundColor Green