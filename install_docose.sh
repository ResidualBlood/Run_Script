#!/bin/bash

# 获取最新版本的 Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

# 检查是否成功获取到版本号
if [ -z "$COMPOSE_VERSION" ]; then
    echo "无法获取 Docker Compose 的最新版本。"
    exit 1
fi

echo "最新版本的 Docker Compose 为: $COMPOSE_VERSION"

# 下载最新版本的 Docker Compose 二进制文件
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 给二进制文件设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version

# 如果需要，可以创建软链接到 /usr/bin 或者其他 PATH 目录
# sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
