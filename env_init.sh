#!/bin/bash

ABSPATH=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$ABSPATH")

#ln -s ${SCRIPTPATH}/screenrc ~/.screenrc
ln -s ${SCRIPTPATH}/tmux.conf ~/.tmux.conf
ln -s ${SCRIPTPATH}/vimrc ~/.vimrc

# call add_bashrc.sh
${SCRIPTPATH}/add_bashrc.sh

