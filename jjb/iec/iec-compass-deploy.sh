#!/bin/bash
set -e

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

#Modify the pip version to 8.1.1 version
PIP_VERSION=$(pip --version|cut -f2 -d ' '|cut -f1 -d '.')
#When pip version is larger than 10, it will result in some errors
#about "pip ImportError"
if [ "$PIP_VERSION" -gt "10" ]; then
  sudo python -m pip uninstall -y pip
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  sudo python get-pip.py pip==8.1.1
  rm get-pip.py
  hash -r
fi

./deploy.sh

echo "Compass Deploy successful"
exit 0
