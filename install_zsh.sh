#!/bin/bash
apt update
apt upgrade -y
apt install wget git nano zsh -y

# INSTALL OH-MY-ZSH
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh
sh install.sh <<EOF
Y
EOF

# INSTALL zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# INSTALL zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# CONFIGURE
cd

echo '
export EDITOR=nano
alias sl="screen -ls"
alias sr="screen -R"
alias ss="screen -S"
alias docner="docker container"
alias docose="docker-compose"

ulimit -u 1048576
ulimit -n 1048576
ulimit -d unlimited
ulimit -m unlimited
ulimit -s unlimited
ulimit -t unlimited
ulimit -v unlimited

# 按两下 Esc 键往上条命令或者当前正在输入的命令前加上 "sudo"
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
bindkey "\e\e" sudo-command-line' >> .zshrc

# THEME
sed -i 's/robbyrussell/agnoster/' .zshrc

# PLUGINS
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' .zshrc

# zsh-autosuggestions
sed -i 's/fg=8/fg=cyan/' ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# change shell
chsh -s /bin/zsh