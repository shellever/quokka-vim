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
}

# Reference:
# Building Vim from source
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
function vim_build_from_source()
{
    debug_print "===> vim_build_from_source"

    # get vim version
    local vim_version=$(vim --version | head -1 | awk '{print $5}')

    # return if vim had been installed successfully
    test "$vim_version" = "8.1" && return 0

    # 1. install all the prerequisite libraries
    sudo apt-get update
    sudo apt-get install -y libncurses5-dev libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 liblua5.1-dev libperl-dev git

    # 2. remove vim if you have it already
    sudo apt-get remove -y vim vim-runtime gvim
    # on Ubuntu 12.04.2 you probably have to remove these packages as well
    sudo apt-get remove -y vim-tiny vim-common vim-gui-common vim-nox

    # 3. once everything is installed, getting the source is easy
    git clone https://github.com/vim/vim.git
    cd vim
    make distclean

    # Note for Ubuntu users: You can only use Python 2 or Python 3.
    # --enable-python3interp=yes \
    # --with-python3-config-dir=/usr/lib/python3.5/config \
    ./configure --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp=yes \
        --enable-pythoninterp=yes \
        --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
        --enable-perlinterp=yes \
        --enable-luainterp=yes \
        --enable-gui=gtk2 \
        --enable-cscope \
        --prefix=/usr

    make
    # use make to install
    sudo make install
    cd -

    # set vim as your default editor with update-alternatives
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
    sudo update-alternatives --set editor /usr/bin/vim
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
    sudo update-alternatives --set vi /usr/bin/vim

    # remove vim directory if install successfully
    [ "$(which vim)" = "/usr/bin/vim" ] && rm -rf ./vim
}

function vim_requirement_setup_base()
{
    debug_print "===> vim_requirement_setup_base"

    # Vi IMproved - enhanced vi editor
    sudo apt-get install -y vim
}

function vim_requirement_setup_ext()
{
    debug_print "===> vim_requirement_setup_ext"

    local distrib_release=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | awk -F= '{print $2}')

    # tagbar {{{
    # build tag file indexes of source code definitions
    sudo apt-get install -y exuberant-ctags
    # }}}

    # airline {{{
    # powerline symbols font
    sudo apt-get install -y fonts-powerline
    # }}}

    # ycm {{{
    # YouCompleteMe requires Vim 7.4.1578+
    # install vim using source (Vim 8.1)
    vim_build_from_source

    sudo apt-get install -y build-essential python3-dev

    if [ "$distrib_release" = "14.04" ]; then
        # required cmake 3.4+
        sudo apt-get install -y cmake3
    else
        # Ubuntu 16.04 and later
        sudo apt-get install -y cmake
    fi
    # }}}
}

# set up Vundle as vim plugin manager
function vim_plugin_manager_setup()
{
    debug_print "===> vim_plugin_manager_setup"

    local repo_vundle_vim=https://github.com/VundleVim/Vundle.vim.git
    if [ ! -d $Q_ROOT_PATH/.vim/bundle/Vundle.vim ]; then
        mkdir -p $Q_ROOT_PATH/.vim/bundle
        git clone $repo_vundle_vim $Q_ROOT_PATH/.vim/bundle/Vundle.vim
    fi
}

# install plugins and quit
function vim_plugin_install()
{
    debug_print "===> vim_plugin_install"

    # vim -c "PluginInstall" -c "q" -c "q"
    vim +PluginInstall +qall
}

# compiling YCM with semantic support for C-family languages
function ycm_compile_with_c()
{
    debug_print "===> ycm_compile_with_c"

    cd $Q_ROOT_PATH/.vim/bundle/YouCompleteMe
    python3 install.py --clang-completer
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
    rm $fname
    if [ -e $fname_backup ]; then
        mv $fname_backup $fname
    fi
}


# issue: error to customize colorscheme before install plugin
# fixed: take a shadow to install plugin only, not setup configs for plugins
function do_shadow_before_vim_plugin_install()
{
    debug_print "===> do_shadow_before_vim_plugin_install"

    do_config_action_backup $HOME/.vimrc

    cp -p $Q_ROOT_PATH/.vimrc.ext $Q_ROOT_PATH/.vimrc.shadow
    sed -i '/=== common configs/,$d' $Q_ROOT_PATH/.vimrc.shadow
    ln -sf $Q_ROOT_PATH/.vimrc.shadow $HOME/.vimrc
}

function do_shadow_after_vim_plugin_install()
{
    debug_print "===> do_shadow_after_vim_plugin_install"

    rm $Q_ROOT_PATH/.vimrc.shadow
    do_config_action_restore $HOME/.vimrc
}


function do_config_action_install_base()
{
    debug_print "===> do_config_action_install_base"

    do_config_action_backup $HOME/.vimrc

    ln -sf $Q_ROOT_PATH/.vimrc.base $HOME/.vimrc
}

function do_config_action_install_ext()
{
    debug_print "===> do_config_action_install_ext"

    do_config_action_backup $HOME/.vim
    do_config_action_backup $HOME/.vimrc

    ln -sf $Q_ROOT_PATH/.vim $HOME/.vim
    ln -sf $Q_ROOT_PATH/.vimrc.ext $HOME/.vimrc
    ln -sf $Q_ROOT_PATH/.vimrc.base $HOME/.vimrc.base
}


function do_config_action_install()
{
    debug_print "===> do_config_action_install"
    if [ "$config_type" = "base" ]; then
        vim_requirement_setup_base
        do_config_action_install_base
    elif [ "$config_type" = "ext" ]; then
        vim_requirement_setup_ext
        vim_plugin_manager_setup

        do_config_action_install_ext

        do_shadow_before_vim_plugin_install
        vim_plugin_install
        do_shadow_after_vim_plugin_install

        ycm_compile_with_c
    fi
}

function do_config_action_uninstall()
{
    debug_print "===> do_config_action_uninstall"
    if [ "$config_type" = "base" ]; then
        do_config_action_restore $HOME/.vimrc
    elif [ "$config_type" = "ext" ]; then
        do_config_action_restore $HOME/.vim
        do_config_action_restore $HOME/.vimrc
        [ -e $HOME/.vimrc.base ] && rm $HOME/.vimrc.base
    fi
}


# start here
# parse options
while getopts behiu ARGS; do
    debug_print "option: $ARGS"
    case $ARGS in
        b) config_type="base";;
        e) config_type="ext";;
        i) config_action="install";;
        u) config_action="uninstall";;
        h) print_help_info; exit 0;;
        *) print_help_info; exit 1;;
    esac
done

# dispatch according to action
if [ "$config_action" = "install" ]; then
    do_config_action_install
elif [ "$config_action" = "uninstall" ]; then
    do_config_action_uninstall
fi

