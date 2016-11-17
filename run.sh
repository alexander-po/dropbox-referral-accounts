#!/bin/bash

#
# Generate a MAC Address that can be used by VirtualBox.
# See https://www.virtualbox.org/ticket/10778 for more information.
#

function generate_mac_address_for_virtualbox() {
    local FIRST_CHAR=$(LC_CTYPE=C tr -dc 0-9A-Fa-f < /dev/urandom | head -c1)
    local SECOND_CHAR=$(LC_CTYPE=C tr -dc 02468ACEace < /dev/urandom | head -c1)
    local FOLLOWING_CHARS=$(LC_CTYPE=C tr -dc 0-9A-Fa-f < /dev/urandom | head -c10)

    echo "${FIRST_CHAR}${SECOND_CHAR}${FOLLOWING_CHARS}" | tr a-z A-Z
}

function create_box() {
    local ACCOUNT_ID=$1
    local MAC_ADDRESS=$(generate_mac_address_for_virtualbox)
    echo "Read configuration file"
    source ./config/config.cfg

    echo "Removing previous runs' screenshots."
    rm -f ./screenshots/*.png
    echo "Generating fake details..."
    RESP=$(curl -s "https://api.randomuser.me/?inc=email,name&nat=${location}&format=csv&noinfo" | sed -n '2p')
    FIRST=$(echo $RESP | cut -d',' -f 2)
    LAST=$(echo $RESP | cut -d',' -f 3)
    RANDOM_NUMBER=$((1 + RANDOM % 99999))
    EMAIL="${account_email/\%d/${RANDOM_NUMBER}}"

    # CasperJS command
    echo "Run python for account."
    # Create the account
    if [ "${action}" == "create" ] || [ "${action}" == "both" ] ; then
        echo "Create the referral account (${EMAIL}) using : ${dropbox_referral_url} !"
        python3 ~/dropbox-referral-accounts/scripts/dropbox.py create "${dropbox_referral_url}" "${FIRST}" "${LAST}" "${EMAIL}" "${account_password}" ${timeout} || true
    fi


    echo "Create a temporary Vagrant box #${ACCOUNT_ID} with the MAC address ${MAC_ADDRESS}..."
    MAC_ADDRESS=${MAC_ADDRESS} FIRST=${FIRST} LAST=${LAST} EMAIL=${EMAIL} vagrant up --provision --provider=${provider}
    return $?
}

function destroy_box() {
    if [ ! -z "$1" ] ; then
        echo "Destroy the temporary Vagrant box #$1..."
    else
        echo "Destroy any previously created Vagrant box..."
    fi

    vagrant destroy -f

    return $?
}

# No argument provided, default to 1
if [ -z "$1" ] ; then
    RANGE=1
# Two arguments provided, create a range
elif [ ! -z "$2" ] ; then
    RANGE=$(seq $1 $2)
# One argument provided, use it
else
    RANGE=$1
fi

destroy_box

for ACCOUNT_ID in ${RANGE}
do
    if create_box ${ACCOUNT_ID} ; then
        destroy_box ${ACCOUNT_ID}
    fi
done

exit 0
