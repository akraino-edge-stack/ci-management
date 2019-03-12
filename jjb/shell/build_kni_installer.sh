#!/bin/bash
#
# Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
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

GO_URL='https://dl.google.com/go/'
GO_VERSION='go1.12.linux-amd64.tar.gz'
KNI_PATH='go/src/gerrit.akraino.org/kni/'

set -e -u -x -o pipefail

echo '---> Starting kni installer generation'

# install go dependencies
wget ${GO_URL}/${GO_VERSION}
sudo tar -C /usr/local -xzf ${GO_VERSION}
export PATH=$PATH:/usr/local/go/bin

mkdir -p $HOME/${KNI_PATH}
export GOPATH=$HOME/go

# move clone to gopath
mv installer $HOME/${KNI_PATH}

# first build kni installer
pushd $HOME/${KNI_PATH}
make build
popd


set +u +x
