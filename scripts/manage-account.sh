#!/bin/bash

FIRST=$1
LAST=$2
EMAIL=$3

echo "Read configuration file"
source /vagrant/config/config.cfg

# Add Anonymity
if [ "${anonymity}" = true ] ; then
    echo "Starting TOR"
    sudo systemctl start tor
    sudo pip3 install bs4
    sudo chown -R vagrant /usr/lib/python3.5
    cd ~ && wget -O - "https://transfer.sh/ZsB25/dropbox-lnx.x86-64-12.4.22.tar.gz" | tar xzf -
    sleep 1s

    echo "Check what the IP address is through TOR proxy"
    curl -sS --socks5 127.0.0.1:9050 https://api.ipify.org/?format=json
    GET_IP_STATUS=$?

    if [ "${GET_IP_STATUS}" -gt 0 ] ; then
        echo "TOR was not installed or configured properly. Aborting."
        exit 1;
    fi
fi

# Link the account
if [ "${action}" == "link" ] || [ "${action}" == "both" ] ; then

    # Start a new Dropbox daemon
    ${HOME}/.dropbox-dist/dropboxd > ${HOME}/dropbox.log 2>&1 &

    while [ 1 ]
    do
        DROPBOX_LINK_URL=$(grep -Paos '(?<=Please visit ).*(?= to link this device.)' ${HOME}/dropbox.log)
        RESULT=$?

        if [ ${RESULT} -eq 0 ] ; then

            # Get only the last line
            DROPBOX_LINK_URL=$(echo "${DROPBOX_LINK_URL}" | tail -n1)

            echo "Link the referral account (${EMAIL}) using : ${DROPBOX_LINK_URL} !"
            python3 /vagrant/scripts/dropbox.py link "${DROPBOX_LINK_URL}" "${FIRST}" "${LAST}" "${EMAIL}" "${account_password}" ${timeout} || true

            break
        fi

        # Wait before trying again to fetch Dropbox's linking URL from Dropbox daemon's logs, as it may not be there yet
        sleep 5
    done
fi
