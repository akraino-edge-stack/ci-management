#!/bin/bash
set -ex

cd compass4nfv

config_vm(){
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
}

modify_workdir(){
  # When deploying the OS by compass, long path will cause the deploying system failed.
  # we will create a soft link to walk around this problem.
  COMPASS_WORK_DIR=${HOME}/compass-work

  ln -sfn $(pwd)/work $COMPASS_WORK_DIR

  sed -i "s#\$COMPASS_DIR/work#$COMPASS_WORK_DIR#g" deploy/launch.sh
}

config_vm

modify_workdir

./deploy.sh

echo "Compass Deploy successful"

rm -rf "$COMPASS_WORK_DIR"
rm -rf work
exit 0
