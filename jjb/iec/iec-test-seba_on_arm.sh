#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2019 Enea Software AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -e

echo "JOB_NAME=${JOB_NAME}"


case "${PON_TYPE}" in
  *ponsim*)
  ;;
  *)
    echo "Unknown PON_TYPE ${PON_TYPE}"
    exit
  ;;
esac

case "${JOB_NAME}" in
  *fuel*)
    K8S_MASTER_IP=$(docker exec fuel cat /etc/hosts | grep iec01 \
                    | awk '{print $1}')
    # On Fuel deployements the K8s ssh key is the one used by the deploy job
    K8S_SSH_KEY=${SSH_KEY}
    IEC_DIR="/var/lib/akraino/iec"
    KUBE_DIR="/home/ubuntu/.kube"
    ;;
  *compass*)
    # K8S_{MASTER_IP,SSH_USER,SSH_PASSWORD} are already set by job params
    IEC_DIR="/${K8S_SSH_USER}/iec"
    ;;
  *)
    echo "Cannot determine installer from ${JOB_NAME}"
    exit 1
    ;;
esac

# First we need to install the selected test tool
SEBA_TEST_DIR="src/use_cases/seba_on_arm/test"
INSTALL_CMD="cd ${IEC_DIR}/${SEBA_TEST_DIR}/${PON_TYPE}; ./install.sh"

# Run the installation script and copy the .kube dir needed for next step
if [ -n "${K8S_SSH_PASSWORD}" ]
then
  sshpass -p "${K8S_SSH_PASSWORD}" ssh -o StrictHostKeyChecking=no \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}" "${INSTALL_CMD}"
  sshpass -p "${K8S_SSH_PASSWORD}" scp -o StrictHostKeyChecking=no -r \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}":"${KUBE_DIR}" "${WORKSPACE}"
elif [ -n "${K8S_SSH_KEY}" ]
then
  ssh -o StrictHostKeyChecking=no -i "${K8S_SSH_KEY}" \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}" "${INSTALL_CMD}"
  scp -o StrictHostKeyChecking=no -i "${K8S_SSH_KEY}" -r \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}":"${KUBE_DIR}" "${WORKSPACE}"
else
  echo "Neither K8S_SSH_USER or K8S_SSH_KEY set. Cannot ssh to K8S Master"
  exit 1
fi

# If the installation is successful, proceed with running the tests
cd "${WORKSPACE}" || exit 1

TEST_CMD="${SEBA_TEST_DIR}/${PON_TYPE}/test.sh"
echo "Issuing command"
echo "${TEST_CMD}"

${TEST_CMD}
exit_code=$?
