#!/usr/bin/env bash

# debug
set -x

ROOT_PATH_Q=$(cd `dirname $0`; pwd) 

if [ -e $HOME/.vimrc ]; then
    cp -fp $HOME/.vimrc{,.bak_by_quokka_vim}
fi

ln -sf $ROOT_PATH_Q/.vimrc.base $HOME/.vimrc 
