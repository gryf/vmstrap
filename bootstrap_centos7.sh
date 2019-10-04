#!/bin/bash -x

# 1. update
sudo yum -i install epel-release
sudo yum -y update

# rxvt-unicode-256color to have proper terminfo
PGS="bash-completion vim mc python2-jedi python3.6-jedi htop python-flake8 python2-mccabe python36-mccabe ctags python2-pylint python2-pylint python36-pylint git-review the_silver_searcher python2-apsw python34-apsw ccze python-pip python2-pip python3-pip rxvt-unicode-256color tmux jq"

# 2. install tools
sudo yum install -y $PGS

# 3. cleanup
sudo yum -y clean all

# 4. set default editor
echo 'export VISUAL="vim"' | sudo tee /etc/profile.d/vim.sh
echo 'export EDITOR="vim"' | sudo tee -a /etc/profile.d/vim.sh


# 5. install tools from pypi
if $(pip list |grep -e rainbow -e remote-pdb|wc -l|grep -qv 2); then
    sudo pip install pip --upgrade
    sudo pip install remote_pdb rainbow
    sudo pip install -U setuptools
fi

# 6. copy configuration for bash, git, tmux
sudo cp .bash_prompt ~/
sudo cp .tmux.conf ~/
sudo cp .gitconfig ~/
echo '. ~/.bash_prompt' >> ~/.bashrc

# 7. get my vim config
if [ ! -d ~/.vim ]; then
    git clone https://github.com/gryf/.vim ~/.vim
    # populate plugins
    vim -c ':PlugUpdate' -c ':qa!'
    # showmarks is a stubborn one
    mkdir ~/.vim/bundle/ShowMarks/doc
fi

# make current user sudo passwordless
if [ -z "$(sudo grep "${USER}" /etc/sudoers)" ]; then
    echo "${USER} ALL = (ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
fi

# clone devstack
git clone https://opendev.org/openstack/devstack ~/devstack
