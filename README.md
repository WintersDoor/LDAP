# The OpenLDAP image

The purpose of this image is to allow users the ability to create an LDAP server that's already customized that they can then just plug and play. This image has been configured to come with the following

- memberOf overlay
- PPolicy (Password Policy) - Configured with lock out at 3 failed attempts, obviously this can be changed
- Configured users OU, Service Accounts OU, and groups OU
- Automatically generated self-signed certificates based on the `LDAP_HOST` environment variable you provide

```
********************************************************************************************************************************

   ____                   __    ____  ___    ____     ______            __        _                
  / __ \____  ___  ____  / /   / __ \/   |  / __ \   / ____/___  ____  / /_____ _(_)___  ___  _____
 / / / / __ \/ _ \/ __ \/ /   / / / / /| | / /_/ /  / /   / __ \/ __ \/ __/ __ `/ / __ \/ _ \/ ___/
/ /_/ / /_/ /  __/ / / / /___/ /_/ / ___ |/ ____/  / /___/ /_/ / / / / /_/ /_/ / / / / /  __/ /    
\____/ .___/\___/_/ /_/_____/_____/_/  |_/_/       \____/\____/_/ /_/\__/\__,_/_/_/ /_/\___/_/     
    /_/                                                                                            
********************************************************************************************************************************

Default ports
   - 22 (SSH)
   - 389 (NON-SSL)
   - 636 (SSL)

********************************************************************************************************************************

Welcome to the OpenLDAP container!

********************************************************************************************************************************
```

## Version

Current image version: 0.3

## How To Install

It's very simple to install. Be sure to have Docker installed on your machine and run the Docker command below. Be sure to edit the settings accordingly to your own.

```
docker run --detach \
  --hostname ldap.localhost.com \
  --name ldap \
  --restart always \
  --privileged \
  --publish 389:389 --publish 636:636 \
  -e LDAP_HOST='localhost.com' \
  -e LDAP_ADMIN_PASSWORD='ADMIN_PASSWORD' \
  -e LDAP_USERNAME='docker' \
  -e LDAP_NAME='Docker Docker' \
  -e LDAP_PASSWORD='DOCKER_PASSWORD' \
  -e TIMEZONE='America/New_York' \
  wintersdoor/ldap:latest
```

To use your own certificates, please create a new folder that you can mount to the container

```
docker run --detach \
  --hostname ldap.localhost.com \
  --name ldap \
  --restart always \
  --privileged \
  --publish 389:389 --publish 636:636 \
  -e LDAP_HOST='localhost.com' \
  -e LDAP_ADMIN_PASSWORD='ADMIN_PASSWORD' \
  -e LDAP_USERNAME='docker' \
  -e LDAP_NAME='Docker Docker' \
  -e LDAP_PASSWORD='DOCKER_PASSWORD' \
  -e TIMEZONE='America/New_York' \
  -e LDAP_SSL_CERT='/app/ssl/ldap_server.crt' \
  -e LDAP_SSL_KEY='/app/ssl/ldap_server.key' \
  -v /var/www/certs:/app/ssl \
  wintersdoor/ldap:latest
```

## Required Arguments

The list below are required arguments that you **must** supply the `docker run` command with otherwise the container will break.

- `--publish` or `-p`: with both **389** and **636** ports
- `LDAP_HOST`: FQN that uniquely identifies the host. This is the hostname in other terms. Default: **localhost.com**
- `LDAP_ADMIN_PASSWORD`: LDAP database admin password. Default: **docker**
- `LDAP_NAME`: LDAP user full name. Default: **Docker Docker**
- `LDAP_USERNAME`: LDAP user account. Default: **docker**
- `LDAP_PASSWORD`: LDAP user password. Default: **docker**
- `TIMEZONE`: Timezone used for the container. This should reflect the timezone the container is hosted on. Default: **Universal Time**

## Optional Arguments

The list below are optional arguments you can supply the `docker run` command with.

- `LDAP_SSL_CERT`: The full file path within the container for the SSL certificate. e.g. `LDAP_SSL_CERT='/app/ssl/ldap_server.crt'`
- `LDAP_SSL_KEY`: The full file path within the container for the SSL certificate key. e.g. `LDAP_SSL_KEY='/app/ssl/ldap_server.key'`
- `--volume` or `-v`: The mounted drive from the host machine to the container.

If you are creating the container in a non-amd64 system, please attach this flag to the `docker run` command

- `--platform=linux/amd64`: This sets the architecure type to be linux/amd64 to correlate with the base Ubuntu image we're using.

## Recommended Software

It is recommended to use an LDAP tool like [Apache Directory Studio](https://directory.apache.org/studio/) to log into your container.

# Docker Hub Link
https://hub.docker.com/r/wintersdoor/ldap

# BUGS & REPORTS

For any bugs or issues, please visit the [Issues](https://github.com/WintersDoor/LDAP/issues) tab.