#!/bin/bash

# Sometimes, it might be needed to force external network to cooperate:
# Network on Ubuntu server:
# paste it to the machine before running this script
#  sudo sh -c 'rm /etc/resolv.conf; echo "nameserver 1.1.1.1" > /etc/resolv.conf'
#  sudo sed -i -e "s/127.0.0.1 localhost/127.0.0.1 localhost ${HOSTNAME}/" /etc/hosts
#  sudo sh -c 'echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
#  sudo netplan apply

set -e

DIR=$(dirname $BASH_SOURCE[0])


if command -v lsb_release > /dev/null 2>&1; then
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
    vim
    wget)

COMMON_DEB=(exuberant-ctags
    flake8
    inotify-tools
    python3-flake8
    python3-jedi
    rlwrap
    silversearcher-ag)


function rpm_based {
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

    if [ "${DONT_INSTALL_PKGS}" != "1" ]; then
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

        # 4. install tools from pypi
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
    fi

    # 5. set default editor
    echo 'export VISUAL="vim"' | sudo tee /etc/profile.d/vim.sh
    echo 'export EDITOR="vim"' | sudo tee -a /etc/profile.d/vim.sh

    # 6. copy configuration for bash, git, tmux
    common_conf
}

function ubuntu {
    case $DISTRO_R in
        '16.04')
            PGS=(ipython
                python-flake8
                python-jedi
                python-pip
                vim-gtk-py2)
            ;;
        '18.04')
            PGS=(ipython3
                python-flake8
                python-jedi
                python-pip
                python3-pip
                tmate
                vim-gtk)
            ;;
        '20.04')
            PGS=(ipython3
                python3-pip
                tmate
                vim-nox)
            ;;
        *)
            echo "Unsupported Ubuntu version: ${DISTRO_R}"
            ;;
    esac

    ## 0. hold - those doesn't matter, since we never get to the point when
    ## reboot is needed.
    #sudo apt-mark hold linux-headers-generic linux-headers-virtual \
    #    linux-image-virtual linux-virtual cryptsetup-initramfs \
    #    busybox-initramfs cloud-init initramfs-tools

    if [ "${DONT_INSTALL_PKGS}" != "1" ]; then

        # 1. update
        sudo apt update && sudo apt -y upgrade

        # 2. install tools
        sudo apt install -y "${COMMON_PGS[@]}" "${COMMON_DEB[@]}" "${PGS[@]}"

        # 3. cleanup
        sudo apt-get autoremove -y && sudo apt-get autoclean -y

        # 4.
        case $DISTRO_R in
            '16.04')
                sudo apt install -y python-apsw
                sudo pip install pip --upgrade
                sudo pip install remote_pdb rainbow pdbpp
                ;;
            '18.04')
                sudo apt install -y python-apsw
                sudo pip3 install pip --upgrade
                sudo pip3 install remote_pdb rainbow pdbpp
                ;;
            '20.04')
                sudo apt install -y python-apsw
                sudo pip3 install remote_pdb rainbow pdbpp
                ;;
            '22.04')
                sudo apt install -y python3-apsw
                sudo pip3 install remote_pdb rainbow pdbpp
                ;;
        esac
    fi

    # 5. change alternatives
    case $DISTRO_R in
        '18.04')
            sudo update-alternatives \
                --install /usr/bin/python python /usr/bin/python3.6 10
            ;;
        '20.04')
            sudo update-alternatives \
                --install /usr/bin/python python /usr/bin/python3.8 10
            # 5.
            ;;
        '22.04')
            sudo update-alternatives \
                --install /usr/bin/python python /usr/bin/python3.10 10
            ;;
    esac

    sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10
    sudo update-alternatives --set editor /usr/bin/vim.basic

    # 6. copy configuration for bash, git, tmux
    common_conf
}

function tmux_conf {
    tmux_ver=$(tmux -V|cut -f 2 -d ' ')
    if [ -z "${tmux_ver}" ]; then
        return
    fi
    major=${tmux_ver%.*}
    minor=${tmux_ver#*.}

    # some colors
    if [[ $major -lt 3 ]]; then
        {
            # tmux < 3.x
            echo "setw -g window-status-current-bg colour8"
            echo "setw -g window-status-current-fg colour15"
            echo "setw -g window-status-current-attr bold"
            echo "set -g pane-active-border-bg default"
            echo "set -g pane-active-border-fg brightyellow"
            echo "set -g pane-border-fg green"
            echo "set -g message-fg white"
            echo "set -g message-bg black"
        } >> ~/.tmux.conf
    else
        {
            echo 'setw -g window-status-current-style "bg=colour8 '`
                `'fg=colour15 bold"'
            echo "set -g pane-border-style fg=green"
            echo 'set -g pane-active-border-style "bg=default fg=brightyellow"'
            echo 'set -g message-style "fg=white bg=black"'
        } >> ~/.tmux.conf
    fi

    if [[ ! ( $major == 1 && $minor -le 6 ) ]]; then
        {
            echo ""
            echo "# renumber windows when a window is closed"
            echo "set -g renumber-windows on"
        } >> ~/.tmux.conf
    fi

    # vi-like selection
    if [[ $major -eq 1 || $major -eq 2 && $minor -lt 6 ]]; then
        {
            # tmux ~ 1.6/1.7/1.8/<2.6
            echo
            echo "# v and y like vi in copy-mode"
            echo "bind -t vi-copy 'v' begin-selection"
            echo "bind -t vi-copy 'y' copy-selection"
        } >> ~/.tmux.conf
    else
        {
            # tmux >= 2.6
            echo
            echo "# v and y like vi in copy-mode"
            echo "bind-key -T copy-mode-vi 'v' send -X begin-selection"
            echo "bind-key -T copy-mode-vi 'y' send -X copy-selection"
        } >> ~/.tmux.conf
    fi
}

function common_conf {
    cp "${DIR}/.bash_prompt" ~/
    cp "${DIR}/.tmux.conf" ~/

    tmux_conf

    cp "${DIR}/.gitconfig" ~/
    cp "${DIR}/cleanup.sh" ~/

    {
        echo 'source ~/.bash_prompt'
        echo "alias ipc='ip -c'"
        echo "alias kss='kubectl -n kube-system'"
        echo "alias pods='kubectl get pods -A -o wide'"
        echo "alias deploys='kubectl get deployments -A -o wide'"
        echo "#if which openstack 2>/dev/null >/dev/null; then"
        echo "#    source ~/devstack/openrc admin admin >/dev/null 2>/dev/null"
        echo "#fi"
        echo "if which kubectl 2>/dev/null >/dev/null; then"
        echo "    source <(kubectl completion bash)"
        echo "fi"
    } >> ~/.bashrc

    if [ ! -d ~/.vim ]; then
        pushd $HOME
        wget "https://github.com/gryf/.vim/releases/download/0.0.1/vim.tar.xz"
        tar xf vim.tar.xz
        rm vim.tar.xz
        popd
    fi

    # get k9s
    wget "https://github.com/derailed/k9s/releases/download/"`
        `"v0.24.7/k9s_Linux_x86_64.tar.gz"
    tar xf k9s_Linux_x86_64.tar.gz --directory ~/ k9s
    rm k9s_Linux_x86_64.tar.gz
}

function _showusage {
    echo "Usage: $(basename $1) [OPTIONS]"
    echo "Configure system and optionally install a set of packages."
    echo
    echo Where OPTIONS are:
    echo "  -h        This help."
    echo "  -c        Do the config only, don't install anything"
}

function main {
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

}

# react on -h or --help
while getopts ":heicbdgvxsauzr" optchar; do
    case "${optchar}" in
        h)
            _showusage "$0"
            exit 0
            ;;
        c)
            DONT_INSTALL_PKGS=1
            ;;
        *)
            echo Invalid argument "$1"
            _showusage "$0"
            exit 1
            ;;
    esac
done

main
