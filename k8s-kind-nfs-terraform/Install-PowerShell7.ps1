# 安装 PowerShell 7 脚本
# 检查 winget 是否可用
# 官方文档 https://learn.microsoft.com/zh-cn/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5
# 下载地址 https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "检测到 winget，正在使用 winget 安装 PowerShell 7..." -ForegroundColor Green
    winget install --id Microsoft.PowerShell --source winget -e
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PowerShell 7 通过 winget 安装完成。" -ForegroundColor Green
    } else {
        Write-Host "winget 安装 PowerShell 7 失败 (退出码: $LASTEXITCODE)，请尝试手动下载安装。" -ForegroundColor Yellow
        Write-Host "官方下载地址：https://github.com/PowerShell/PowerShell/releases/latest"
        Start-Process "https://github.com/PowerShell/PowerShell/releases/latest"
    }
} else {
    Write-Host "未检测到 winget，请手动下载安装 PowerShell 7。" -ForegroundColor Yellow
    Write-Host "官方下载地址：https://github.com/PowerShell/PowerShell/releases/latest"
    Start-Process "https://github.com/PowerShell/PowerShell/releases/latest"
}