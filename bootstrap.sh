#!/bin/bash -x

# 1. update
sudo apt update && sudo apt -y upgrade

lsb_release -cs 2>/dev/null | grep -q bionic
if [[ $? -eq 0 ]]; then
    PGS="vim-gtk mc python-jedi python3-jedi htop python-flake8 python3-flake8 exuberant-ctags pylint flake8 pylint3 git-review silversearcher-ag python-apsw ccze python-pip"
else
    PGS="vim-gtk-py2 mc python-jedi python3-jedi htop python-flake8 python3-flake8 exuberant-ctags pylint flake8 pylint3 git-review silversearcher-ag python-apsw ccze python-pip"
fi

# 2. install tools
sudo apt install -y $PGS

# 3. cleanup
sudo apt-get autoremove && sudo apt-get autoclean

# 4. set default editor
sudo update-alternatives --set editor /usr/bin/vim.gtk-py2

# 5. install tools from pypi
sudo pip install pip --upgrade
sudo pip install remote_pdb rainbow

# 6. copy configuration for bash, git, tmux
sudo cp .bash_prompt ~/
sudo cp .tmux.conf ~/
sudo cp .gitconfig ~/
echo '. ~/.bash_prompt' >> ~/.bashrc

# 7. get my vim config
git clone https://github.com/gryf/.vim ~/.vim
# populate plugins
vim -c ':PlugUpdate' -c ':qa!' ${STACKUSER}
# showmarks is a stubborn one
mkdir ~/.vim/bundle/ShowMarks/doc ${STACKUSER}
