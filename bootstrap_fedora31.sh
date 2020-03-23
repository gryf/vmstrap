#!/bin/bash

set -e

# 1. update
sudo yum -y update

# rxvt-unicode-256color to have proper terminfo
PGS="bash-completion vim mc htop ctags git-review the_silver_searcher 
     rxvt-unicode-256color tmux jq gcc gcc-c++ kernel-devel make 
     python3-ipython ptpython3 python3-jedi python3-flake8 python3-mccabe 
     python3-pylint python3-apsw python2-pip python3-pip python3-devel 
     python2-devel python2"

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
cp cleanup.sh ~/
echo '. ~/.bash_prompt' >> ~/.bashrc
echo "alias ip='ip -c'" >> ~/.bashrc

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
cp kuryr.conf ~/devstack/local.conf
