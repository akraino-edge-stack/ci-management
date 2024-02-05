#!/bin/bash -ex
if apt --version 2>1 >/dev/null; then
    sudo chmod +r /boot/vmlinuz*
    if ! docker --version 2>1 >/dev/null; then
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common rename
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb http://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce
    fi
else
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum -y install docker-ce docker-ce-cli containerd.io
fi
sudo mkdir -p /etc/docker/
echo '{"experimental":true}' | sudo tee /etc/docker/daemon.json
sudo systemctl start docker
# Ugly hack to make docker usable for non-root
# (adding to the group would require re-login)
sudo chmod 777 /var/run/docker.sock
