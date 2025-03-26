# Home Server
This public repo contains the scripts I use too set up my home server. 

Although I deploy the services in a virtualized test environment first, I'm actively modifying the script in order to harden the security and automate the deployment in my production environment later.

For security reasons, I'm not commiting my .env files in this repo.

# Virtualization
The test environment is a virtualized Rocky Linux running in Virtual Box bridged to the host machine. The production environment is a Beelink Mini S12 with an Intel N95, 8GB DDR4 and a 256GB SSD running Rocky Linux.
![alt text](https://raw.githubusercontent.com/cralonsobcn/Server/refs/heads/main/Home%20Server%20diagram.webp)

# Containerization
[Docker](https://docs.docker.com/get-started/get-docker/) is the container management application that runs all the apps of my home server.

Installation Steps are covered in the [Rocky Linux documentation](https://docs.rockylinux.org/gemstones/containers/docker).

# Docker Images
Almost all the images can be pulled from [Docker Hub](https://hub.docker.com/), [linuxserver.io](https://www.linuxserver.io/) and [github.com](https://github.com/).

## Server
- [Homepage](https://gethomepage.dev/latest/installation/docker/)
- [Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/)
- [Radarr](https://hub.docker.com/r/linuxserver/radarr)
- [Readarr](https://docs.linuxserver.io/images/docker-readarr/)
- [Sonarr](https://hub.docker.com/r/linuxserver/sonarr)
- [Jellyseer](https://hub.docker.com/r/linuxserver/jellyfin)
- [IT tools](https://github.com/CorentinTh/it-tools)
- [Web Check](https://github.com/Lissy93/web-check?ref=selfh.st)
- [Change Detection](https://docs.linuxserver.io/images/docker-changedetection.io/#linuxserverchangedetectionio)
- [Stirling PDF](https://docs.stirlingpdf.com/Installation/Docker%20Install/)
- [Code Server](https://hub.docker.com/r/linuxserver/code-server)
- [Jsoncrack](https://github.com/AykutSarac/jsoncrack.com)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Glances](https://github.com/nicolargo/glances)
- [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
- [cAdvisor](https://prometheus.io/docs/guides/cadvisor/#docker-compose-configuration)
- [Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

## NAS
- [Jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)
- [Qbitorrent](https://hub.docker.com/r/linuxserver/qbittorrent)
- [Gitea](https://github.com/go-gitea/gitea)

## Security
- [Traefik](https://github.com/traefik/traefik)
- [Portainer](https://docs.portainer.io/start/install-ce/server/docker/linux)
- [Watchtower](https://containrrr.dev/watchtower/usage-overview/)
- [Pihole](https://hub.docker.com/r/pihole/pihole)
- [Authelia](https://www.authelia.com/integration/deployment/docker/)
- [Mullvad VPN](https://mullvad.net/es/help/install-mullvad-app-linux#fedora)

## Deployment
As easy as typing in the command:

```docker compose -f compose-file.yml up -d```

## Transcoding
Some media applications such as Jellyfin require hardware acceleration. This will improve CPU usage as the main load will be carried over by the iGPU.

Since the N95 is compatible with QSV, Docker needs to be aware of the render device associated with the iGPU.

The command ```ls -l /dev/dri``` will list the render devices and eventually, the render device needs to be added in the docker compose file as a `device` argument.

Example:
```
    devices:
      - /dev/dri:/dev/dri #let the application access the render and iGPU devices
```

### TODO
- Implement VPN.
- Perform iperf3 tests on all the devices.
- Migrate env passwords to secrets.
- Implement 2FA and IAM with Authelia.
- Implement ZFS.
- Implement ntfy.
- Implement Prometheus scrappers.
- Implement Grafana.
- Implement cronjob to prune unused images and unused volumes.
- Review the Networking diagram + validate and refine the firewall policies.