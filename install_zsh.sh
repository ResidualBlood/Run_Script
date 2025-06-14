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
    brew install sudo wget git nano zsh lnav font-fira-code font-fira-code-nerd-font tree
else
    # Debian: 使用 apt 安装必要软件
    echo "Installing dependencies for Debian..."
    apt update
    apt upgrade -y
    apt install sudo wget git nano zsh lnav tree-y

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

# 安装 history-substring-search 插件
echo "Installing history-substring-search..."
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/history-substring-search

# 配置 .zshrc 文件
echo "Configuring .zshrc..."
cd ~

# 添加自定义配置到 .zshrc
cat << EOF >> .zshrc

# 设置语言防止乱码
export LANG=en_US.UTF-8

# 设置默认编辑器为 nano
export EDITOR=nano

# 自定义命令别名
alias sl="screen -ls"
alias sr="screen -R"
alias ss="screen -S"
alias docner="docker container"
alias docose="docker compose"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias ll="ls -alFh"
alias la="ls -A"
alias l="ls -CF"
alias grep="grep --color=auto"
alias df="df -h"
alias h="history"

# 显示当前目录下的子目录（不递归太深）
alias tdirs='tree -L 1 -d'

# 显示当前目录及子目录下的文件/目录总数统计
alias tstat='tree | tail -n 1'

# 推荐启用项
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':omz:update' mode auto
# zstyle ':omz:update' frequency 13

# 显示命令历史带时间戳
HIST_STAMPS="yyyy-mm-dd"

# 启用历史子串搜索（上下箭头）
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

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
sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search common-aliases)/' ~/.zshrc

# 配置 zsh-autosuggestions 插件颜色
echo "Configuring zsh-autosuggestions color..."
sed -i '' 's/fg=8/fg=cyan/' ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 更改默认 shell 为 zsh
echo "Changing default shell to zsh..."
chsh -s /bin/zsh

echo "Zsh installation and configuration complete."
