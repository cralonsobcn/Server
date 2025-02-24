#!/usr/bin/env bash

###################ACTIONS###################
# This Script does the following actions
# 1. Installs docker, docker compose and git
# 2. Creates application folders depending the role of the host machine
# 3. Updates hostnames in /etc/hosts
# 4. 
#############################################

nas_name=""
server_name=""
security_name=""
server_ip=""
security_ip=""
nas_ip=""

# If docker-ce.repo is not present download it and add it to /etc/yum.repos.d/
if [[ ! -f "/etc/yum.repos.d/docker-ce.repo" ]]; then
    echo "Adding /etc/yum.repos.d/ repo @ /etc/yum.repos.d/"
    dnf config-manager add-repo --from-repofile=https://download.docker.com/linux/rhel/docker-ce.repo
else 
    echo "docker-ce.repo already present in the system"
fi

# Install docker packages
packages=("docker-ce" "docker-ce-cli" "containerd.io" "docker-compose-plugin")
for package in ${packages[@]}; do # Loop through the list of packages and install them if they're not present
    if [[ ! $(dnf list --installed ${package}) ]]; then
        dnf -y install ${package}
    else
        echo "${package} is already installed"
    fi
done

# Install Git
if [[ ! $(dnf list --installed "git") ]]; then
    dnf -y install git
else
    echo "Git is already installed"
fi

# Check if user is in the docker group (sudo-less docker)
if [[ ! $(groups ${hostname} | grep "docker") ]]; then
    usermod -a -G docker $(whoami)
else
    echo "User is already included in the docker group"
fi

# If this script is executed in the NAS, install the VPN as well


# Actions to be done as per appliance purpose basis
security_actions(){

    # Application folders within the security appliance
    folders=("pihole/" "/authelia/" "traefik/" "traefik/config" "traefik/config/certs" "traefik/config/logs")
    # If any of the security folders do not exist, create under the Home directory and change the owner and group to the USER's
    for folder in ${folders[@]}; do
        if [[ ! -d "${HOME}/${folder}" ]]; then
            echo "Creating directory ${HOME}/${folder}"
            mkdir "${HOME}/${folder}"
            echo "Updating the ownership of the directory to ${USER}"
            chown -R ${USER}:${USER} "${HOME}/${folder}"
        else
            echo "Directory ${HOME}/${folder} already exists"
        fi
    done

    modify_hosts()
    # TODO /etc/resolv.conf  # Careful this is handled via NetworkManager
}

nas_actions(){
    
    # Add the VPN client repo and install it 
    if [[ ! $(dnf list --installed "mullvad-vpn") ]]; then
        dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo
        dnf install -y mullvad-vpn
    else
        echo "Current system is not nas"
    fi

    # TODO Application folders within the nas appliance
    modify_hosts()
    # TODO /etc/resolv.conf  # Careful this is handled via NetworkManager
}

server_actions(){

    # Application folders within the server appliance
    folders=("changedetection/" "code-server/" "grafana/" "homepage/" "homepage/config" "homepaeg/config/images" "jellyseerr" "jellyseerr/config" "prometheus/" "prometheus/config" "radarr/" "readarr/" "sonarr/" "stirlingPDF/" "uptime_kuma/")
    # If any of the security folders do not exist, create under the Home directory and change the owner and group to the USER's
    for folder in ${folders[@]}; do
        if [[ ! -d "${HOME}/${folder}" ]]; then
            echo "Creating directory ${HOME}/${folder}"
            mkdir "${HOME}/${folder}"
            echo "Updating the ownership of the directory to ${USER}"
            chown -R ${USER}:${USER} "${HOME}/${folder}"
        else
            echo "Directory ${HOME}/${folder} already exists"
        fi
    done

    modify_hosts()
    # TODO /etc/resolv.conf  # Careful this is handled via NetworkManager
}

modify_hosts(){ # TODO get static IP from each appliance

    # Refactor this. 100% sure that there's a way to make this acceptable
    echo "${server_ip}  ${server_name}" >> /etc/hosts
    echo "${security_ip}  ${security_name}" >> /etc/hosts
    echo "${nas_ip}  ${nas_name}" >> /etc/hosts
}