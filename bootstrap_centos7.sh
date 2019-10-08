#!/bin/bash

set -e

# 1. update
sudo yum -y install epel-release
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
sudo pip install -U pip setuptools
installed_pkgs=$(pip list)
pkgs_to_install=
for pkg in remote_pdb pdbpp rainbow; do
    if echo "${installed_pkgs}" | grep -qv "${pkg}"; then
        pkgs_to_install="${pkgs_to_install} ${pkg}"
    fi
done

if [ -n "${pkgs_to_install}" ]; then
    sudo pip install ${pkgs_to_install}
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
