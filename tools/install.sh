#!/bin/bash

RED="$(tput bold)$(tput setaf 1)"
GRN="$(tput bold)$(tput setaf 2)"
YEL="$(tput bold)$(tput setaf 3)"
BLU="$(tput bold)$(tput setaf 4)"
NRM=`tput sgr0`

p_blu() {
    if [ "$1" = "-n" ]; then
        shift
        echo -n "${BLU}$*$NRM"
    else
        echo "${BLU}$*$NRM"
    fi
}

p_blu -n "Check OS ... "


if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then
    OS=Debian
elif [ -f /etc/redhat-release ]; then
    OS=`cat /etc/redhat-release | cut -d ' ' -f 1`
else
    echo "${RED}Unknown${NRM}"
    exit 1
fi

echo $OS

p_blu -n "Check package manager ... "

if which yum >/dev/null; then
    PKG=yum
elif which apt >/dev/null; then
    PKG=apt
else
    echo "${RED}Unknown${NRM}"
    exit 1
fi

pkg_update() {
    case $PKG in
        "yum") sudo $PKG -y update ;;
        "apt") sudo $PKG -y update
               sudo $PKG -y upgrade ;;
    esac
}

pkg_install() {
    case $PKG in
        "yum") sudo $PKG -y install $@ ;;
        "apt") sudo $PKG -y install $@ ;;
    esac
}

echo $PKG

prompt() {
    while :
    do
        echo -n "${GRN}$*${NRM} [y/n] "
        read yn
        case $yn in
            "y" | "Y") return 0 ;;
            "n" | "N") return 1 ;;
            *) echo "${RED}Please enter y/n${NRM}"
        esac
    done
}

check_program() {
    p_blu -n "Check $1 ... "
    if which $1 >/dev/null; then
        echo `which $1`
    else
        echo "${RED}Unknown$NRM"
        exit 1
    fi
}

if prompt "do you have root privileges?"; then
    p_blu Update packages ...
    pkg_update
    
    p_blu Install vim zsh git ...
    pkg_install vim git zsh
else
    check_program vim
    check_program zsh
    check_program git
fi

p_blu Install dotfiles
git clone https://github.com/Wing924/dotfiles.git ~/.dotfiles
if [ -f ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.pre-dotfile
fi
ln -sf ~/.dotfiles/templates/zshrc ~/.zshrc
if [ ! -f ~/.zshenv ]; then
    echo "# Please put your custom env here" > ~/.zshenv
fi
if [ -f ~/.vimrc ]; then
    mv ~/.vimrc ~/.vimrc.pre-dotfile
fi
ln -sf ~/.dotfiles/templates/vimrc ~/.vimrc

p_blu Install NeoBundle ...
mkdir -p ~/.vim/bundle
git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim

p_blu change to zsh
chsh -s `which zsh`
p_blu "DONE"
