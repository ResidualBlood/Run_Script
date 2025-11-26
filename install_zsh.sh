#!/bin/bash

# --- 辅助函数：跨平台 SED ---
# 使用函数代替变量，避免 shell 分词问题
run_sed() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# --- 辅助函数：判断是否需要 sudo ---
# 如果是 root 用户，则不需要 sudo
ensure_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# --- 操作系统判断与依赖安装 ---
if [[ "$(uname)" == "Darwin" ]]; then
    echo "🔵 Detect macOS..."
    
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    
    echo "Installing packages..."
    brew install wget git nano zsh lnav tree
    
    echo "Installing fonts..."
    # 尝试安装字体，忽略错误（防止已安装报错）
    brew install --cask font-fira-code font-fira-code-nerd-font 2>/dev/null || echo "Fonts might be already installed."

else
    # 假定为 Debian/Ubuntu 系列
    echo "🟢 Detect Linux (Debian/Ubuntu)..."
    
    ensure_sudo apt update
    # 移除 -y 的 upgrade，避免耗时过长，视需求而定
    # ensure_sudo apt upgrade -y 
    ensure_sudo apt install -y wget git nano zsh lnav tree curl
fi

# --- Oh My Zsh 安装 ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    # 移除最后的 "" 参数，--unattended 足够了
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "✅ Oh My Zsh already installed."
fi

# --- 插件安装 (增加存在性检查) ---
echo "Installing zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

install_plugin() {
    local repo_url=$1
    local plugin_name=$(basename $repo_url .git)
    local target_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"
    
    if [ ! -d "$target_dir" ]; then
        echo "Cloning ${plugin_name}..."
        git clone "${repo_url}" "${target_dir}"
    else
        echo "✅ Plugin ${plugin_name} already exists. Skipping."
        # 可选：如果存在则更新
        # git -C "${target_dir}" pull
    fi
}

install_plugin "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "https://github.com/zsh-users/zsh-history-substring-search"

# --- 配置 .zshrc ---
echo "Configuring .zshrc..."
ZSHRC_FILE="$HOME/.zshrc"

# 1. 修改主题 (使用 run_sed 函数)
echo "Setting theme to agnoster..."
# 先判断是否已经是 agnoster，避免重复修改
if ! grep -q 'ZSH_THEME="agnoster"' "$ZSHRC_FILE"; then
    run_sed 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="agnoster"/' "$ZSHRC_FILE"
fi

# 2. 配置插件
echo "Enabling plugins..."
# 只有当 plugins=(git) 存在时才替换，防止重复追加
if grep -q '^plugins=(git)$' "$ZSHRC_FILE"; then
    run_sed 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search common-aliases)/' "$ZSHRC_FILE"
fi

# --- 追加自定义配置 ---
# 使用标记行来防止重复追加内容
START_MARKER="# --- CUSTOM CONFIG START ---"
if grep -q "$START_MARKER" "$ZSHRC_FILE"; then
    echo "✅ Custom configurations already exist in .zshrc."
else
    echo "Appending custom configurations..."
    cat << 'EOF' >> "$ZSHRC_FILE"

# --- CUSTOM CONFIG START ---

export LANG=en_US.UTF-8
export EDITOR=nano

# zsh-autosuggestions color
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan'

# Aliases
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

# OMZ Settings
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':omz:update' mode auto

# History Settings
HIST_STAMPS="yyyy-mm-dd"

# Key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Intelligent Sudo (Esc+Esc)
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

# --- CUSTOM CONFIG END ---
EOF
fi

# --- Debian ulimit 设置 ---
if [[ "$(uname)" != "Darwin" ]]; then
    if ! grep -q "ulimit -u" "$ZSHRC_FILE"; then
        echo "Setting ulimit restrictions for Debian..."
        cat << EOF >> "$ZSHRC_FILE"

# ulimit settings
ulimit -u 1048576
ulimit -n 1048576
ulimit -d unlimited
ulimit -m unlimited
ulimit -s unlimited
ulimit -t unlimited
ulimit -v unlimited
EOF
    fi
fi

echo "🎉 Installation complete!"
echo "Please restart your terminal or run: exec zsh"
