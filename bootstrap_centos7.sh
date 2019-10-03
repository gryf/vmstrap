#!/bin/bash -x

# 1. update
sudo yum -i install epel-release
sudo yum -y update

# rxvt-unicode-256color to have proper terminfo
PGS="bash-completion vim mc python2-jedi python3.6-jedi htop python-flake8 python2-mccabe python36-mccabe ctags python2-pylint python2-pylint python36-pylint git-review the_silver_searcher python2-apsw python34-apsw ccze python2-pip python3-pip rxvt-unicode-256color tmux"

# 2. install tools
sudo yum install -y $PGS

# 3. cleanup
sudo yum -y clean all

# 4. set default editor
sudo cat <<EOF >>/etc/profile.d/vim.sh
export VISUAL="vim"
export EDITOR="vim"
EOF

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
vim -c ':PlugUpdate' -c ':qa!'
# showmarks is a stubborn one
mkdir ~/.vim/bundle/ShowMarks/doc

# make current user sudo passwordless
cat <<EOF >>/tmp/${USER}.sudo
${USER} ALL = (ALL) NOPASSWD: ALL
EOF
sudo mv /tmp/${USER}.sudo /etc/sudoers.d/

git clone clone https://opendev.org/openstack/devstack
