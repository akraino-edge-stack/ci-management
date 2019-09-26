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

info ()  {
    logger -s -t "run_blu_val.info" "$*"
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
}

verify_connectivity() {
    local ip=$1
    info "Verifying connectivity to $ip..."
    for i in $(seq 0 10); do
        if ping -c 1 -W 1 $ip > /dev/null; then
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
while getopts ":j:k:u:s:b:l:r:n:" optchar; do
    case "${optchar}" in
        j) k8s_master=${OPTARG} ;;
        k) k8s_config_dir=${OPTARG} ;;
        s) ssh_key=${OPTARG} ;;
        b) blueprint_yaml=${OPTARG} ;;
        l) blueprint_layer=${OPTARG} ;;
        r) results_dir=${OPTARG} ;;
        n) blueprint_name=${OPTARG} ;;
        u) sh_user=${OPTARG} ;;
        *) echo "Non-option argument: '-${OPTARG}'" >&2
           usage
           exit 2
           ;;
    esac
done

if [ -z "$blueprint_name" ]
then
    usage
    error "Please specify blueprint name. "
fi
user=$(whoami)
# Use cwd/kube for k8s config
input="$cwd/kube"

# Initialize ssh key used
ssh_key=${ssh_key:-$SSH_KEY}
# k8s config directory
k8s_config_dir=${k8s_config_dir:-$input}
mkdir -p $k8s_config_dir
# If no blueprint given use demo 
blueprint_yaml=${blueprint_yaml:-$cwd/bluval-demo.yaml}
results_dir=${results_dir:-$cwd/results}
k8s_master=${k8s_master:-$K8S_MASTER}
ssh_user=${sh_user:-$SSH_USER}
# Initialize ssh options
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
ssh_options+=" -i ${ssh_key}"
ssh_options+=" -r "

# If blueprint layer is not defined use kubernetes by default
if [ "${blueprint_layer:-k8s}" == "k8s" ]
then
    verify_connectivity "${k8s_master}"
    scp $ssh_options "${ssh_user}@${k8s_master}:~/.kube/*" "$k8s_config_dir"
fi

git clone http://gerrit.akraino.org/r/validation

cp $blueprint_yaml $cwd/validation/bluval

volumes_path="$cwd/validation/bluval/volumes.yaml"
#update information in volumes yaml
sed -i -e "/kube_config_dir/{n; s@local: ''@local: '$input'@}" -e "/blueprint_dir/{n; s@local: ''@local: '$cwd/validation/bluval/'@}" -e "/results_dir/{n; s@local: ''@local: '$results_dir'@}" $volumes_path

python3 validation/bluval/blucon.py $blueprint_name -l "${blueprint_layer:-k8s}"
