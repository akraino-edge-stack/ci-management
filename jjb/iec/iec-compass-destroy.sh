#!/bin/bash
set -e

rm -rf compass4nfv
sudo virsh destroy host1
sudo virsh destroy host2
sudo virsh destroy host3

exit 0
