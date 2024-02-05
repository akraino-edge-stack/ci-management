#!/bin/bash -ex
if apt --version 2>1 >/dev/null; then
    if ! createrepo --version 2>1 >/dev/null; then
        sudo apt update
        sudo apt install -y createrepo libguestfs-tools jq libvirt-daemon-system
    fi
else
    sudo yum -y install createrepo libguestfs-tools-c jq
fi
sudo systemctl start libvirtd
systemctl status libvirtd
