#!/bin/bash

# 设置报错即退出 (可选，但在安装脚本中比较安全)
# set -e

# --- 颜色变量 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 检查是否为 Root 用户 ---
if [ "$(id -u)" != "0" ]; then
   warn "此脚本需要 root 权限运行，正在尝试使用 sudo..."
   SUDO="sudo"
else
   SUDO=""
fi

# --- 1. 检测操作系统 ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_CODENAME=${VERSION_CODENAME:-$VERSION_ID} # Fallback for some distros
else
    error "无法检测到 /etc/os-release 文件，脚本无法继续。"
    exit 1
fi

info "Detected OS: $OS ($VERSION_CODENAME)"

# --- 2. 通用安装函数 (Debian/Ubuntu) ---
install_debian_based() {
    info "Updating package index..."
    $SUDO apt-get update -qq

    info "Installing dependencies..."
    $SUDO apt-get install -y ca-certificates curl gnupg

    info "Setting up Docker GPG key..."
    # 建立标准的 keyrings 目录
    $SUDO install -m 0755 -d /etc/apt/keyrings
    # 下载 key，如果文件存在则覆盖
    curl -fsSL "https://download.docker.com/linux/$OS/gpg" | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

    info "Setting up the repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs 2>/dev/null || echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

    info "Installing Docker Engine and Compose Plugin..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# --- 3. 通用安装函数 (CentOS/Fedora/RHEL) ---
install_rhel_based() {
    local repo_url=""
    
    if [[ "$OS" == "fedora" ]]; then
        repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
        pkg_manager="dnf"
        $SUDO dnf -y install dnf-plugins-core
    else 
        # CentOS / RHEL / Rocky / Alma
        repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
        pkg_manager="yum"
        $SUDO yum install -y yum-utils
    fi

    info "Adding Docker repository..."
    $SUDO $pkg_manager config-manager --add-repo "$repo_url"

    info "Installing Docker Engine and Compose Plugin..."
    $SUDO $pkg_manager install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# --- 4. 执行安装逻辑 ---
case "$OS" in
    ubuntu|debian|raspbian|kali)
        install_debian_based
        ;;
    centos|fedora|rhel|rocky|almalinux)
        install_rhel_based
        ;;
    *)
        error "不支持的操作系统: $OS"
        exit 1
        ;;
esac

# --- 5. 服务配置 ---
info "Starting Docker service..."
$SUDO systemctl enable --now docker

# --- 6. 用户组配置 ---
if getent group docker > /dev/null 2>&1; then
    CURRENT_USER=${SUDO_USER:-$USER}
    info "Adding user '$CURRENT_USER' to docker group..."
    $SUDO usermod -aG docker "$CURRENT_USER"
else
    warn "Docker group does not exist (Installation failed?)"
fi

# --- 7. 验证与结束 ---
echo
echo "--------------------------------------------------------------------"
if $SUDO docker version > /dev/null 2>&1; then
    info "Docker Installation Successful!"
    echo "   - Docker Version:  $($SUDO docker --version | cut -d ' ' -f3 | tr -d ',')"
    echo "   - Compose Version: $($SUDO docker compose version | cut -d ' ' -f4)"
else
    error "Docker check failed. Please check logs."
    exit 1
fi

echo
warn "‼️  IMPORTANT:"
echo "   You must [Log Out] and [Log Back In] for group changes to take effect."
echo "   Or run: 'newgrp docker' to apply changes temporarily."
echo "--------------------------------------------------------------------"
