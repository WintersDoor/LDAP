# Import from base image out there on the Docker hub
FROM ubuntu:latest

# Set the maintainer settings
LABEL company="Winters Door"
LABEL version="0.3"
LABEL maintainer="NamelessArmy"
LABEL description="An OpenLDAP Docker container with SSL support"
LABEL url="https://github.com/wintersdoor/ldap"
LABEL license="MIT"

# Set the runlevel to 1
ENV RUNLEVEL=1

# Change to the root user
USER root

# Run these commands
	# Update the system
	# Install software-properties-common, lsb-release, apt-transport-https, ca-certificates, wget, sudo, htop, openssh-server, vim, net-tools, zip, git, inetutils-ping, apache2-utils, and rsyslog
	# Update the system

RUN apt-get -y update && \
	apt-get -y install apt-utils software-properties-common lsb-release apt-transport-https ca-certificates wget sudo htop openssh-server vim net-tools zip git inetutils-ping apache2-utils rsyslog && \
	apt-get -y update && \
	printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

# Create working directory on the image
WORKDIR /app

# Copy all files from the local app folder into the image's base directory
COPY app .

# Copy both the etc and usr folders to the /app folder
COPY conf/etc /app/etc
COPY conf/usr /app/usr

# Recursively deletes all .DS_Sore files within the system
RUN find . -name ".DS_Store" -delete

# Exposes the SSH port
EXPOSE 22

# Exposes the default LDAP port
EXPOSE 389

# Exposes the SSL port for LDAP
EXPOSE 636

# Run the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "/app/entrypoint.sh"]