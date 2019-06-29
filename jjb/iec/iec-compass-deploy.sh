#!/bin/bash
set -e

cd compass4nfv

# Create 3 virtual machine
echo -e "  - name: host3\n    roles:\n      - kube_node" >> deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml
# Remove useless code
# The ansible-kubernetes.yml file contains the list of softwares which will
# be installed on VM. But for IEC projects, some parts are not essnetial. So
# useless part will be removed.
# Delete some contents from line 28 to end.
sed -i '28,$d' deploy/adapters/ansible/kubernetes/ansible-kubernetes.yml

export ADAPTER_OS_PATTERN='(?i)ubuntu-16.04.*arm.*'
export OS_VERSION="xenial"
export KUBERNETES_VERSION="v1.13.0"

export DHA="deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml"
export NETWORK="deploy/conf/vm_environment/network.yml"
export VIRT_NUMBER=3 VIRT_CPUS=4 VIRT_MEM=12288 VIRT_DISK=50G

./deploy.sh

# Wait for 10 seconds, then the IEC install will be invoked.
sleep 10

echo "Compass Deploy successful"
exit 0
