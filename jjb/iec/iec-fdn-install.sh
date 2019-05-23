#!/bin/bash
set -e

sleep 10
echo "Start IEC installation:"
rm -rf iec
rm -rf ~/.ssh/known_hosts

git clone "https://gerrit.akraino.org/r/iec"

cd iec/src/foundation/scripts

sed -i.bak 's/10.169.36.152/10.1.0.50/g' ./config
sed -i "/^K8S_MASTERPW=/cK8S_MASTERPW=\"root\"" ./config
sed -i "/^HOST_USER=/cHOST_USER=\${HOST_USER:-root}" ./config
sed -i "s/10.169.40.106,123456/10.1.0.51,root\"\n\"10.1.0.52,root/g" ./config
HOST_USER=root
export HOST_USER
sudo ./startup.sh


exit 0
