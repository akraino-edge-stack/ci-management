#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2019 Enea Software AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -o nounset

export TERM="vt220"

# set deployment parameters
export TMPDIR=${HOME}/tmpdir
if [ "$(uname -m)" = 'aarch64' ]; then
    LAB_NAME='arm'
    # shellcheck disable=SC2153
    POD_NAME=${NODE_NAME/*ubuntu1604-dev-48c-256g-/virtual}
else
    echo "Unavailable hardware. Cannot continue!"
    exit 1
fi

echo "Using configuration for ${LAB_NAME}"

# create TMPDIR if it doesn't exist, change permissions
mkdir -p "${TMPDIR}"
sudo chmod a+x "${HOME}" "${TMPDIR}"

cd "${WORKSPACE}" || exit 1

# log file name
# shellcheck disable=SC2153
FUEL_LOG_FILENAME="${JOB_NAME}_${BUILD_NUMBER}.log.tar.gz"

# turn on DEBUG mode
[ "${CI_DEBUG,,}" == 'true' ] && EXTRA_ARGS="-D ${EXTRA_ARGS:-}"

# construct the command
git clone https://github.com/opnfv/fuel.git

DEPLOY_COMMAND="fuel/ci/deploy.sh \
    -l ${LAB_NAME} -p ${POD_NAME} -s ${DEPLOY_SCENARIO} \
    -S ${TMPDIR} ${EXTRA_ARGS:-} \
    -b file://${WORKSPACE}/ci
    -L ${WORKSPACE}/${FUEL_LOG_FILENAME}"

# log info to console
echo "Deployment parameters"
echo "--------------------------------------------------------"
echo "Scenario: ${DEPLOY_SCENARIO}"
echo "Lab: ${LAB_NAME}"
echo "POD: ${POD_NAME}"
echo
echo "Starting the deployment using Fuel. This could take some time..."
echo "--------------------------------------------------------"
echo

# start the deployment
echo "Issuing command"
echo "${DEPLOY_COMMAND}"

${DEPLOY_COMMAND}
exit_code=$?

echo
echo "--------------------------------------------------------"
echo "Deployment is done!"

if [ "${exit_code}" -ne 0 ]; then
    echo "Deployment failed!"
    exit "${exit_code}"
fi

echo "Deployment is successful!"
exit 0
