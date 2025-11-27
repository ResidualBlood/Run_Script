#!/bin/bash

# ==========================================
# 0. 基础辅助函数
# ==========================================

# 跨平台 sed
run_sed() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# 权限检查
ensure_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# ==========================================
# 1. 自动检测网络环境 (关键修改)
# ==========================================
echo "🔍 Detecting network environment..."

# 尝试连接 Google 来判断是否在墙外，超时时间 3秒
if curl -I -m 3 -s https://www.google.com >/dev/null; then
    IS_CN=false
    echo "🌍 Global network detected. Using GitHub."
    
    # GitHub 源地址
    OMZ_INSTALLER="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    GIT_HOST="https://github.com"
else
    IS_CN=true
    echo "🇨🇳 China network detected. Using Gitee Mirrors."
    
    # Gitee 镜像源地址
    OMZ_INSTALLER="https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh"
    GIT_HOST="https://gitee.com"
fi

# ==========================================
# 2. 依赖安装与语言修复 (Locale Fix)
# ==========================================
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
    brew install --cask font-fira-code font-fira-code-nerd-font 2>/dev/null || echo "Fonts might be already installed."

else
    echo "🟢 Detect Linux (Debian/Ubuntu)..."
    
    ensure_sudo apt update
    # 增加 locales 和 fonts-powerline 防止乱码
    ensure_sudo apt install -y wget git nano zsh lnav tree curl locales fonts-powerline

    echo "🔧 Fixing Locale (Solving 'character not in range' error)..."
    if [ -f /etc/locale.gen ]; then
        ensure_sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        ensure_sudo sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
        ensure_sudo locale-gen
        ensure_sudo update-locale LANG=en_US.UTF-8
        
        # 临时生效，防止脚本后续步骤报错
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
    fi
fi

# ==========================================
# 3. Oh My Zsh 安装
# ==========================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🚀 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL $OMZ_INSTALLER)" "" --unattended
else
    echo "✅ Oh My Zsh already installed."
fi

# ==========================================
# 4. 插件安装 (根据地区自动选择源)
# ==========================================
echo "📦 Installing zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

install_plugin() {
    local plugin_path=$1  # 例如: zsh-users/zsh-autosuggestions.git
    local plugin_name=$2
    local target_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"
    
    # 拼接最终 URL
    local full_url="${GIT_HOST}/${plugin_path}"

    if [ ! -d "$target_dir" ]; then
        echo "   -> Cloning ${plugin_name} from ${GIT_HOST}..."
        git clone "${full_url}" "${target_dir}"
    else
        echo "   -> ✅ Plugin ${plugin_name} already exists."
    fi
}

# 只需要传入路径后缀，前缀由脚本自动拼接
install_plugin "zsh-users/zsh-autosuggestions.git" "zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting.git" "zsh-syntax-highlighting"
install_plugin "zsh-users/zsh-history-substring-search.git" "zsh-history-substring-search"

# ==========================================
# 5. 配置 .zshrc
# ==========================================
echo "⚙️  Configuring .zshrc..."
ZSHRC_FILE="$HOME/.zshrc"

# 修改主题
if ! grep -q 'ZSH_THEME="agnoster"' "$ZSHRC_FILE"; then
    run_sed 's/^ZSH_THEME="robbyrussell"$/ZSH_THEME="agnoster"/' "$ZSHRC_FILE"
fi

# 启用插件
if grep -q '^plugins=(git)$' "$ZSHRC_FILE"; then
    run_sed 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search common-aliases)/' "$ZSHRC_FILE"
fi

# ==========================================
# 6. 追加自定义配置
# ==========================================
START_MARKER="# --- CUSTOM CONFIG START ---"
if grep -q "$START_MARKER" "$ZSHRC_FILE"; then
    echo "✅ Custom configurations already exist."
else
    echo "📝 Appending custom configurations..."
    cat << 'EOF' >> "$ZSHRC_FILE"

# --- CUSTOM CONFIG START ---

# Locale fix for Zsh theme
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
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

# History
HIST_STAMPS="yyyy-mm-dd"

# Key bindings for history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Intelligent Sudo (Press Esc twice)
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

# --- Linux ulimit settings ---
if [[ "$(uname)" != "Darwin" ]]; then
    if ! grep -q "ulimit -u" "$ZSHRC_FILE"; then
        echo "🔧 Setting ulimit restrictions for Linux..."
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
echo "👉 Run this command to switch shell: chsh -s \$(which zsh)"
echo "👉 Then log out and log back in."
