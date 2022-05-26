#!/bin/bash
sudo apt-get update
sudo apt-get -y install zsh
touch ~/.zshrc
sudo usermod -s /usr/bin/zsh $(whoami)
sudo apt-get -y install powerline fonts-powerline
sudo apt-get -y install zsh-theme-powerlevel9k
sudo apt-get -y install zsh-syntax-highlighting
yes Y | sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo "source /usr/share/powerlevel9k/powerlevel9k.zsh-theme" >> ~/.zshrc
echo "source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc