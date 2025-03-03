#!/bin/bash

APACHE2_PATH="/var/www/html"
MIRROR_PATH="oe-mirror"
SUPPORT_MIRROR=$(ls ${APACHE2_PATH}/${MIRROR_PATH})
SUPPORT_ARRAY=($SUPPORT_MIRROR)

PS3="請選擇一個項目: "
select opt in "${SUPPORT_ARRAY[@]}"
do
    MIRRO_SERVER=$opt

    if [[ $opt == "" ]]; then
    echo "bye bye!"
    fi
    break;
done
if test "$opt" = "";then
    exit 1
fi

ETHDEV="enp4s0"
MYIP=$(ip addr show ${ETHDEV} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
echo "Added to your local.conf to use the Mirror"
echo "############################################"
echo ""
echo "INHERIT:append = \" own-mirrors\""
echo "SOURCE_MIRROR_URL = \"http://${MYIP}/${MIRROR_PATH}/${MIRRO_SERVER}/\""
echo ""
echo "############################################"