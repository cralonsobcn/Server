#!/usr/bin/env bash

# If docker-ce.repo is not present download it and add it to /etc/yum.repos.d/
if [[ ! -f "/etc/yum.repos.d/docker-ce.repo" ]]; then
    echo "Adding /etc/yum.repos.d/ repo @ /etc/yum.repos.d/"
    dnf config-manager add-repo --from-repofile=https://download.docker.com/linux/rhel/docker-ce.repo
else 
    echo "docker-ce.repo already present in the system"
fi

# Install docker and docker compose
if [[ ! $(dnf list --installed "docker-ce") ]]; then
    dnf -y install docker-ce
elif [[ ! $(dnf list --installed "docker-ce-cli") ]]; then
    dnf -y install docker-ce-cli
elif [[ ! $(dnf list --installed "containerd.io") ]]; then
    dnf -y install containerd.io
elif [[ ! $(dnf list --installed "docker-compose-plugin") ]]; then
    dnf -y install docker-compose-plugin
else
    echo "Docker and Docker compose is already installed"
fi

# Check if user is in the docker group (sudo-less docker)
if [[ ! $(groups ${hostname} | grep "docker") ]]; then
    usermod -a -G docker $(whoami)
else
    echo "User is already in the docker group"
fi

# If this script is executed in the NAS, install the VPN as well
if [[ $(hostname) = "nas" && ! $(dnf list --installed "mullvad-vpn") ]]; then
    dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo
    dnf install -y mullvad-vpn
else
    echo "Current system is not nas"
fi