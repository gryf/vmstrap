#!/bin/bash

set -e

if command -v lsb_release 2>&1 > /dev/null; then
    DISTRO_ID=$(lsb_release -i | cut -f 2 -d ':' | tr '[:upper:]' '[:lower:]')
    DISTRO_R=$(lsb_release -r | awk '{print $2}')
else
    if [[ -e /etc/redhat-release ]]; then
        DISTRO_ID=$(cut -f 1 -d ' ' /etc/redhat-release | \
            tr '[:upper:]' '[:lower:]')
        if [[ $DISTRO_ID =~ centos ]]; then
            # CentOS Linux release 7.6.1810 (Core)
            # We want only major, here: 7
            DISTRO_R=$(cut -f 4 -d ' ' /etc/redhat-release | cut -f 1 -d '.')
        elif [[ $DISTRO_ID =~ fedora ]]; then 
            # Fedora release 32 (Thirty Two)
            DISTRO_R=$(cut -f 3 -d ' ' /etc/redhat-release)
        fi
    fi
fi

COMMON_PGS=(ccze
    git-review 
    htop
    jq
    mc
    tmux)

COMMON_RPM=(bash-completion
    ctags
    gcc
    gcc-c++
    kernel-devel
    make
    python3-devel
    python3-pip
    rxvt-unicode-256color
    the_silver_searcher
    vim)

COMMON_DEB=(exuberant-ctags
    flake8
    python-apsw
    python-flake8
    python-jedi
    python-pip
    python3-flake8
    python3-jedi
    silversearcher-ag)

centos7() {
    # 1. update
    sudo yum -y install epel-release
    sudo yum -y update

    # rxvt-unicode-256color to have proper terminfo
    PGS=(ptpython2
         python-devel
         python-flake8 
         python-ipython-console
         python-pip
         python2-apsw 
         python2-jedi 
         python2-mccabe 
         python2-pip
         python34-apsw 
         python36-jedi 
         python36-mccabe)

    # 2. install tools
    sudo yum install -y "${COMMON_PGS[@]}" "${COMMON_RPM[@]}" "${PGS[@]}"

    # 3. cleanup
    sudo yum -y clean all

    # 4. set default editor
    echo 'export visual="vim"' | sudo tee /etc/profile.d/vim.sh
    echo 'export editor="vim"' | sudo tee -a /etc/profile.d/vim.sh

    # 5. install non-medieval version of vim (not working anymore)
    # wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/centos_7/x86_64/vim-common-8.1.0875-1.1.x86_64.rpm
    # wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/centos_7/x86_64/vim-enhanced-8.1.0875-1.1.x86_64.rpm
    # wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/centos_7/x86_64/vim-icons-8.1.0875-1.1.x86_64.rpm
    # wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/fusion809/centos_7/x86_64/vim-minimal-8.1.0875-1.1.x86_64.rpm

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
    sudo pip3 install -u pip setuptools
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
    echo "alias ip='ip -c'" >> ~/.bashrc

    # 8. get my vim config
    if [ ! -d ~/.vim ]; then
        git clone https://github.com/gryf/.vim ~/.vim
        # populate plugins
        vim -c ':plugupdate' -c ':qa!'
        # showmarks is a stubborn one
        mkdir ~/.vim/bundle/showmarks/doc
    fi

    # make current user sudo passwordless
    if [ -z "$(sudo grep "${user}" /etc/sudoers)" ]; then
        echo "${user} all = (all) nopasswd: all" | sudo tee -a /etc/sudoers
    fi

    # clone devstack
    git clone https://opendev.org/openstack/devstack ~/devstack
    cp kuryr.conf ~/devstack/local.conf
}

fedora() {
    # fedora 31
    # 1. update
    sudo yum -y update

    # rxvt-unicode-256color to have proper terminfo

    PGS=(ptpython3
        python2
        python2-devel
        python2-pip
        python3-apsw
        python3-flake8
        python3-ipython
        python3-jedi
        python3-mccabe
        python3-pylint)

    # 2. install tools
    sudo yum install -y "${COMMON_PGS[@]}" "${COMMON_RPM[@]}" "${PGS[@]}"

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
}

ubuntu() {
    # Sometimes, it might be needed to force external network to cooperate:
    # 0. network. paste it to the machine before running this script
    # sudo sh -c 'rm /etc/resolv.conf; echo "nameserver 1.1.1.1" > /etc/resolv.conf'
    # sudo sed -i -e "s/127.0.0.1 localhost/127.0.0.1 localhost ${HOSTNAME}/" /etc/hosts
    # sudo sh -c 'echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
    # sudo netplan apply
    # git clone https://github.com/gryf/vmstrap
    # cd vmstrap

    case $DISTRO_R in
        '16.04')
            PGS=(ipython
                vim-gtk-py2)
            ;;
        '18.04')
            PGS=(ipython3
                tmate
                vim-gtk)
            ;;
        '20.04')
            echo "20.04 is not yet supported"
            exit 1
            ;;
        *)
            echo "Unsupported Ubuntu version: ${DISTRO_R}"
            ;;
    esac

    # 1. update
    sudo apt update && sudo apt -y upgrade

    # 2. install tools
    sudo apt install -y "${COMMON_PGS[@]}" "${COMMON_DEB[@]}" "${PGS[@]}"

    # 3. cleanup
    sudo apt-get autoremove -y && sudo apt-get autoclean -y

    # 4. set default editor
    sudo update-alternatives --set editor /usr/bin/vim.gtk-py2

    # 5. install tools from pypi
    sudo pip install pip --upgrade
    sudo pip install remote_pdb rainbow

    # 6. copy configuration for bash, git, tmux
    cp .bash_prompt ~/
    cp .tmux.conf ~/
    # v and y like vi in copy-mode
    {
        echo "bind-key -T copy-mode-vi 'v' send -X begin-selection"
        echo "bind-key -T copy-mode-vi 'y' send -X copy-selection"
    } >> ~/.tmux.conf
    cp .gitconfig ~/
    cp cleanup.sh ~/
    {
        echo 'source ~/.bash_prompt'
        echo "alias ip='ip -c'"
        echo "alias skctl='kubectl -n kube-system'"
        echo "source ~/devstack/openrc admin admin >/dev/null 2>/dev/null"
    } >> ~/.bashrc

    # 7. get my vim config
    git clone https://github.com/gryf/.vim ~/.vim
    # populate plugins
    vim -c ':PlugUpdate' -c ':qa!'
    # showmarks is a stubborn one
    mkdir ~/.vim/bundle/ShowMarks/doc

    # clone devstack
    git clone https://opendev.org/openstack/devstack ~/devstack
    cp kuryr.conf ~/devstack/local.conf
}

case $DISTRO_ID in
    "ubuntu")
        ubuntu
        ;;
    "centos")
        centos7
        ;;
    "fedora")
        fedora
        ;;
    *)
        echo Distribution ${DISTRO_ID} not supported
        ;;
esac
