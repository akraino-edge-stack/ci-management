#!/bin/bash
set -ex

check_env(){
  #Checking python-pip software status. If failed, reinstall it.
  set +e
  sudo pip --version
  CHECK_PIP_SUDO=$?

  pip --version
  CHECK_PIP_USER=$?
  set -e

  #Check command result, if failed, reinstall the pip
  if [ ${CHECK_PIP_SUDO} -ne 0 ] || [ ${CHECK_PIP_USER} -ne 0 ]; then
    echo "Reinstall pip"
    sudo python -m pip uninstall -y pip
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python get-pip.py pip
    rm get-pip.py
    hash -r
  fi
}

checkout_arm64(){
  VERSION="dcc6d07"
  git checkout ${VERSION}
  sed -i 's:opnfv/:cyb70289/:' build/build-aarch64.yaml

  # The different version of ifconfig command will result in compass building failed
  # on different Ubuntu system. Use the "ip addr" to replace the ifconfig may be a
  # good way for getting host ip address. So, there are some modifications in
  # configuration file.
  sed -i "s/^    host_ip.*$/    host_ip=\`ip addr show dev \$external_nic \| grep \'inet \' \| cut -d\/ -f1 \| awk \'\{ print \$2\}\'\`/g" \
         util/docker-compose/roles/compass/tasks/main.yml
}

check_env

echo "begin build compass"
git clone https://github.com/opnfv/compass4nfv.git

cd compass4nfv

if [ "$(uname -m)" = 'aarch64' ]; then
  echo "Checkout compass4nfv to Arm64 version"
  checkout_arm64
fi

COMPASS_WORK_DIR=$WORKSPACE/../compass-work

mkdir -p $COMPASS_WORK_DIR
ln -s $COMPASS_WORK_DIR work

sudo docker rm -f `sudo docker ps | grep compass | cut -f1 -d' '` || true

./build.sh

# Fix permissions so we can archive log files before pushing to Nexus
sudo chown $(id -u):$(id -g) -R "${WORKSPACE}"

exit 0
