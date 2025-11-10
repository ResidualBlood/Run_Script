#!/bin/bash

# --- Docker 安装脚本 (已修正和改进) ---

# 函数: 安装 Docker (Ubuntu)
# 修正: 使用现代的 GPG 密钥环方法 (与 Debian 相同)
# 修正: 添加 docker-compose-plugin
install_docker_ubuntu() {
    echo "Starting Docker installation for Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加 Docker 的官方 GPG 密钥环
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 设置稳定版仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
    sudo apt-get update
    # 安装 Docker 引擎, CLI, containerd, 以及 Compose V2 插件
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# 函数: 安装 Docker (CentOS)
# 修正: 从 'get.docker.com' 脚本改为使用官方 yum 仓库
# 修正: 添加 docker-compose-plugin
install_docker_centos() {
    echo "Starting Docker installation for CentOS..."
    sudo yum install -y yum-utils
    
    # 设置稳定版仓库
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    sudo yum check-update
    # 安装 Docker 引擎, CLI, containerd, 以及 Compose V2 插件
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# 函数: 安装 Docker (Fedora)
# 修正: 添加 docker-compose-plugin
install_docker_fedora() {
    echo "Starting Docker installation for Fedora..."
    sudo dnf -y install dnf-plugins-core
    
    # 设置稳定版仓库
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    
    # 安装 Docker 引擎, CLI, containerd, 以及 Compose V2 插件
    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# 函数: 安装 Docker (Debian)
# 修正: 添加 docker-compose-plugin
install_docker_debian() {
    echo "Starting Docker installation for Debian..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加 Docker 的官方 GPG 密钥环
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 设置稳定版仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
    sudo apt-get update
    # 安装 Docker 引擎, CLI, containerd, 以及 Compose V2 插件
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# --- 脚本主逻辑 ---

# 检测操作系统
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
else
    echo "无法检测到 /etc/os-release 文件。"
    exit 1
fi

echo "Detected OS: $OS_ID"

# 根据操作系统执行相应的安装函数
case $OS_ID in
    ubuntu)
        install_docker_ubuntu
        ;;
    debian)
        install_docker_debian
        ;;
    centos)
        install_docker_centos
        ;;
    fedora)
        install_docker_fedora
        ;;
    *)
        echo "不支持的操作系统: $OS_ID"
        exit 1
        ;;
esac

# --- 后续配置步骤 ---

echo "启动并启用 Docker 服务..."
# 启动并设置开机自启
sudo systemctl enable --now docker

echo "使用 sudo 验证 Docker 守护进程是否正在运行..."
# 修正: 使用 'sudo docker version' 来验证守护进程，因为当前用户权限尚未生效
if sudo docker version; then
    echo "Docker 守护进程已成功启动。"
else
    echo "Docker 守护进程启动失败，请检查。"
    exit 1
fi

echo "将当前用户 $USER 添加到 'docker' 组..."
# 将当前用户添加到 docker 组，以便无需 sudo 即可运行 docker
sudo usermod -aG docker $USER

echo
echo "--------------------------------------------------------------------"
echo "✅ Docker 和 Docker Compose (v2 插件) 安装完成！"
echo
echo "‼️ 重要提示:"
echo "您必须 **完全退出登录** 并 **重新登录** (或重启电脑),"
echo "新的 'docker' 组权限才会生效。"
echo
echo "重新登录后, 您就可以直接运行 'docker ps' (无需 sudo) 来验证。"
echo "--------------------------------------------------------------------"
