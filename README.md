#  🛡️ AdGuardHome static compiled in a scratch container

[![Build Status](https://gitlab.com/lansible1/docker-adguardhome/badges/master/pipeline.svg)](https://gitlab.com/lansible1/docker-adguardhome/pipelines)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/adguardhome.svg)](https://hub.docker.com/r/lansible/adguardhome)
[![Docker Version](https://img.shields.io/docker/v/lansible/adguardhome?sort=semver)](https://hub.docker.com/r/lansible/adguardhome)
[![Docker Image Size](https://img.shields.io/docker/image-size/lansible/adguardhome?sort=semver)](https://hub.docker.com/r/lansible/adguardhome)

## Running the container

The default configuration has `admin:admin` set as credentials. See these instructions on how to change this (in the config dir or k8s configmap):
https://github.com/AdguardTeam/Adguardhome/wiki/Configuration#reset-web-password

When using this docker run or docker-compose make sure the volume directories are writeable by user 1000 (chown -R 1000:1000 /my/own/workdir /my/own/confdir).
By default docker creates those as the root user and that will not work.

Simple non persistent setup to just run DNS (53) and the webinterface (3000)
```
docker run --name adguardhome\
    --restart unless-stopped\
    -p 53:53/tcp -p 53:53/udp -p 3000:3000/tcp\
    -d lansible/adguardhome:latest
```

Full example based on the upstream docs:
```
docker run --name adguardhome\
    --restart unless-stopped\
    -v /my/own/workdir:/opt/adguardhome/work\
    -v /my/own/confdir:/opt/adguardhome/conf\
    -p 53:53/tcp -p 53:53/udp\
    -p 67:67/udp -p 68:68/udp\
    -p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp\
    -p 853:853/tcp\
    -p 784:784/udp -p 853:853/udp -p 8853:8853/udp\
    -p 5443:5443/tcp -p 5443:5443/udp\
    -d lansible/adguardhome:latest
```

Also see the `examples\` directory for a docker-compose and Kubernetes example.

## Credits

* [AdguardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)
