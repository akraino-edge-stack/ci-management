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

check_env

echo "begin build compass"
git clone https://github.com/opnfv/compass4nfv.git

cd compass4nfv

COMPASS_WORK_DIR=$WORKSPACE/../compass-work

mkdir -p $COMPASS_WORK_DIR
ln -s $COMPASS_WORK_DIR work

sudo docker rm -f `sudo docker ps | grep compass | cut -f1 -d' '` || true

curl -s http://people.linaro.org/~yibo.cai/compass/compass4nfv-arm64-fixup.sh | bash || true

./build.sh

exit 0
