#!/bin/bash

RED="$(tput bold)$(tput setaf 1)"
GRN="$(tput bold)$(tput setaf 2)"
YEL="$(tput bold)$(tput setaf 3)"
BLU="$(tput bold)$(tput setaf 4)"
NRM=`tput sgr0`

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
    local exit_on_error=0
    if [ "$1" = "-e" ]; then
        local exit_on_error=1
        shift
    fi
    p_blu -n "Check $1 ... "
    if hash $1 2>/dev/null; then
        echo `which $1`
        local error=0
    else
        echo "${RED}Not found$NRM"
        local error=1
    fi
    if [ "$error" = "1" ] && [ "$exit_on_error" = "1" ]; then
        exit 1
    fi
    return $error
}

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
    OS=`uname -s`
fi

echo $OS

# Check essential commands

LACK_CMD=
for prg in vim zsh git; do
    if ! check_program $prg; then
        LACK_CMD="$prg $LACK_CMD"
    fi
done

if [ "$LACK_CMD" != "" ]; then
    if prompt "Some essential commands are not found. Do you want to install them? (need sudo)"; then
        p_blu -n "Check package manager ... "

        if hash yum 2>/dev/null; then
            PKG=yum
        elif hash apt 2>/dev/null; then
            PKG=apt
        else
            echo "${RED}Not found${NRM}"
            exit 1
        fi
        echo $PKG

        pkg_update() {
            case $PKG in
            "yum") sudo $PKG -y update ;;
            "apt") sudo $PKG -y update
                   sudo $PKG -y upgrade ;;
            esac
        }

        pkg_install() {
            case $PKG in
            "yum") sudo $PKG -y install $* ;;
            "apt") sudo $PKG -y install $* ;;
            esac
        }

        p_blu Update packages ...
        pkg_update
        
        p_blu Install vim zsh git ...
        pkg_install $LACK_CMD
    else
        exit 1
    fi
fi

p_blu Install dotfiles ...
if [ ! -d ~/.dotfiles ]; then
    git clone https://github.com/Wing924/dotfiles.git ~/.dotfiles
else
    p_blu dotfiles already exists
fi
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
if [ ! -d ~/.vim/bundle/neobundle.vim ]; then
mkdir -p ~/.vim/bundle
    git clone https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
else
    p_blu NeoBundle already exists.
fi

if [[ "$SHELL" =~ ".*/zsh" ]]; then
    if hash chsh 2>/dev/null; then
        p_blu change to zsh
        chsh -s `which zsh`
    fi
fi
p_blu "DONE"
zsh
