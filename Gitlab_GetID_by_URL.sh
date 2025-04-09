#!/bin/bash

ACCESS_TOKEN=""
print_help()
{
    echo ""
    echo "This script helps to get the repo's ID by Gitlab project URL"
    echo "  Usage: $(basename $0) \${Gitlab project URL}"
}

getGitLabAccessToken()
{
    local git_credentials=""
    local token_tmp=""

    if [ ! -f ${HOME}/.git-credentials ]; then
        echo "${HOME}/.git-credentials not found."
        return 1
    fi

    git_credentials="$(cat ${HOME}/.git-credentials | grep -v '^#' | grep "gitlab.com")"

    if test "x${git_credentials}" = "x"; then
        echo "Credentials for gitlab.com not found."
        return 1
    fi

    token_tmp="$(echo ${git_credentials} | awk -F '@' '{print $1}' | awk -F '//' '{print $NF}')"

    if test "${token_tmp}" = ""; then
         echo "Access token for gitlab.com not found."
         return 1
    fi

    if [ $(echo "${token_tmp}" | grep -i ":" | wc -w) -gt 0 ]; then
        # remove username.
        ACCESS_TOKEN="$(echo ${token_tmp} | awk -F ':' '{print $NF}')"
    else
        ACCESS_TOKEN="${token_tmp}"
    fi
}

function GetRepoID(){
    if test "${ACCESS_TOKEN}" = "";then
        getGitLabAccessToken
    fi
    GIT_REPOSITORY_URL=${1%.git}".git"
    REPO_NAME=$(echo ${GIT_REPOSITORY_URL} | awk -F "/" '{print $NF}')
    REPO_NAME=${REPO_NAME%.git}
    REPO_ID=$(curl -s -H "PRIVATE-TOKEN:${ACCESS_TOKEN}" https://gitlab.com/api/v4/projects?search=${REPO_NAME} | jq ".[] | select(.http_url_to_repo == \"${GIT_REPOSITORY_URL}\") | .id")
    echo ${REPO_ID}
}

re='^[0-9]+$'
if [[ ${1} =~ ${re} ]] ; then
    print_help
    exit 1
fi

# Get access token
getGitLabAccessToken

GIT_REPOSITORY_URL=${1%.git}".git"
REPO_NAME=$(echo ${GIT_REPOSITORY_URL} | awk -F "/" '{print $NF}')
REPO_NAME=${REPO_NAME%.git}
REPO_ID=$(curl -s -H "PRIVATE-TOKEN:${ACCESS_TOKEN}" https://gitlab.com/api/v4/projects?search=${REPO_NAME} | jq ".[] | select(.http_url_to_repo == \"${GIT_REPOSITORY_URL}\") | .id")
echo ${REPO_ID}
