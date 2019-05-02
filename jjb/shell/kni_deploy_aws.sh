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

export PATH=$PATH:/usr/local/go/bin
KNI_PATH='go/src/gerrit.akraino.org/kni/'

set -e -u -x -o pipefail

echo '---> Starting kni installer generation'

mkdir -p $HOME/${KNI_PATH}/installer
export GOPATH=$HOME/go

# move clone to gopath
cp -R ${WORKSPACE}/* $HOME/${KNI_PATH}/installer/

# first build kni installer
pushd $HOME/${KNI_PATH}/installer
make build

# first copy credentials locally
cp $KNI_KEY_PATH $(pwd)/id_rsa
chmod 0600 $(pwd)/id_rsa
ssh-keygen -p -P cosita -N "" -f $(pwd)/id_rsa
GIT_SSH_COMMAND='ssh -i $(pwd)/id_rsa' git clone --verbose git@github.com:yrobla/akraino-secrets.git

# then start aws deploy
export CREDENTIALS=file://$(pwd)/akraino-secrets
export BASE_REPO="git::https://gerrit.akraino.org/r/kni/templates"
export BASE_PATH="aws/3-node"
export SITE_REPO="git::https://gerrit.akraino.org/r/kni/templates"
export SETTINGS_PATH="aws/sample_settings.yaml"
make deploy
STATUS=$?

# output tfstate
echo "metadata.json for removing cluster"
cat $(pwd)/build/metadata.json

if [ $STATUS -ne 0 ]; then
    echo "Error deploying in AWS"
    exit 1
fi

echo "Cluster successfully deployed! Starting cleanup"
make clean
STATUS=$?

popd

exit $STATUS
