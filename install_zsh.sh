#!/bin/bash

# --- 错误修正 1: `sed` 兼容性 ---
# 根据操作系统设置 'sed -i' (原地替换) 命令的正确语法
# macOS (BSD sed) 需要一个空字符串 '' 作为 -i 的参数
# Debian (GNU sed) 不需要
local sed_inplace='sed -i'
if [[ "$(uname)" == "Darwin" ]]; then
    sed_inplace="sed -i ''"
fi

# 判断操作系统并执行
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: 使用 Homebrew 安装必要软件
    echo "Installing dependencies for macOS..."
    if ! command -v brew &>/dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    
    # --- 错误修正 2: Homebrew 包名 ---
    # 移除了 'sudo' (系统自带)
    # 为字体添加了 '--cask'
    echo "Installing packages: wget, git, nano, zsh, lnav, tree"
    brew install wget git nano zsh lnav tree
    echo "Installing fonts: fira-code, fira-code-nerd-font"
    brew install --cask font-fira-code font-fira-code-nerd-font

else
    # --- 逻辑改进: 假定为 Debian ---
    # 注意：这个 'else' 块仍然假定非 macOS 就是 Debian。
    # 更健壮的脚本会使用 'elif [ -f /etc/debian_version ]; then'
    echo "Installing dependencies for Debian..."
    
    # --- 错误修正 3: Debian 权限和包名 ---
    # 为所有 'apt' 命令添加 'sudo'
    # 将 'tree-y' 修正为 'tree -y'
    # 添加 'curl' 以便统一使用 OMZ 的 curl 安装方式
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y sudo wget git nano zsh lnav tree curl
fi

# --- 错误修正 4: Oh My Zsh (OMZ) 安装 ---
# 逻辑顺序修正：必须先安装 OMZ，它会创建 .zshrc，然后我们才能修改它。
# 统一使用 curl 和 '--unattended' 标志进行非交互式安装。
# 这会安装 OMZ 并自动将 zsh 设置为默认 shell（如果它有权限），无需手动 'chsh'。
# 使用了新的官方 OMZ 仓库 URL。
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed. Skipping installation."
fi

# 安装 zsh 插件（这部分原脚本是正确的）
echo "Installing zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/history-substring-search

# 配置 .zshrc 文件
echo "Configuring .zshrc..."

# --- 错误修正 1 (应用): 使用 $sed_inplace ---
# 更改默认主题为 agnoster
# 使用更安全的 sed 表达式，只匹配 ZSH_THEME 这一行
echo "Changing theme to agnoster..."
$sed_inplace 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="agnoster"/' ~/.zshrc

# --- 错误修正 1 (应用): 使用 $sed_inplace ---
# 配置插件
# 使用更安全的 sed 表达式，只匹配 plugins= 这一行
echo "Configuring plugins..."
$sed_inplace 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search common-aliases)/' ~/.zshrc

# --- 逻辑顺序修正: 在 OMZ 安装后追加配置 ---
echo "Appending custom configurations to .zshrc..."
cd ~

# 添加自定义配置到 .zshrc
cat << 'EOF' >> ~/.zshrc

# --- 自定义配置开始 ---

# 设置语言防止乱码
export LANG=en_US.UTF-8

# 设置默认编辑器为 nano
export EDITOR=nano

# --- 错误修正 5: zsh-autosuggestions 颜色 ---
# 不再修改插件文件，而是使用 .zshrc 变量来设置
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan'

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
alias tdirs='tree -L 1 -d'
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
# 注意：在 'cat << EOF' 中（没有引号），$ 必须被转义为 \$
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# --- 自定义配置结束 ---
EOF
# 注意：上面的 'EOF' 使用了单引号，这样 cat 块内的 $BUFFER 等变量就无需转义，更清晰。

# --- 逻辑顺序修正: 在 OMZ 安装后追加 Debian 特定的 ulimit 设置 ---
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Setting ulimit restrictions for Debian..."
    cat << EOF >> ~/.zshrc

# 设置 ulimit 限制 (Debian-specific)
ulimit -u 1048576
ulimit -n 1048576
ulimit -d unlimited
ulimit -m unlimited
ulimit -s unlimited
ulimit -t unlimited
ulimit -v unlimited
EOF
fi

# --- 错误修正 6: 移除多余的 'chsh' ---
# OMZ 的 '--unattended' 安装标志已经处理了更改默认 shell。

echo "Zsh installation and configuration complete."
echo "请关闭并重新打开你的终端，或者运行 'exec zsh' 来应用更改。"
