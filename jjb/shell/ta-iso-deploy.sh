#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

echo "---> ta-iso-deploy.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

set -x  # Trace commands for this script to make debugging easier.

set +f  # Ensure filename expansion (globbing) is enabled

NEXUS_REPO=images-snapshots
release_path=TA/images/${JOB_NAME##*-}

repo_dir="$WORKSPACE/work/nexus/$NEXUS_REPO"
upload_dir1="$repo_dir/$release_path/$BUILD_ID"
upload_dir2="$repo_dir/$release_path/latest"
nexus_repo_url="$NEXUS_URL/content/repositories/$NEXUS_REPO"

mkdir -p "$upload_dir1"
mkdir -p "$upload_dir2"

platform_arch=$(uname -m)
if [ "${platform_arch}" != 'x86_64' ]; then
    # On non-x86 architecture, rename the artifacts appropiately
    pushd "$WORKSPACE/work/results/images/"
    rename "s/\./.${platform_arch}./" *.*
    sed -i "s/\./.${platform_arch}./" *."${platform_arch}".iso.*
    popd
fi

cp "$WORKSPACE/work/results/images/"* "$upload_dir1"
cp "$WORKSPACE/work/results/images/"* "$upload_dir2"

echo "-----> Sign all artifacts"
lftools sign sigul "$repo_dir"

echo "-----> Upload ISOs to Nexus"
lftools deploy nexus "$nexus_repo_url" "$repo_dir"
rm -rf "$repo_dir"

set +x  # Disable trace since we no longer need it.
echo "ISOs location: <a href=\"$nexus_repo_url\">$nexus_repo_url</a>"
