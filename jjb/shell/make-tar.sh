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

sudo yum install -y dos2unix
# shellcheck source="$WORKSPACE/version.properties" disable=SC1091
dos2unix "${WORKSPACE}/version.properties"
source "$WORKSPACE/version.properties"
TARDIR=$UPLOAD_FILES_PATH

# STAGING_BUILD (below) may be unset
set -e +u -x -o pipefail
rm -fr "$TARDIR"

if [ -n "$STAGING_BUILD" ]
then
    # Remove the "-SNAPSHOT" from the version for a staging build
    VERSION=$(echo "$VERSION" | sed 's/-SNAPSHOT//')
else
    # Make sure the version has the "-SNAPSHOT" on the end for other builds
    [[ ! "$VERSION" =~ -SNAPSHOT$ ]] && VERSION="${VERSION}-SNAPSHOT"
fi

# STAGING_BUILD not used past this point
set -u

if [ "$PROJECT" == "addon-onap" ]
then

    # Make sure $TARDIR is an absolute path
    mkdir "$TARDIR"
    [[ "$TARDIR" != /* ]] && TARDIR="$PWD/$TARDIR"

    # ONAP addon is special.
    # Build the regional controller scripts tar ball
    ARTIFACT_NAME="onap-amsterdam-regional-controller-${STREAM}"
    TAR_NAME="${ARTIFACT_NAME}-${VERSION}.tgz"
    echo "Making tar file ${TARDIR}/${TAR_NAME}"
    cd ./src/regional_controller_scripts/
    tar -cvzf "${TARDIR}/${TAR_NAME}" -- *

    # Build the ONAP VM scripts tar ball
    ARTIFACT_NAME="onap-amsterdam-VM-${STREAM}"
    TAR_NAME="${ARTIFACT_NAME}-${VERSION}.tgz"
    echo "Making tar file ${TARDIR}/${TAR_NAME}"
    cd ../onap_vm_scripts/
    tar -cvzf "${TARDIR}/${TAR_NAME}" -- *

else

    TAR_NAME="${PROJECT}-${VERSION}.tgz"
    echo "Making tar file ${TARDIR}/${TAR_NAME}"
    # Put the file in /tmp initially to prevent it $TARDIR from going into the tar file
    tar -cvzf "/tmp/${TAR_NAME}" -- *
    mkdir "$TARDIR"
    cp "/tmp/${TAR_NAME}" "${TARDIR}/${TAR_NAME}"

fi
set +u +x
