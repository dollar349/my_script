#!/bin/bash
ABSPATH=$(readlink -f "$BASH_SOURCE")
SCRIPTPATH=$(dirname "$ABSPATH")
script_name=$(basename "$0")
NOTE_FILE="${SCRIPTPATH}/.${script_name%.*}.txt"

if test $# = 0;then
    if test -f ${NOTE_FILE};then
        cat ${NOTE_FILE}
    fi
    exit 0
fi

if test "$1" = '-e';then
    vi ${NOTE_FILE}
    exit 0
fi

if test "$1" = '-a';then
    all_arguments="$*"
    # Remove the '-a '
    APPEND_STR="${all_arguments#-a }"
    if test -f ${NOTE_FILE};then
        #echo "///////////////////////////////////////////////////////" >> ${NOTE_FILE}
        echo "" >> ${NOTE_FILE}
    fi

    echo ${APPEND_STR} >> ${NOTE_FILE}
    exit 0
fi
