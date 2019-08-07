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
x86_dir="$repo_dir/$release_path/rpms/x86_64"
sources_dir="$repo_dir/$release_path/rpms/Sources"
nexus_repo_url="$ALT_NEXUS_URL/repository/$NEXUS_REPO"
results_dir="$WORKSPACE/work/results"
repo_name=`echo $WORKSPACE | awk -F '/' '{print $4}' | cut -d '-' -f2- | sed 's|\(.*\)-.*|\1|'`

#Creating dir to move duplicate RPMs/SRPMs to avoid re-upload
mkdir "$results_dir/repo/duplicates"
mkdir "$results_dir/src_repo/duplicates"

#List all RPMs available in Nexus and move the duplicates
for artefact in \
  `ls $results_dir/repo`
    do
        if curl --head --fail $nexus_repo_url/$release_path/rpms/x86_64/$artefact
        then
            mv $results_dir/repo/$artefact $results_dir/repo/duplicates/
        fi
    done

#List all SRPMs available in Nexus and move the duplicates
for artefact in \
  `ls $results_dir/src_repo`
    do
        if curl --head --fail $nexus_repo_url/$release_path/rpms/Sources/$artefact
        then
            mv $results_dir/src_repo/$artefact $results_dir/src_repo/duplicates/
	fi
    done

mkdir -p "$x86_dir"
mkdir -p "$sources_dir"

cp "$results_dir/repo/"*.rpm "$x86_dir"
cp "$results_dir/src_repo/"*.rpm "$sources_dir"

echo "-----> Upload RPMs to Nexus"
lftools deploy nexus "$nexus_repo_url" "$repo_dir"

set +x  # Disable trace since we no longer need it.
echo "RPMs location: <a href=\"$nexus_repo_url\">$nexus_repo_url</a>"
