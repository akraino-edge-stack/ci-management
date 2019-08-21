#!/bin/bash
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

NEXUS_REPO=images-snapshots
release_path=TA/release-1

repo_dir="$WORKSPACE/work/nexus/$NEXUS_REPO"
upload_dir1="$repo_dir/$release_path/images/$BUILD_ID"
upload_dir2="$repo_dir/$release_path/images/latest"
nexus_repo_url="$NEXUS_URL/content/repositories/$NEXUS_REPO"

mkdir -p "$upload_dir1"
mkdir -p "$upload_dir2"

if [ "$(uname -m)" != 'x86_64' ]; then
    # On non-x86 architecture, rename the artifacts appropiately
    pushd "$WORKSPACE/work/results/images/"
    rename "s/\./.$(uname -m)./" *.*
    popd
fi

cp "$WORKSPACE/work/results/images/"* "$upload_dir1"
cp "$WORKSPACE/work/results/images/"* "$upload_dir2"

echo "-----> Upload ISOs to Nexus"
lftools deploy nexus "$nexus_repo_url" "$repo_dir"

set +x  # Disable trace since we no longer need it.
echo "ISOs location: <a href=\"$nexus_repo_url\">$nexus_repo_url</a>"
