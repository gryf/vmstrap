#!/bin/bash

set -e

# 1. update
sudo yum -y install epel-release
sudo yum -y update

# rxvt-unicode-256color to have proper terminfo
PGS="bash-completion
     ccze
     ctags
     gcc
     gcc-c++
     git-review 
     htop
     jq 
     kernel-devel
     make
     mc
     ptpython2
     python-devel
     python-devel 
     python-flake8 
     python-ipython-console
     python-pip
     python2-apsw 
     python2-jedi 
     python2-mccabe 
     python2-pip
     python3-devel
     python3-pip
     python34-apsw 
     python36-devel 
     python36-jedi 
     python36-mccabe
     rxvt-unicode-256color
     the_silver_searcher 
     tmux
     vim"

# 2. install tools
sudo yum install -y $PGS

# 3. cleanup
sudo yum -y clean all

# 4. set default editor
echo 'export VISUAL="vim"' | sudo tee /etc/profile.d/vim.sh
echo 'export EDITOR="vim"' | sudo tee -a /etc/profile.d/vim.sh

# 5. install non-medieval version of vim (not working anymore)
# wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-common-8.1.0875-1.1.x86_64.rpm
# wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-enhanced-8.1.0875-1.1.x86_64.rpm
# wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-icons-8.1.0875-1.1.x86_64.rpm
# wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-minimal-8.1.0875-1.1.x86_64.rpm

# # this has to be run all at once, otherwise we will not have sudo for a
# # moment.
# sudo bash -c "yum -y remove vim-minimal vim-common vim-enhanced;
    # rpm -i vim-common-8.1.0875-1.1.x86_64.rpm \
    # vim-enhanced-8.1.0875-1.1.x86_64.rpm \
    # vim-icons-8.1.0875-1.1.x86_64.rpm \
    # vim-minimal-8.1.0875-1.1.x86_64.rpm;
    # yum -y install sudo"

# rm vim-common-8.1.0875-1.1.x86_64.rpm vim-enhanced-8.1.0875-1.1.x86_64.rpm \
    # vim-icons-8.1.0875-1.1.x86_64.rpm vim-minimal-8.1.0875-1.1.x86_64.rpm

# 6. install tools from pypi (only py3, no more latest setuptools for py2)
sudo pip3 install -U pip setuptools
installed_pkgs=$(pip list)
if echo "${installed_pkgs}" | grep -qv "rainbow"; then
    sudo pip install rainbow
    sudo pip3 install rainbow
fi

installed_pkgs=$(pip3 list)
for pkg in remote_pdb pdbpp; do
    if echo "${installed_pkgs}" | grep -qv "${pkg}"; then
        sudo pip3 install ${pkg}
    fi
done

# 7. copy configuration for bash, git, tmux
cp .bash_prompt ~/
cp .tmux.conf ~/
# v and y like vi in copy-mode
echo "bind -t vi-copy 'v' begin-selection" >> ~/.tmux.conf
echo "bind -t vi-copy 'y' copy-selection" >> ~/.tmux.conf
cp .gitconfig ~/
cp cleanup.sh ~/
echo '. ~/.bash_prompt' >> ~/.bashrc

# 8. get my vim config
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
