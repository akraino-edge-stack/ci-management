#!/bin/bash
#
# Copyright (c) 2019 Red Hat. All rights reserved.
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

if [ -z "${GO_URL}" ]; then
    GO_URL='https://dl.google.com/go/'
fi

if [ -z "${GO_VERSION}" ]; then
    GO_VERSION='go1.12.linux-amd64.tar.gz'
fi

set -e -u -x -o pipefail

echo "---> Installing golang from ${GO_URL} with version ${GO_VERSION}"

# install go
wget ${GO_URL}/${GO_VERSION}
sudo tar -C /usr/local -xzf ${GO_VERSION}
