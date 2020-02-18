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
export PATH=$PATH:/home/jenkins/.local/bin

cwd=$(pwd)
current_user=$(whoami)
is_optional="false"

info ()  {
    logger -s -t "run_blu_val.info" "$*"
}

has_substring() {
    [[ $1 =~ $2 ]]
}

change_res_owner() {
# change owner of results created by root in container
    if [ -d "$results_dir" ]
    then
        sudo chown -R "$current_user" "$results_dir"
    fi
}

usage() {
    echo "usage: $0" >&2
    echo "[-n <blueprint_name>">&2
    echo "[-b <blueprint_yaml> blueprint definition">&2
    echo "[-k <k8s_config_dir> k8s config dir">&2
    echo "[-j <cluster_master_ip> cluster master IP">&2
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
        j) cluster_master_ip=${OPTARG} ;;
        k) k8s_config_dir=${OPTARG} ;;
        s) ssh_key=${OPTARG} ;;
        b) blueprint_yaml=${OPTARG} ;;
        l) blueprint_layer=${OPTARG} ;;
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
blueprint_name=${blueprint_name:-$BLUEPRINT}
if [ -z "$blueprint_name" ]
then
    usage
    error "Please specify blueprint name. "
fi

# Use cwd/kube for k8s config
input="$cwd/kube"

# Initialize ssh key used
ssh_key=${ssh_key:-$CLUSTER_SSH_KEY}
# K8s config directory
k8s_config_dir=${k8s_config_dir:-$input}
mkdir -p "$k8s_config_dir"

# Testing configuration
version=${version:-$VERSION}
results_dir=$cwd/results
cluster_master_ip=${cluster_master_ip:-$CLUSTER_MASTER_IP}
ssh_user=${sh_user:-$CLUSTER_SSH_USER}
blueprint_layer=${blueprint_layer:-$LAYER}

if [ "$blueprint_layer" == "k8s" ]
then
    if [ -z "$cluster_master_ip" ]
    then
        usage
        error "Please provide valid IP address to access the k8s cluster."
    fi
    verify_connectivity "${cluster_master_ip}"
    if [[ -n $CLUSTER_SSH_PASSWORD ]]
    then
        sshpass -p "${CLUSTER_SSH_PASSWORD}" scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -r\
             "${ssh_user}@${cluster_master_ip}:~/.kube/*" "$k8s_config_dir"
    else
        scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i"$ssh_key" -r\
            "${ssh_user}"@"${cluster_master_ip}":~/.kube/* "$k8s_config_dir"
    fi
fi

if [[ -n $blueprint_yaml ]]
then
    cp "$blueprint_yaml" ./bluval/
fi

volumes_path="$cwd/bluval/volumes.yaml"
#update information in volumes yaml
sed -i -e "/kube_config_dir/{n; s@local: ''@local: '$k8s_config_dir'@}" -e "/blueprint_dir/{n; s@local: ''@local: '$cwd/bluval/'@}" -e "/results_dir/{n; s@local: ''@local: '$results_dir'@}" "$volumes_path"

if [[ -n $blueprint_layer ]]
then
    options="-l$blueprint_layer"
fi
if [ "$is_optional" == "true" ] || [ "$OPTIONAL" == "yes" ]
then
    options+=" -o"
fi

printf 'ok / PASS /\nerror / FAIL /\n' > ./bluval/rules.txt

set +e
# even if the script fails we need to change the owner of results
# shellcheck disable=SC2086
python3 bluval/blucon.py $options "$blueprint_name"

if [ $? -ne 0 ]; then
    change_res_owner
    error "Bluval validation FAIL "
fi
set -e

change_res_owner
if has_substring "$NODE_NAME" "snd-"
then
    echo "In sandbox the logs are not pushed"
else
    TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
    NEXUS_URL=https://nexus.akraino.org/
    NEXUS_PATH="${LAB_SILO}/bluval_results/${blueprint_name}/${VERSION}/${TIMESTAMP}"
    BUILD_URL="${JENKINS_HOSTNAME}/job/${JOB_NAME}/${BUILD_NUMBER}/"
    zip -r results.zip ./results
    lftools deploy nexus-zip "$NEXUS_URL" logs "$NEXUS_PATH" results.zip
    rm results.zip
fi

rm -f ~/.netrc

