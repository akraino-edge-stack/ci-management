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

mkdir -p "$x86_dir"
mkdir -p "$sources_dir"

cp "$WORKSPACE/work/results/repo/"*.rpm "$x86_dir"
cp "$WORKSPACE/work/results/src_repo/"*.rpm "$sources_dir"

echo "-----> Upload RPMs to Nexus"
lftools deploy nexus "$nexus_repo_url" "$repo_dir"

set +x  # Disable trace since we no longer need it.
echo "RPMs location: <a href=\"$nexus_repo_url\">$nexus_repo_url</a>"
