###
 # @Author       : ResidualBlood
 # @Date         : 2022-01-14 09:53:15
 # @LastEditors  : ResidualBlood
 # @LastEditTime : 2022-01-14 09:54:37
 # @Description  : 
 # @FilePath     : /zsh.sh
### 
#!/bin/bash
apt update
apt upgrade -y
apt install wget git nano zsh -y
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
