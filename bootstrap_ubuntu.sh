#!/bin/bash -x

# 1. update
sudo apt update && sudo apt -y upgrade

lsb_release -cs 2>/dev/null | grep -q bionic
if [[ $? -eq 0 ]]; then
    PGS="ccze 
    exuberant-ctags
    flake8
    git-review
    htop 
    mc 
    python-apsw
    python-flake8
    python-jedi
    python-pip
    python3-flake8 
    python3-jedi 
    silversearcher-ag
    vim-gtk"
else
    PGS="ccze 
    exuberant-ctags 
    flake8 
    git-review 
    htop 
    mc 
    python-apsw 
    python-flake8 
    python-jedi 
    python-pip
    python3-flake8 
    python3-jedi
    silversearcher-ag 
    vim-gtk-py2"
fi

# 2. install tools
sudo apt install -y $PGS

# 3. cleanup
sudo apt-get autoremove -y && sudo apt-get autoclean -y

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

# clone devstack
git clone https://opendev.org/openstack/devstack ~/devstack
cp kuryr.conf ~/devstack/local.conf
