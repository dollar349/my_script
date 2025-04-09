#!/bin/sh
API_V4_URL="https://gitlab.com/api/v4"

print_help()
{
    echo ""
    echo "This script helps to Upload file to Gitlab Package Registry"
    echo "Upload package to a Repository. "
    echo " In addition to the Repository ID, you need to specify [Package name]/[Version]/[File name]" 
    echo "  Usage: $(basename $0) -r \${Repository ID/URL} -p \${Package name} -v \${Version} -f \${Specify an file to upload}"
    echo "  option: "
    echo "    -F [Specify another name]"
    echo "        Specify another name in the \"Package Registry\""
}


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

# Get access token
getGitLabAccessToken

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

UPLOAD_FILE_NAME=""
while getopts 'r:p:v:f:F:h' OPT; do
    case $OPT in
        r)  
            REPO_ID=$OPTARG
            ;;
        p)  
            PACKAGE_NAME=$OPTARG
            ;;
        v)  
            PACKAGE_VERSION=$OPTARG
            ;;
        f)  
            UPLOAD_FILE=$OPTARG
            ;;
        F)  
            UPLOAD_FILE_NAME=$OPTARG
            ;;
        h)
            print_help
            exit 0
            ;;
        ?)
            print_help
            exit 1
            ;;
    esac
done

if test "${1}" = "getid"; then
    if test "${2}" = ""; then
        echo "Please provide the URL of the Repository you want to query"
    fi
    REPO_ID=$(GetRepoID ${2})
    echo "REPO_ID = ${REPO_ID}"
    exit 0
fi

if test "${UPLOAD_FILE}" = "" \
         -o "${PACKAGE_NAME}" = "" \
         -o "${REPO_ID}" = "" \
         -o "${PACKAGE_VERSION}" = "" ; then
    print_help
    exit 1
fi

if test "${UPLOAD_FILE_NAME}" = ""; then
    UPLOAD_FILE_NAME=$(basename ${UPLOAD_FILE})
fi

# Get access token
getGitLabAccessToken

# If given a repo URL
re='^[0-9]+$'
if ! [[ ${REPO_ID} =~ ${re} ]] ; then
   REPO_ID=$(GetRepoID ${REPO_ID})
fi

curl --header "PRIVATE-TOKEN:${ACCESS_TOKEN}" --upload-file ${UPLOAD_FILE} "${API_V4_URL}/projects/${REPO_ID}/packages/generic/${PACKAGE_NAME}/${PACKAGE_VERSION}/${UPLOAD_FILE_NAME}"
if [ $? -eq 0 ]; then
    echo ""
    echo "Download URL is: ${API_V4_URL}/projects/${REPO_ID}/packages/generic/${PACKAGE_NAME}/${PACKAGE_VERSION}/${UPLOAD_FILE_NAME}"
fi