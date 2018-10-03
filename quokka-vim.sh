#!/usr/bin/env bash

# turn on debug mode
# set -x
# flag for debug mode (true/false)
is_debug=true

# quokka-vim root path
Q_ROOT_PATH=$(cd `dirname $0`; pwd)

function debug_print()
{
    local msg=$1
    [ "$is_debug" = "true" ] && {
        echo $msg
    }
}

function print_help_info()
{
    echo
    echo "Usage: $(basename $0) -[behiu]"
    echo
    echo "Options:"
    echo "  -b    specify a base vimrc config"
    echo "  -e    specify a extended vimrc config"
    echo "  -h    display this help and exit"
    echo "  -i    install vimrc config"
    echo "  -u    uninstall vimrc config"
    echo
    exit 1
}

function vim_requirement_setup()
{
    # Vi IMproved - enhanced vi editor
    # YouCompleteMe requires Vim 7.4.1578+
    sudo apt-get install -y vim
    # build tag file indexes of source code definitions
    sudo apt-get install -y exuberant-ctags
    # powerline symbols font
    sudo apt-get install -y fonts-powerline
    # requirements for Ycm
    sudo apt-get install -y build-essential cmake python3-dev
}

# set up Vundle as vim plugin manager
function vim_plugin_manager_setup()
{
    local repo_vundle_vim=https://github.com/VundleVim/Vundle.vim.git
    mkdir -p $Q_ROOT_PATH/.vim/bundle
    git clone $repo_vundle_vim $Q_ROOT_PATH/.vim/bundle/Vundle.vim
}

# install plugins and quit
function vim_plugin_install()
{
    # vim -c "PluginInstall" -c "q" -c "q"
    vim +PluginInstall +qall
}

# compiling YCM with semantic support for C-family languages
function ycm_compile_with_c()
{
    cd $Q_ROOT_PATH/.vim/bundle/YouCompleteMe
    python3 install.py -clang-completer
    cd -
}

function do_config_action_backup()
{
    # backup: .vimrc -> .vimrc.backup_by_quokka_vim
    local fname="$1"
    local fname_backup="${fname}.backup_by_quokka_vim"
    [ -e $fname ] && mv $fname $fname_backup
}

function do_config_action_restore()
{
    # restore: .vimrc.backup_by_quokka_vim -> .vimrc
    local fname="$1"
    local fname_backup="${fname}.backup_by_quokka_vim"
    if [ -e $fname_backup ]; then
        mv $fname_backup $fname
    else
        rm $fname
    fi
}

function do_config_action_base()
{
    debug_print "do_config_action_base"
    if [ "$config_action" = "install" ]; then
        do_config_action_backup $HOME/.vimrc

        ln -sf $Q_ROOT_PATH/.vimrc.base $HOME/.vimrc
    elif [ "$config_action" = "uninstall" ]; then
        do_config_action_restore $HOME/.vimrc
    fi
}

function do_config_action_ext()
{
    debug_print "do_config_action_ext"
    if [ "$config_action" = "install" ]; then
        do_config_action_backup $HOME/.vim
        do_config_action_backup $HOME/.vimrc

        ln -sf $Q_ROOT_PATH/.vim $HOME/.vim
        ln -sf $Q_ROOT_PATH/.vimrc.ext $HOME/.vimrc
        ln -sf $Q_ROOT_PATH/.vimrc.base $HOME/.vimrc.base
    elif [ "$config_action" = "uninstall" ]; then
        do_config_action_restore $HOME/.vim
        do_config_action_restore $HOME/.vimrc
        [ -e $HOME/.vimrc.base ] && rm $HOME/.vimrc.base
    fi
}

# parse options
while getopts behiu ARGS; do
    debug_print "option: $ARGS"
    case $ARGS in
        b)
            debug_print "base"
            config_type="base"
            ;;
        e)
            debug_print "ext"
            config_type="ext"
            ;;
        i)
            debug_print "install"
            config_action="install"
            ;;
        u)
            debug_print "uninstall"
            config_action="uninstall"
            ;;
        h)
            debug_print "help"
            print_help_info
            ;;
        *)
            debug_print "invalid"
            print_help_info
            ;;
    esac
done

# dispatch type action
if [ "$config_type" = "base" ]; then
    do_config_action_base
elif [ "$config_type" = "ext" ]; then
    vim_requirement_setup
    vim_plugin_manager_setup
    do_config_action_ext
    vim_plugin_install
    ycm_compile_with_c
fi

