#!/bin/bash

echo "Read configuration file"
source /vagrant/config/config.cfg

RESP=$(curl -s "https://api.randomuser.me/?inc=email,name&nat=${location}&format=csv&noinfo" | sed -n '2p')
FIRST=$(echo $RESP | cut -d',' -f 2)
LAST=$(echo $RESP | cut -d',' -f 3)

# Add Anonymity
if [ "${anonymity}" = true ] ; then
    echo "Starting TOR"
    sudo systemctl start tor
    cd ~ && wget -O - "https://www.dropbox.com/download/?plat=lnx.x86_64" | tar zxf -
    sleep 1.5s

    echo "Check what the IP address is through TOR proxy"
    curl -sS --socks5 127.0.0.1:9050 https://api.ipify.org/?format=json
    GET_IP_STATUS=$?

    if [ "${GET_IP_STATUS}" -gt 0 ] ; then
        echo "TOR was not installed or configured properly. Aborting."
        exit 1;
    fi
fi

# Fix screenshots path for CasperJS
cd /vagrant

echo "Removing previous runs' screenshots."
rm -f /vagrant/screenshots/*.png

# CasperJS command
echo "Run python for account."
RUN="python3 /vagrant/scripts/dropbox.py"
RANDOM_NUMBER=$((1 + RANDOM % 99999))
EMAIL="${account_email/\%d/${RANDOM_NUMBER}}"

# Create the account
if [ "${action}" == "create" ] || [ "${action}" == "both" ] ; then
    echo "Create the referral account (${EMAIL}) using : ${dropbox_referral_url} !"
    ${RUN} create "${dropbox_referral_url}" "${FIRST}" "${LAST}" "${EMAIL}" "${account_password}" ${timeout} || true
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
            ${RUN} link "${DROPBOX_LINK_URL}" "${FIRST}" "${LAST}" "${EMAIL}" "${account_password}" ${timeout} || true

            break
        fi

        # Wait before trying again to fetch Dropbox's linking URL from Dropbox daemon's logs, as it may not be there yet
        sleep 5
    done
fi
