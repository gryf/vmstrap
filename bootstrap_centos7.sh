#!/bin/bash

set -e

# 1. update
sudo yum -y install epel-release
sudo yum -y update

# rxvt-unicode-256color to have proper terminfo
PGS="bash-completion vim mc python2-jedi python3.6-jedi htop python-flake8
     python2-mccabe python36-mccabe ctags python2-pylint python2-pylint
     python36-pylint git-review the_silver_searcher python2-apsw
     python34-apsw ccze python-pip python2-pip python3-pip
     rxvt-unicode-256color tmux jq python-ipython-console ptpython2
     gcc gcc-c++ kernel-devel make python36-devel python-devel
     python27-python-devel python3-devel"

# 2. install tools
sudo yum install -y $PGS

# 3. cleanup
sudo yum -y clean all

# 4. set default editor
echo 'export VISUAL="vim"' | sudo tee /etc/profile.d/vim.sh
echo 'export EDITOR="vim"' | sudo tee -a /etc/profile.d/vim.sh

# 5. install non-medieval version of vim
wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-common-8.1.0875-1.1.x86_64.rpm
wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-enhanced-8.1.0875-1.1.x86_64.rpm
wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-icons-8.1.0875-1.1.x86_64.rpm
wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/CentOS_7/x86_64/vim-minimal-8.1.0875-1.1.x86_64.rpm

# this has to be run all at once, otherwise we will not have sudo for a
# moment.
sudo bash -c "yum -y remove vim-minimal vim-common vim-enhanced;
    rpm -i vim-common-8.1.0875-1.1.x86_64.rpm \
    vim-enhanced-8.1.0875-1.1.x86_64.rpm \
    vim-icons-8.1.0875-1.1.x86_64.rpm \
    vim-minimal-8.1.0875-1.1.x86_64.rpm;
    yum -y install sudo"

rm vim-common-8.1.0875-1.1.x86_64.rpm vim-enhanced-8.1.0875-1.1.x86_64.rpm \
    vim-icons-8.1.0875-1.1.x86_64.rpm vim-minimal-8.1.0875-1.1.x86_64.rpm

# 6. install tools from pypi
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

# 7. copy configuration for bash, git, tmux
sudo cp .bash_prompt ~/
sudo cp .tmux.conf ~/
sudo cp .gitconfig ~/
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
