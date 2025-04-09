#!/bin/sh

API_V4_URL="https://gitlab.com/api/v4"

print_help()
{
    echo ""
    echo "This script helps to Delete file from Gitlab Package Registry"
    echo ""
    echo " In addition to the Repository ID, you need to specify [Package name]/[Version]" 
    echo "  Usage: $(basename $0) -r \${Repository ID/URL} -p \${Package name} -v \${Version}"
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

DOWNLOAD_FILE_NAME=""
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

if test "${PACKAGE_NAME}" = "" \
         -o "${REPO_ID}" = "" \
         -o "${PACKAGE_VERSION}" = "" ; then
    print_help
    exit 1
fi

# Get access token
getGitLabAccessToken

# If given a repo URL
re='^[0-9]+$'
if ! [[ ${REPO_ID} =~ ${re} ]] ; then
   REPO_ID=$(GetRepoID ${REPO_ID})
fi

PER_PAGE=100
PAGE=1
JSON_TMP_FILE=package.json
while [ 1 ];do
    curl -s -o ${JSON_TMP_FILE} -H "PRIVATE-TOKEN:${ACCESS_TOKEN}" "${API_V4_URL}/projects/${REPO_ID}/packages?page=${PAGE}&per_page=${PER_PAGE}"
    DELETE_URL=`cat ${JSON_TMP_FILE} | jq ".[] | select(.name == \"${PACKAGE_NAME}\" and .version == \"${PACKAGE_VERSION}\" ) | ._links.delete_api_path"`
    if test "${DELETE_URL}" != ""; then
        # Remove first and last quote (")
        DELETE_URL=`echo ${DELETE_URL} | tr -d '"'`
        curl -s --request DELETE -H "PRIVATE-TOKEN:${ACCESS_TOKEN}" ${DELETE_URL}
        break
    fi
    COUNT=`cat ${JSON_TMP_FILE} | jq '. | length'` 
    if [[ "$COUNT" == "" ||  "$COUNT" -lt "${PER_PAGE}" ]]; then
        break
    fi
    PAGE=$((PAGE+1))
    echo $PAGE
done
rm -rf ${JSON_TMP_FILE}