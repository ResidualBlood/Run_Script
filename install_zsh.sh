#!/bin/bash

# 判断操作系统是否为 Debian 或 macOS 并分别执行
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: 使用 Homebrew 安装必要软件
    echo "Installing dependencies for macOS..."
    # 如果 Homebrew 没有安装，先安装 Homebrew
    if ! command -v brew &>/dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update
    brew install sudo wget git nano zsh lnav font-fira-code font-fira-code-nerd-font
else
    # Debian: 使用 apt 安装必要软件
    echo "Installing dependencies for Debian..."
    apt update
    apt upgrade -y
    apt install sudo wget git nano zsh lnav -y

    # 设置 ulimit 限制（仅限 Debian 系统）
    echo "Setting ulimit restrictions for Debian..."
    # 将 ulimit 设置写入到 .zshrc 中
    cat << EOF >> ~/.zshrc

# 设置 ulimit 限制
ulimit -u 1048576
ulimit -n 1048576
ulimit -d unlimited
ulimit -m unlimited
ulimit -s unlimited
ulimit -t unlimited
ulimit -v unlimited
EOF
fi

# 安装 Oh My Zsh
echo "Installing Oh My Zsh..."
# macOS 使用 curl 下载脚本，而 Debian 使用 wget
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS 使用 curl 下载脚本
    sh -c "$(curl -fsSL https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh)"
else
    # Debian 使用 wget 下载脚本
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O install.sh
    sh install.sh <<EOF
Y
EOF
    rm install.sh
fi

# 安装 zsh-autosuggestions 插件
echo "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 安装 zsh-syntax-highlighting 插件
echo "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 配置 .zshrc 文件
echo "Configuring .zshrc..."
cd ~

# 添加自定义配置到 .zshrc
cat << EOF >> .zshrc

# 设置默认编辑器为 nano
export EDITOR=nano

# 自定义命令别名
alias sl="screen -ls"
alias sr="screen -R"
alias ss="screen -S"
alias docner="docker container"
alias docose="docker compose"

# 按两下 Esc 键往上条命令或者当前正在输入的命令前加上 "sudo"
sudo-command-line() {
    [[ -z \$BUFFER ]] && zle up-history
    if [[ \$BUFFER == sudo\ * ]]; then
        LBUFFER="\${LBUFFER#sudo }"
    elif [[ \$BUFFER == \$EDITOR\ * ]]; then
        LBUFFER="\${LBUFFER#\$EDITOR }"
        LBUFFER="sudoedit \$LBUFFER"
    elif [[ \$BUFFER == sudoedit\ * ]]; then
        LBUFFER="\${LBUFFER#sudoedit }"
        LBUFFER="\$EDITOR \$LBUFFER"
    else
        LBUFFER="sudo \$LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\\e\\e" sudo-command-line
EOF

# 更换默认主题为 agnoster
echo "Changing theme to agnoster..."
sed -i '' 's/robbyrussell/agnoster/' ~/.zshrc

# 配置插件
echo "Configuring plugins..."
sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# 配置 zsh-autosuggestions 插件颜色
echo "Configuring zsh-autosuggestions color..."
sed -i '' 's/fg=8/fg=cyan/' ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 更改默认 shell 为 zsh
echo "Changing default shell to zsh..."
chsh -s /bin/zsh

echo "Zsh installation and configuration complete."
