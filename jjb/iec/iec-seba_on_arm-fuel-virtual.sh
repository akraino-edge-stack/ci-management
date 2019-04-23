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

echo "deploy-type=${DEPLOY_TYPE}"

INSTALL_CMD="cd /home/${K8S_SSH_USER}/iec/src/use_cases/seba_on_arm/install; ./install.sh"

if [ -z "${K8S_SSH_PASSWORD}" ] && ! [ -z "${K8S_SSH_KEY}" ]
then
  ssh -o StrictHostKeyChecking=no -i /var/lib/opnfv/mcp.rsa \
    ${K8S_SSH_USER}@${K8S_MASTER_IP} "${INSTALL_CMD}"
elif ! [ -z "${K8S_SSH_PASSWORD}" ]
then
  sshpass -o StrictHostKeyChecking=no -p "${K8S_SSH_PASSWORD}" \
    -i /var/lib/opnfv/mcp.rsa \
    ${K8S_SSH_USER}@${K8S_MASTER_IP} "${INSTALL_CMD}"
else
  echo "Invalid parameters cannot ssh"
  return 1
fi
