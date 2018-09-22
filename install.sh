#!/usr/bin/env bash

# debug
set -x

ROOT_PATH_Q=$(cd `dirname $0`; pwd) 

ln -sf $ROOT_PATH_Q/.vimrc.base $HOME/.vimrc 
