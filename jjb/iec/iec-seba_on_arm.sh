#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2019 Enea Software AB and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

export TERM="vt220"

echo "JOB_NAME=${JOB_NAME}"

case "${JOB_NAME}" in
  *fuel*)
    K8S_MASTER_IP=$(docker exec fuel cat /etc/hosts | grep iec01 \
                    | awk '{print $1}')
    # On Fuel deployements the K8s ssh key is the one used by the deploy job
    K8S_SSH_KEY=${SSH_KEY}
    IEC_DIR="/home/${K8S_SSH_USER}/iec"
    ;;
  *)
    echo "Cannot determine installer from ${JOB_NAME}"
    exit 1
    ;;
esac

if [ -z "$K8S_SSH_USER" ]
then
  echo "K8S_SSH_USER not set, cannot ssh to install SEBA"
  exit 1
fi

INSTALL_CMD="cd ${IEC_DIR}/src/use_cases/seba_on_arm/install; ./install.sh"

if [ -n "${K8S_SSH_PASSWORD}" ]
then
  sshpass -o StrictHostKeyChecking=no -p "${K8S_SSH_PASSWORD}" \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}" "${INSTALL_CMD}"
elif [ -n "${K8S_SSH_KEY}" ]
then
  ssh -o StrictHostKeyChecking=no -i "${K8S_SSH_KEY}" \
    "${K8S_SSH_USER}"@"${K8S_MASTER_IP}" "${INSTALL_CMD}"
else
  echo "Neither K8S_SSH_USER or K8S_SSH_KEY set. Cannot ssh to K8S Master"
  exit 1
fi

exit 0
