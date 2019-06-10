#!/bin/bash
#
# Copyright (c) 2019 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e -u -x -o pipefail

export PATH=$PATH:/usr/local/go/bin:/usr/local/bin
KNI_PATH='src/gerrit.akraino.org/kni/installer'

echo '---> Building Openshift Installer binary with libvirt support'


# move to right directory in GOPATH
mkdir -p ${WORKSPACE}/${KNI_PATH}
export GOPATH=${WORKSPACE}
mv cmd pkg vendor ${WORKSPACE}/${KNI_PATH}/

# first build kni installer
make build 2>&1 | tee ${WORKSPACE}/build.log

# now build the openshift-install binary and copy to gopath
make binary 2>&1 | tee ${WORKSPACE}/binary.log

# publish openshift-install binary in a versioned way
source /tmp/ocp_installer_version
export NEXUS_URL=https://nexus.akraino.org
export GROUP_ID=org.akraino.kni
export NEXUS_REPO_ID=snapshots
export ARTIFACT_ID=openshift-install
export VERSION=$(echo $INSTALLER_GIT_TAG | sed 's/^v//')
export PACKAGING=bin
export FILE=bin/openshift-install
lftools deploy file $NEXUS_URL $NEXUS_REPO_ID $GROUP_ID $ARTIFACT_ID $VERSION $PACKAGING $FILE
