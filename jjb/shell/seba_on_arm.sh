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
set -ex

echo "JOB_NAME=${JOB_NAME}"

# Run either ssh or scp on the K8S master
run_on_k8s_master () {
  case "${1}" in
    ssh)
      _c="${1}"
      shift
      _s=" "
      ;;
    scp)
      _c="${1} -r"
      shift
      _s=":${1}"
      shift
      ;;
    *)
      echo "Use either ssh or scp to run on K8S master"
      exit 1
      ;;
  esac

  if [ -n "${K8S_SSH_PASSWORD}" ]
  then
    eval sshpass -p "${K8S_SSH_PASSWORD}" "${_c}" \
         -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         ${_o} "${K8S_SSH_USER}"@"${K8S_MASTER_IP}${_s}" "$@"
  elif [ -n "${K8S_SSH_KEY}" ]
  then
    eval ${_c} -i "${K8S_SSH_KEY}" \
         -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         ${_o} "${K8S_SSH_USER}"@"${K8S_MASTER_IP}${_s}" "$@"
  else
    echo "Neither K8S_SSH_PASSWORD nor K8S_SSH_KEY are set"
    exit 1
  fi
}

if [ -z "$K8S_SSH_USER" ]
then
  echo "K8S_SSH_USER not set, cannot ssh to K8S master, aborting"
  exit 1
fi

case "${JOB_NAME}" in
  *fuel*)
    K8S_MASTER_IP=$(docker exec fuel cat /etc/hosts | grep iec01 \
                    | awk '{print $1}')
    # On Fuel deployements the K8s ssh key is the one used by the deploy job
    K8S_SSH_KEY=${SSH_KEY}
    IEC_DIR="/var/lib/akraino/iec"
    KUBE_DIR="~${K8S_SSH_USER}/.kube"
    ;;
  *compass*)
    # K8S_{MASTER_IP,SSH_USER,SSH_PASSWORD} are already set by job params
    IEC_DIR="/${K8S_SSH_USER}/iec"
    KUBE_DIR="~${K8S_SSH_USER}/.kube"
    ;;
  *)
    echo "Cannot determine installer from ${JOB_NAME}"
    exit 1
    ;;
esac

case "${JOB_NAME}" in
  iec-*-install-seba_on_arm*)
    INSTALL_CMD="'cd ${IEC_DIR}/src/use_cases/seba_on_arm/install; ./install.sh'"
    run_on_k8s_master ssh "${INSTALL_CMD}"
    ;;
  iec-*-test-seba_on_arm*)

    case "${PON_TYPE}" in
      *ponsim*)
      ;;
      *)
        echo "Unknown PON_TYPE ${PON_TYPE}"
        exit
      ;;
    esac

    # After the installation, copy the .kube dir from the K8S master
    cd "${WORKSPACE}" || exit 1
    run_on_k8s_master scp "${KUBE_DIR}" "${WORKSPACE}"

    SEBA_TEST_DIR="src/use_cases/seba_on_arm/test"
    TEST_CMD="${SEBA_TEST_DIR}/${PON_TYPE}/test.sh"
    echo "Issuing command"
    echo "${TEST_CMD}"

    eval ${TEST_CMD}
    ;;
  *)
    echo "Cannot determine what to do for seba_on_arm from ${JOB_NAME}"
    exit 1
    ;;
esac

exit 0
