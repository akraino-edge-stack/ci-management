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
KNI_PATH='go/src/gerrit.akraino.org/kni'

echo '---> Starting kni installer generation'

mkdir -p $HOME/${KNI_PATH}/installer
export GOPATH=$HOME/go

# move clone to gopath
cp -R ${WORKSPACE}/* $HOME/${KNI_PATH}/installer/

# do a host preparation and cleanup
pushd $HOME/${KNI_PATH}/installer
bash utils/prep_host.sh
wget https://raw.githubusercontent.com/openshift/installer/master/scripts/maintenance/virsh-cleanup.sh
chmod a+x ./virsh-cleanup.sh
sudo bash -c "yes Y | ./virsh-cleanup.sh"

# first build kni installer
make build 2>&1 | tee ${WORKSPACE}/build.log

# now build the openshift-install binary and copy to gopath
make binary 2>&1 | tee ${WORKSPACE}/binary.log

# then start aws deploy
export MASTER_MEMORY_MB=24000
export CREDENTIALS=file://$(pwd)/akraino-secrets
export BASE_REPO="git::https://gerrit.akraino.org/r/kni/templates"
export BASE_PATH="libvirt/3-node"
export SITE_REPO="git::https://gerrit.akraino.org/r/kni/templates"
export SETTINGS_PATH="libvirt/sample_settings.yaml"
export INSTALLER_PATH="file://${HOME}/${KNI_PATH}/installer/bin/openshift-install"
make deploy 2>&1 | tee ${WORKSPACE}/libvirt_deploy.log
STATUS=$?

# output tfstate
echo "metadata.json for removing cluster"
cat $(pwd)/build/metadata.json

if [ $STATUS -ne 0 ]; then
    echo "Error deploying in libvirt"
    exit 1
fi

echo "Cluster successfully deployed! Starting cleanup"
popd

exit $STATUS
