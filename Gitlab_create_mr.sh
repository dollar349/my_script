#!/bin/bash

MR_TITLE="My merge request"
MR_DESCRIPT=""
MR_LABEL=""
DEBUG="false"
print_help()
{
    echo ""
    echo "This script helps to create Gitlab \"Merge Request (MR)\""
    echo "  Usage: $(basename $0) -r \${Repository ID/URL} -s \${Source branch} -t \${Target branch} [options] ..."
    echo "  Example: ./$(basename $0) -r https://gitlab.com/firstproject7232046/FirstProject.git -s dollar_test -t main"
    echo "  option: "
    echo "    -T [MR Title]"
    echo "        Specify the MR Title, default is \"My merge request\""
    echo "    -D [MR Description]"
    echo "        Specify the MR description, default is blank"
    echo "    -L [MR Label]"
    echo "        Specify the MR Label(Use commas to separate)"
}

while getopts 'Hhr:t:s:T:D:L:d' OPT; do
    case $OPT in
        d)
            DEBUG="true"
            ;;
        t)
            TARGET_BRANCH=${OPTARG}
            ;;
        s)
            SOURCE_BRANCH=${OPTARG}
            ;;
        r)
            MY_REPO_ID=${OPTARG}
            ;;
        T)
            MR_TITLE=${OPTARG}
            ;;
        D)
            MR_DESCRIPT=${OPTARG}
            ;;
        L)
            MR_LABEL=${OPTARG}
            ;;
        [Hh])
            print_help
            exit 0
            ;;
        ?)
            print_help
            exit 1
            ;;
    esac
done

if [ "${MY_REPO_ID}" = "" ];then
    echo "Please provide \"REPOSITORY ID/URL\" by [-r \${Repository ID/URL}]"
    exit 1
fi

if [ "${SOURCE_BRANCH}" = "" ];then
    echo "Please provide \"Source branch\" by [-r \${Source branch}]"
    exit 1
fi

if [ "${TARGET_BRANCH}" = "" ];then
    echo "Please provide \"Target branch\" by [-r \${Target branch}]"
    exit 1
fi


ACCESS_TOKEN=""
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


getGitLabAccessToken

# If given a repo URL
re='^[0-9]+$'
if ! [[ ${MY_REPO_ID} =~ ${re} ]] ; then
   MY_REPO_ID=$(GetRepoID ${MY_REPO_ID})
fi

if test "${MR_LABEL}" != "";then
    USE_LABEL=",\"labels\": \"${MR_LABEL}\""
else
    USE_LABEL=""
fi

if test "${DEBUG}" = "true"; then
    echo "TARGET_BRANCH = ${TARGET_BRANCH}"
    echo "SOURCE_BRANCH = ${SOURCE_BRANCH}"
    echo "REPOSITORY_URL = ${REPOSITORY_URL}"
    echo "MR_TITLE = ${MR_TITLE}"
    echo "MR_DESCRIPT = ${MR_DESCRIPT}"
    echo "MR_LABEL = ${MR_LABEL}"
    echo "MY_REPO_NAME = ${MY_REPO_NAME}"
    echo "MY_REPO_ID = ${MY_REPO_ID}"
    echo "USE_LABEL = ${USE_LABEL}"
fi

curl -s --location --request POST -H "PRIVATE-TOKEN:${ACCESS_TOKEN}" "https://gitlab.com/api/v4/projects/${MY_REPO_ID}/merge_requests" \
     --header 'Content-Type: application/json' \
     --data-raw "{
        \"source_branch\": \"${SOURCE_BRANCH}\",
        \"target_branch\": \"${TARGET_BRANCH}\",
        \"title\": \"${MR_TITLE}\",
        \"description\": \"${MR_DESCRIPT}\"
        ${USE_LABEL}
    }"