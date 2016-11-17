#!/bin/bash

FIRST=$1
LAST=$2
EMAIL=$3

echo "Read configuration file"
source /vagrant/config/config.cfg

# Add Anonymity
if [ "${anonymity}" = true ] ; then
    cd ~ && tar xzf /vagrant/dropbox.tar.gz
    echo "Starting TOR"
    sudo systemctl start tor
    sudo pip3 install bs4
    sudo chown -R vagrant /usr/lib/python3.5
    sleep 1s
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
