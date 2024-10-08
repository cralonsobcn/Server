# Home Server
This public repo contains the script I use too set up my linux home server. 

Although I deploy the services in a virtualized test environment first, I'm actively modifying the script in order to harden the security and automate the deployment in my production environment later.

For security reasons, I'm not commiting my .env files in this repo.

# Virtualization
The test environment is a virtualized Ubuntu Server running in Virtual Box bridged to the host machine. The production environment is a Beelink Mini S12 with an Intel N95, 8GB DDR4 and a 256GB SSD running Ubuntu Server.

# Containerization
[Docker](https://docs.docker.com/get-started/get-docker/) is the container orchestration application that runs all the apps of my home server.

Note: Docker compose has been update to the v2 recently. ```apt install docker-compose-v2```

It's worth mentioning that Docker, by default, requests sudo permission for every command and hence following [this linux post-installation step]([url](https://docs.docker.com/engine/install/linux-postinstall/)) is hihgly advised.

## Docker Images
Almost all the images can be pulled from the official Docker Hub website, however I prefer [linuxserver.io](https://www.linuxserver.io/) and [github.com](https://github.com/).
- [Homepage](https://gethomepage.dev/latest/installation/docker/)
- [Jackett](https://hub.docker.com/r/linuxserver/jackett)
- [Jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)
- [Qbitorrent](https://hub.docker.com/r/linuxserver/qbittorrent)
- [Radarr](https://hub.docker.com/r/linuxserver/radarr)
- [Sonarr](https://hub.docker.com/r/linuxserver/sonarr)
- [Jellyseer](https://hub.docker.com/r/linuxserver/jellyfin)
- [IT tools](https://github.com/CorentinTh/it-tools)
- [Web Check](https://github.com/Lissy93/web-check?ref=selfh.st)
- [Code Server](https://hub.docker.com/r/linuxserver/code-server)
- [Youtube DL](https://github.com/Tzahi12345/YoutubeDL-Material?ref=selfh.st)
- [FreshRSS](https://github.com/FreshRSS/FreshRSS/tree/edge/Docker#quick-run)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Glances](https://github.com/nicolargo/glances)
- [Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
- [Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

## Deployment
As easy as typing in the terminal:

```docker compose -f server.yml --env-file my-env up -d```

## Transcoding
Some media applications such as Jellyfin require hardware acceleration. This will improve CPU usage as the main load will be carried over by the iGPU.

Since the N95 is compatible with QSV, Docker needs to be aware of the render device associated with the iGPU.

The command ```ls -l /dev/dri``` will list the render devices and eventually, the render device needs to be added in the docker compose file as a `device` argument.

Example:
```
    devices:
      - /dev/dri:/dev/dri #let the application access the render and iGPU devices
```

## TODO
- Finish the implementation of the reverse Proxy and the self signed certificates.
- Finish the implementation of pfsense running in my firewall appliance.
- Perform iperf3 test on my firewall appliance.
- Implement 2FA, IAM, ZFS and PubSub solutions.
- Implement Grafana and Prometheus, monitor and logging solutions.
- Review the Networking diagram and refine the firewall policies if necessary.

