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

echo "---> ta-rpm-deploy.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

set -x  # Trace commands for this script to make debugging easier.

NEXUS_REPO=rpm.snapshots
release_path=TA/release-1

repo_dir="$WORKSPACE/work/nexus/$NEXUS_REPO"
arch_dir="$repo_dir/$release_path/rpms/$(uname -m)"
sources_dir="$repo_dir/$release_path/rpms/Sources"
nexus_repo_url="$ALT_NEXUS_URL/repository/$NEXUS_REPO"
results_dir="$WORKSPACE/work/results"
repo_name=`echo $WORKSPACE | awk -F '/' '{print $4}' | cut -d '-' -f2- | sed 's|\(.*\)-.*|\1|'`

#Creating dirs to move duplicate RPMs/SRPMs to avoid re-upload and copy the changed RPMs/SRPMs
mkdir "$results_dir/repo/duplicates"
mkdir "$results_dir/src_repo/duplicates"
mkdir -p "$arch_dir"
mkdir -p "$sources_dir"

#List all RPMs available in Nexus, move the duplicates and copy the changed ones
for artifact in \
  `ls $results_dir/repo/*.rpm`
    do
        if curl --head --fail $nexus_repo_url/$release_path/rpms/$(uname -m)/$(basename $artifact)
        then
            echo "RPM - $(basename $artifact) already available in Nexus"
            mv $results_dir/repo/$(basename $artifact) $results_dir/repo/duplicates/
        else
            echo "RPM - $(basename $artifact) is not available in Nexus. Will be uploaded"
            cp $results_dir/repo/$(basename $artifact) $arch_dir
        fi
    done

#List all Source RPMs available in Nexus, move the duplicates and copy the changed ones
for artifact in \
  `ls $results_dir/src_repo/*.rpm`
    do
        if curl --head --fail $nexus_repo_url/$release_path/rpms/Sources/$(basename $artifact)
        then
            echo "Source RPM - $(basename $artifact) already available in Nexus"
            mv $results_dir/src_repo/$(basename $artifact) $results_dir/src_repo/duplicates/
        else
            echo "Source RPM - $(basename $artifact) is not available in Nexus. Will be uploaded"
            cp $results_dir/src_repo/$(basename $artifact) $sources_dir
        fi
    done

echo "-----> Upload RPMs to Nexus"
lftools deploy nexus "$nexus_repo_url" "$repo_dir"

set +x  # Disable trace since we no longer need it.
echo "RPMs location: <a href=\"$nexus_repo_url\">$nexus_repo_url</a>"
