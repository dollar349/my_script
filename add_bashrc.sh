#!/bin/bash
#ABSPATH=$(readlink -f "$BASH_SOURCE")
TARGET_FILE=$BASH_SOURCE

cd `dirname $TARGET_FILE`
TARGET_FILE=`basename $TARGET_FILE`

# Iterate down a (possible) chain of symlinks
while [ -L "$TARGET_FILE" ]
do
    TARGET_FILE=`readlink $TARGET_FILE`
    cd `dirname $TARGET_FILE`
    TARGET_FILE=`basename $TARGET_FILE`
done

# Compute the canonicalized name by finding the physical path 
# for the directory we're in and appending the target file.
PHYS_DIR=`pwd -P`
ABSPATH=$PHYS_DIR/$TARGET_FILE

SCRIPTPATH=$(dirname "$ABSPATH")
GITPROMPT="/etc/bash_completion.d/git-prompt"

GITPROMPT=""
if test -e /etc/bash_completion.d/git-prompt;then
   GITPROMPT="/etc/bash_completion.d/git-prompt"
elif test -e ~/.git-prompt.sh;then
   GITPROMPT="~/.git-prompt.sh"
else
   curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
   GITPROMPT="~/.git-prompt.sh"
fi

BASHRC="~/.bashrc"
eval BASHRC=$BASHRC

cd ~ && MYPATH=`pwd` && cd - > /dev/null
ADD_PATH=`echo $SCRIPTPATH | sed  "s,"${MYPATH}",~,g"`

echo "PATH=\$PATH:$ADD_PATH" >> $BASHRC 

if test "${GITPROMPT}" != "";then
   echo "source ${GITPROMPT}" >> $BASHRC
   echo 'PS1="\[\e[01;32m\][\T]\[\033[35m\][\w]\[\033[36m\]\$(__git_ps1)\n\[\033[1;33m\]\u~[\h]$ \[\033[0m\]"' >> $BASHRC
fi


# function rebake { bitbake -c cleanall $@ && bitbake $@; }

