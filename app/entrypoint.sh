#!/bin/bash

setup() {
	RC=-1
	trap 'teardown' EXIT

	# Create a variable holding the init file
	INIT_DIR="/app/init/init.sh"

	# Check to see if the init folder exits
	# If it exists then run the installation script
	if [ -f "$INIT_DIR" ]; then
		# Check to see if the LDAP_HOST environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_HOST+1}" ]]; then
			export LDAP_HOST
		else
			LDAP_HOST="localhost.com"
			export LDAP_HOST
		fi

		# Check to see if the LDAP_ADMIN_PASSWORD environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_ADMIN_PASSWORD+1}" ]]; then
			export LDAP_ADMIN_PASSWORD
		else
			LDAP_ADMIN_PASSWORD="docker"
			export LDAP_ADMIN_PASSWORD
		fi

		# Check to see if the LDAP_USERNAME environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_USERNAME+1}" ]]; then
			export LDAP_USERNAME
		else
			LDAP_USERNAME="docker"
			export LDAP_USERNAME
		fi

		# Check to see if the LDAP_NAME environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_NAME+1}" ]]; then
			export LDAP_NAME
		else
			LDAP_NAME="Docker Docker"
			export LDAP_NAME
		fi

		# Check to see if the LDAP_PASSWORD environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_PASSWORD+1}" ]]; then
			export LDAP_PASSWORD
		else
			LDAP_PASSWORD="docker"
			export LDAP_PASSWORD
		fi

		# Check to see if the LDAP_SSL_CERT environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_SSL_CERT+1}" ]]; then
			export LDAP_SSL_CERT
		fi

		# Check to see if the LDAP_SSL_KEY environment variable has been set via the "docker run" command
		if [[ -n "${LDAP_SSL_KEY+1}" ]]; then
			export LDAP_SSL_KEY
		fi

		# Check to see if the TIMEZONE environment variable has been set via the "docker run" command
		if [[ -n "${TIMEZONE+1}" ]]; then
			export TIMEZONE
		fi

		/bin/bash "$INIT_DIR"
	else
		# Always start LDAP because LDAP is never started at boot
		service slapd start >/dev/null 2>&1 &

		# Start the syslog service
		rsyslogd >/dev/null 2>&1 &

		# Setting up the header script
		source /app/header.sh
	fi
}

teardown() {
	trap - EXIT
	exit $RC
}

setup
$@  # do NOT "exec $@"
RC=$?  # try to return command's exit code if it had a natural end

# Keep the container running
tail -f /var/log/ldap.log