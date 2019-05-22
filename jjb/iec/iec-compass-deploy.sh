#!/bin/bash
set -e

deploy_k8s(){
   sshpass -p root ssh root@10.1.0.50 \
     "apt-get update"
   sshpass -p root ssh root@10.1.0.50 \
     "apt-get install -y git"
   sshpass -p root ssh root@10.1.0.50 \
     "git clone https://gerrit.akraino.org/r/iec"
   sshpass -p root ssh root@10.1.0.50 \
     "source ./iec/src/foundation/scripts/startup.sh"
}



cd compass4nfv

# Create 3 virtual machine
echo -e "  - name: host3\n    roles:\n      - kube_node" >> deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml
# Remove useless code
sed -i "33,90d" deploy/adapters/ansible/kubernetes/ansible-kubernetes.yml

export ADAPTER_OS_PATTERN='(?i)ubuntu-16.04.*arm.*'
export OS_VERSION="xenial"
export KUBERNETES_VERSION="v1.13.0"
if [[ "$NODE_NAME" =~ "-virtual" ]]; then
    export DHA="deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml"
    export NETWORK="deploy/conf/vm_environment/network.yml"
    export VIRT_NUMBER=3 VIRT_CPUS=2 VIRT_MEM=4096 VIRT_DISK=50G
fi

./deploy.sh

deploy_k8s

echo "Compass Deploy successful"
exit 0
