#!/bin/bash
set -e

rm -rf compass4nfv
virsh destroy host1
virsh destroy host2
virsh destroy host3

exit 0
