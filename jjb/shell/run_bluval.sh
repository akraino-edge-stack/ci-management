#!/bin/bash
##############################################################################
# Copyright (c) 2019 ENEA and others.
# valentin.radulescu@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -e
set -o errexit
set -o pipefail

cwd=$(pwd)
current_user=$(whoami)
is_optional="false"

info ()  {
    logger -s -t "run_blu_val.info" "$*"
}

change_res_owner() {
# change owner of results created by root in container
    if [ -d "$results_dir" ]
    then
        sudo chown -R "$current_user" "$results_dir"
    fi
}

usage() {
    echo "usage: $0 -n <blueprint_name>" >&2
    echo "[-r <results_dir> results dir">&2
    echo "[-b <blueprint_yaml> blueprint definition">&2
    echo "[-k <k8s_config_dir> k8s config dir">&2
    echo "[-j <k8s_master> k8s master">&2
    echo "[-u <ssh_user> ssh user">&2
    echo "[-s <ssh_key>] path to ssh key">&2
    echo "[-c <custmom_var_file> ] path to variables yaml file">&2
    echo "[-l <layer> ] blueprint layer">&2
    echo "[-o ] run optional tests">&2
    echo "[-v <version> ] version">&2
}

verify_connectivity() {
    local ip=$1
    info "Verifying connectivity to $ip..."
    for i in $(seq 0 10); do
        if ping -c 1 -W 1 "$ip" > /dev/null; then
            info "$ip is reachable!"
            return 0
        fi
        sleep 1
    done
    error "Can not talk to $ip."
}

error () {
    logger -s -t "run_blu_val.error" "$*"
    exit 1
}

# Get options from shell
while getopts "j:k:u:s:b:l:r:n:ov:" optchar; do
    case "${optchar}" in
        j) k8s_master=${OPTARG} ;;
        k) k8s_config_dir=${OPTARG} ;;
        s) ssh_key=${OPTARG} ;;
        b) blueprint_yaml=${OPTARG} ;;
        l) blueprint_layer=${OPTARG} ;;
        r) results_dir=${OPTARG} ;;
        n) blueprint_name=${OPTARG} ;;
        u) sh_user=${OPTARG} ;;
        o) is_optional="true"  ;;
        v) version=${OPTARG} ;;
        *) echo "Non-option argument: '-${OPTARG}'" >&2
           usage
           exit 2
           ;;
    esac
done

# Blueprint name is mandatory
if [ -z "$blueprint_name" ]
then
    usage
    error "Please specify blueprint name. "
fi

# Use cwd/kube for k8s config
input="$cwd/kube"

# Initialize ssh key used
ssh_key=${ssh_key:-$K8S_SSH_KEY}
# K8s config directory
k8s_config_dir=${k8s_config_dir:-$input}
mkdir -p "$k8s_config_dir"

# Testing configuration
version=${version:-$VERSION}
results_dir=${results_dir:-$cwd/results}
k8s_master=${k8s_master:-$K8S_MASTER_IP}
ssh_user=${sh_user:-$K8S_SSH_USER}
blueprint_layer=${blueprint_layer:-$LAYER}

# If blueprint layer is not defined use k8s by default
if [ "$blueprint_layer" == "k8s" ]
then
    if [ -z "$k8s_master" ]
    then
        usage
        error "Please provide valid k8s IP address."
    fi
    verify_connectivity "${k8s_master}"
    if [[ -n $K8S_SSH_PASSWORD ]]
    then
        sshpass -p "${K8S_SSH_PASSWORD}" scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -r\
             "${ssh_user}@${k8s_master}:~/.kube/*" "$k8s_config_dir"
    else
        scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i"$ssh_key" -r\
            "${ssh_user}"@"${k8s_master}":~/.kube/* "$k8s_config_dir"
    fi
fi

if [ ! -d "$cwd/validation" ]
then
    git clone http://gerrit.akraino.org/r/validation
fi

if [[ -n $blueprint_yaml ]]
then
    cp "$blueprint_yaml" ./validation/bluval/
fi

# Create rules file for log parser
printf 'error /(?i)^error /\nerror /(?i)error:/\nerror /(?i)^fail/\nerror /(?i)fail/\nerror /BUILD FAILED/\nerror /failed with exit code/\n' > ./rules.txt

volumes_path="$cwd/validation/bluval/volumes.yaml"
#update information in volumes yaml
sed -i -e "/kube_config_dir/{n; s@local: ''@local: '$k8s_config_dir'@}" -e "/blueprint_dir/{n; s@local: ''@local: '$cwd/validation/bluval/'@}" -e "/results_dir/{n; s@local: ''@local: '$results_dir'@}" "$volumes_path"

if [[ -n $blueprint_layer ]]
then
    options="-l$blueprint_layer"
fi
if [ "$is_optional" == "true" ] || [ "$OPTIONAL" == "yes" ]
then
    options+=" -o"
fi

set +e
# even if the script fails we need to change the owner of results
# shellcheck disable=SC2086
python3 validation/bluval/blucon.py $options "$blueprint_name"

if [ $? -ne 0 ]; then
    change_res_owner
    error "Bluval validation failed!"
fi

set -e

change_res_owner
