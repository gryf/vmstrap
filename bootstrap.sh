#!/bin/bash

# Sometimes, it might be needed to force external network to cooperate:
# Network on Ubuntu server:
# paste it to the machine before running this script
#  sudo sh -c 'rm /etc/resolv.conf; echo "nameserver 1.1.1.1" > /etc/resolv.conf'
#  sudo sed -i -e "s/127.0.0.1 localhost/127.0.0.1 localhost ${HOSTNAME}/" /etc/hosts
#  sudo sh -c 'echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
#  sudo netplan apply

set -e

if command -v lsb_release 2>&1 > /dev/null; then
    DISTRO_ID=$(lsb_release -i | cut -f 2 -d ':' | xargs \
        | tr '[:upper:]' '[:lower:]')
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
    rlwrap
    silversearcher-ag)


rpm_based() {
    if [[ $DISTRO_ID == 'fedora' ]]; then
        PGS=(ptpython3
            python3-apsw
            python3-flake8
            python3-ipython
            python3-jedi
            python3-mccabe
            python3-pylint
            rxvt-unicode)
    elif [[ $DISTRO_ID == 'centos' ]]; then
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
             python36-mccabe
             rxvt-unicode-256color)
    fi

    # 1. update
    if [[ $DISTRO_ID == 'centos' ]]; then
        # install epel repository for centos
        sudo yum -y install epel-release
    fi
    sudo yum -y update

    # 2. install tools
    sudo yum install -y "${COMMON_PGS[@]}" "${COMMON_RPM[@]}" "${PGS[@]}"

    # 3. cleanup
    sudo yum -y clean all

    # 4. set default editor
    echo 'export VISUAL="vim"' | sudo tee /etc/profile.d/vim.sh
    echo 'export EDITOR="vim"' | sudo tee -a /etc/profile.d/vim.sh

    # 5. install tools from pypi
    if [[ $DISTRO_ID == 'fedora' ]]; then
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
    elif [[ $DISTRO_ID == 'centos' ]]; then
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
    fi

    # 6. copy configuration for bash, git, tmux
    common_conf
}

ubuntu() {
    case $DISTRO_R in
        '16.04')
            PGS=(ipython
                vim-gtk-py2)
            ;;
        '18.04')
            PGS=(ipython3
                python3-pip
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

    # 4. change alternatives
    sudo update-alternatives --set editor /usr/bin/vim.basic
    sudo update-alternatives \
        --install /usr/bin/python python /usr/bin/python3.6 10
    sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10

    # 5. install tools from pypi
    sudo pip install pip --upgrade
    sudo pip install remote_pdb rainbow pdbpp
    sudo pip3 install pip --upgrade
    sudo pip3 install remote_pdb rainbow pdbpp

    # 6. copy configuration for bash, git, tmux
    common_conf
}

common_conf() {
    cp .bash_prompt ~/
    cp .tmux.conf ~/
    # v and y like vi in copy-mode
    if [[ $DISTRO_ID == 'centos' ]]; then
        {
            echo "bind -t vi-copy 'v' begin-selection"
            echo "bind -t vi-copy 'y' copy-selection"
        } >> ~/.tmux.conf
    else
        {
            echo "bind-key -T copy-mode-vi 'v' send -X begin-selection"
            echo "bind-key -T copy-mode-vi 'y' send -X copy-selection"
        } >> ~/.tmux.conf
    fi
    cp .gitconfig ~/
    cp cleanup.sh ~/
    {
        echo 'source ~/.bash_prompt'
        echo "alias ip='ip -c'"
        echo "alias skctl='kubectl -n kube-system'"
        echo "alias pods='kubectl get pods -A -o wide'"
        echo "alias deploys='kubectl get deployments -A -o wide'"
        echo "source ~/devstack/openrc admin admin >/dev/null 2>/dev/null"
    } >> ~/.bashrc

    if [ ! -d ~/.vim ]; then
        git clone https://github.com/gryf/.vim ~/.vim
        # populate plugins
        vim -c ':PlugUpdate' -c ':qa!'
        # showmarks is a stubborn one
        mkdir ~/.vim/bundle/ShowMarks/doc
    fi

    # make current user sudo passwordless
    #if [ -z "$(sudo grep "${USER}" /etc/sudoers)" ]; then
    #    echo "${USER} ALL = (ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
    #fi

    # clone devstack
    git clone https://opendev.org/openstack/devstack ~/devstack
    cp kuryr.conf ~/devstack/local.conf
}

case $DISTRO_ID in
    "ubuntu")
        ubuntu
        ;;
    "centos")
        rpm_based
        ;;
    "fedora")  # Fedora 31
        rpm_based
        ;;
    *)
        echo "Distribution ${DISTRO_ID} not supported"
        ;;
esac
