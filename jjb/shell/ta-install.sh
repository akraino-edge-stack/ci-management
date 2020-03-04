#!/bin/bash
# Copyright 2019 AT&T
# Copyright 2020 ENEA

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

#Work-flow:

#0.  Get values for the environment variables

# The following must be provided.
    HOST_IP=${HOST_IP:?'Must be defined!'}
    CLOUDNAME=${CLOUDNAME:?'Must be defined!'}
    ADMIN_PASSWD=${ADMIN_PASSWD:?'Must be defined!'}
    REC_ISO_IMAGE_NAME=${REC_ISO_IMAGE_NAME:?'Must be defined!'}
    REC_PROVISIONING_ISO_NAME=${REC_PROVISIONING_ISO_NAME:?'Must be defined!'}
    REC_USER_CONFIG=${REC_USER_CONFIG:?'Must be defined!'}

# The next set may be modified if necessary but are best left as-is
    HTTPS_PORT=8443
    API_PORT=15101
    # Max time (in minutes) to wait for the remote-installer to return completed
    # Currently 4 hours
    MAX_TIME=240

    # These should probably not be changed
    WORKDIR=$(dirname $0)
    BASEDIR=$WORKDIR
    NETWORK=host


cat <<EOF
    --------------------------------------------
    WORKDIR is $WORKDIR
    HOST_IP is $HOST_IP
    REC_ISO_IMAGE_NAME is $REC_ISO_IMAGE_NAME
    REC_PROVISIONING_ISO_NAME is $REC_PROVISIONING_ISO_NAME
    --------------------------------------------
EOF

#1. Create a new directory to be used for holding the installation artifacts.

    #create the base directory structure
    mkdir -p $BASEDIR/ \
             $BASEDIR/images \
             $BASEDIR/certificates \
             $BASEDIR/user-configs \
             $BASEDIR/installations \

#2. Get REC golden image from REC Nexus artifacts and copy it to the images sub-directory under the directory created in (1).

   cd $BASEDIR/images/
   FILENAME=$(echo "${REC_ISO_IMAGE_NAME##*/}")
   curl $REC_ISO_IMAGE_NAME > $FILENAME

#3. Get REC booting image from REC Nexus artifacts and copy it to the images sub-directory under the directory created in (1).

   cd $BASEDIR/images/
   FILENAME=$(echo "${REC_PROVISIONING_ISO_NAME##*/}")
   curl $REC_PROVISIONING_ISO_NAME > $FILENAME

#4. Get the user-config.yaml file and admin_password file for the CD environment from the
#   cd-environments repo and copy it to the user-configs sub-directory under the directory
#   created in (1). Copy the files to a cloud-specific directory identified by the cloudname.

   cd $BASEDIR/user-configs/
   mkdir $CLOUDNAME
   cd $CLOUDNAME
   cp $REC_USER_CONFIG user_config.yaml
   ln user_config.yaml user_config.yml
   echo $ADMIN_PASSWD > admin_passwd

#5. Checkout the remote-installer repo from LF

    mkdir $BASEDIR/git
    cd $BASEDIR/git
    git clone https://gerrit.akraino.org/r/ta/remote-installer
    if [ -n "${REMOTE_INSTALLER_GITREF}" ]; then
        echo "Switching remote-installer to ${REMOTE_INSTALLER_GITREF}"
        cd $BASEDIR/git/remote-installer
        git fetch origin "${REMOTE_INSTALLER_GITREF}" && git checkout FETCH_HEAD
   fi

#6. Copy the sever certificates, the client certificates in addition to CA certificate to
#  the certificates sub-directory under the directory created in (1).
#   The following certificates are expected to be available in the directory:
#
#   cacert.pem: The CA certificate
#   servercert.pem: The server certificate signed by the CA
#   serverkey.pem: The server key
#   clientcert.pem: The client certificate signed by the CA
#   clientkey.pem: The client key
#

    cd $BASEDIR/git/remote-installer/test/certificates
    ./create.sh
    cp -a {ca,client,server}{cert,key}.pem ${BASEDIR}/certificates

#7. Build the remote installer docker-image.
    cd $BASEDIR/git/remote-installer/scripts/
    echo $0: ./build.sh "$HTTPS_PORT" "$API_PORT"
    ./build.sh "$HTTPS_PORT" "$API_PORT"

#8. Start the remote installer

    cd $BASEDIR/git/remote-installer/scripts/
    echo $0: ./start.sh -b "$BASEDIR" -e "$HOST_IP" -s "$HTTPS_PORT" -a "$API_PORT" -p "$ADMIN_PASSWD"
    if ! ./start.sh -b "$BASEDIR" -e "$HOST_IP" -s "$HTTPS_PORT" -a "$API_PORT" -p "$ADMIN_PASSWD"
    then
        echo Failed to run workflow
        exit 1
    fi

#9. Wait for the remote installer to become running.
#   check every 30 seconds to see if it has it has a status of "running"

    DOCKER_STATUS=""

    while [ ${#DOCKER_STATUS} -eq 0 ]; do
        sleep 30

        DOCKER_ID=$(docker ps | grep remote-installer | awk ' {print $1}')
        DOCKER_STATUS=$(docker ps -f status=running | grep $DOCKER_ID)
    done

#10. Start the installation by sending the following http request to the installer API

#    POST url: https://localhost:$API_PORT/v1/installations
#    REQ body json- encoded
#    {
#        'cloudname': $CLOUDNAME,
#        'iso': $REC_ISO_IMAGE_NAME,
#        'provisioning-iso': $REC_PROVISIONING_ISO_NAME
#    }
#    REP body json-encoded
#    {
#        'uuid': $INSTALLATION_UUID
#    }

rec=$(basename $REC_ISO_IMAGE_NAME)
boot=$(basename $REC_PROVISIONING_ISO_NAME)
cat >rec_request.json <<EOF
{
    "cloud-name": "$CLOUDNAME",
    "iso": "$rec",
    "provisioning-iso": "$boot"
}
EOF

    # Get the IP address of the remote installer container
    # RI_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' remote-installer)
    RI_IP=$HOST_IP

    echo "$0: Posting to https://$RI_IP:$API_PORT/v1/installations"
    RESPONSE=$(
        curl -k \
            --header "Content-Type: application/json" \
            -d "@rec_request.json" \
            --cert $BASEDIR/certificates/clientcert.pem \
            --key  $BASEDIR/certificates/clientkey.pem \
            https://$RI_IP:$API_PORT/v1/installations)
    echo "$0: RESPONSE IS $RESPONSE"

    INSTALLATION_UUID=$(echo $RESPONSE | jq -r ".uuid")

#11. Follow the progress of the installation by sending the following http request to the installer API

#    GET url: https://localhost:$API_PORT/v1/installations/$INSTALLATION_UUID
#
#    REP body json-encoded
#    {
#        'status': <ongoing|completed|failed>,
#        'description': <description>,
#        'percentage': <the progess precentage>
#    }
#
#

# check the status every minute until it has become "completed"
# (for a maximum of MAX_TIME minutes)

    STATUS="ongoing"
    NTIMES=$MAX_TIME
    while [ "$STATUS" == "ongoing" -a $NTIMES -gt 0 ]; do
        sleep 60
        NTIMES=$((NTIMES - 1))
        RESPONSE=$(curl -k --silent \
            --cert $BASEDIR/certificates/clientcert.pem \
            --key  $BASEDIR/certificates/clientkey.pem \
            https://$RI_IP:$API_PORT/v1/installations/$INSTALLATION_UUID/state)
        STATUS=$(echo $RESPONSE | jq -r ".status")
        PCT=$(   echo $RESPONSE | jq -r ".percentage")
        DESCR=$( echo $RESPONSE | jq -r ".description")
        echo "$(date): Status is $STATUS ($PCT) $DESCR"
    done
    if [ "$STATUS" == "ongoing" -a $NTIMES -eq 0 ]
    then
        echo "Installation failed after $MAX_TIME minutes."
        exit 1
    fi
    echo "Installation complete!"

#12. When installation is completed stop the remote installer.

    cd $BASEDIR/git/remote-installer/scripts/
    ./stop.sh

    exit 0
