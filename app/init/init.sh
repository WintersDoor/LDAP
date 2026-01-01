#!/bin/bash

# Setting up the output script
source /app/output.sh

# Setting up the header script
source /app/header.sh

# Output the script initialization step
outputDate "Starting to setup the OpenLDAP container!"

# Set the run level to 1 which is basically "system level access"
export RUNLEVEL=1

# Split the LDAP_HOST variable by periods
DN=(${LDAP_HOST//./ })

# Assign static ADMINDN variable
ADMINDN="cn=admin"

# Create an empty BASEDN variable so we can attach values to it below
BASEDN=""

# Loop through the DN array
for i in "${DN[@]}"
do
	ADMINDN+=",dc=$i" # Construct the admin DN string
	BASEDN+="dc=$i," # Construct the base DN string
done

# Trim the trailing comma
BASEDN=$(echo "$BASEDN" | sed 's:,*$::')

echo "slapd slapd/password1 password $LDAP_ADMIN_PASSWORD" >> /app/init/debconf-slapd.conf
echo "slapd slapd/internal/adminpw password $LDAP_ADMIN_PASSWORD" >> /app/init/debconf-slapd.conf
echo "slapd slapd/internal/generated_adminpw password $LDAP_ADMIN_PASSWORD" >> /app/init/debconf-slapd.conf
echo "slapd slapd/password2 password $LDAP_ADMIN_PASSWORD" >> /app/init/debconf-slapd.conf
echo 'slapd slapd/unsafe_selfwrite_acl note' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/purge_database boolean false' >> /app/init/debconf-slapd.conf
echo "slapd slapd/domain string $LDAP_HOST" >> /app/init/debconf-slapd.conf
echo 'slapd slapd/ppolicy_schema_needs_update select abort installation' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/invalid_config boolean true' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/move_old_database boolean false' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/backend select MDB' >> /app/init/debconf-slapd.conf
echo "slapd shared/organization string $LDAP_HOST" >> /app/init/debconf-slapd.conf
echo 'slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/no_configuration boolean false' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/dump_database select when needed' >> /app/init/debconf-slapd.conf
echo 'slapd slapd/password_mismatch note' >> /app/init/debconf-slapd.conf

export DEBIAN_FRONTEND=noninteractive
cat /app/init/debconf-slapd.conf | debconf-set-selections

if [[ -n "${TIMEZONE+1}" ]]; then
	if [[ "$TIMEZONE" == *"/"* ]]; then
		ln -fs /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
		sudo dpkg-reconfigure --frontend noninteractive tzdata
	else
		outputDate 'Please specify a correct timezone for tzdata to apply'
	fi
else
	outputDate 'Timezone was not passed'
fi

outputDate "Installing required packages... This may take a few minutes!"

# Install LDAP, ldap-utils, vim, apt-utils, and the SSL stuff here because apparently they still aren't installed from the Dockerfile
apt-get -y install slapd ldap-utils vim apt-utils apt-transport-https ca-certificates openssl > /dev/null

outputDate "Packages have been installed!"

outputDate "Starting to configure OpenLDAP server..."

# Create empty LDAP log file first
touch /var/log/ldap.log

# Giving syslog the ownership to the LDAP log
chown syslog:syslog /var/log/ldap.log

# Replace the baseDN placeholder with the correct DN in all of the files below
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/basedn.ldif"
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/ppolicy.ldif"
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/ppolicy_group.ldif"
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/ppolicy_overlay.ldif"
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/ldapgroups.ldif"
perl /app/init/update_files.pl "baseDN" "$BASEDN" "/app/init/ldapusers.ldif"

# Add our base DN
ldapadd -x -D "$ADMINDN" -w "$LDAP_ADMIN_PASSWORD" -f /app/init/basedn.ldif > /dev/null 2>&1

# Append to the end of the ldap.conf file
echo "TLS_REQCERT allow" >> /etc/ldap/ldap.conf

# Set LDAP log file
echo "logfile /var/log/ldap.log" >> /etc/ldap/ldap.conf

# Enable logging
echo "loglevel    256" >> /etc/ldap/ldap.conf

# Load the ppolicy module
# We may not need this since it seems to have already been loaded
# ldapadd -Y EXTERNAL -H ldapi:/// -f /app/init/load_ppolicy.ldif > /dev/null

# Update LDAP to allow the memberOF overlay
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /app/init/memberof_config.ldif > /dev/null 2>&1
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /app/init/refint1.ldif > /dev/null 2>&1
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /app/init/refint2.ldif > /dev/null 2>&1

# Enables logs
ldapmodify -Y EXTERNAL -H ldapi:/// -f /app/init/log.ldif > /dev/null 2>&1

# Copies the 10-slapd.conf file to the rsyslog.d folder
cp /app/init/10-slapd.conf /etc/rsyslog.d/

# Get the uniquely generated LDAP password using LDAP's hashing feature
encryptedPassword=$(slappasswd -s $LDAP_PASSWORD)

# Split the full name of the user's account into an array based on spaces
fullName=($LDAP_NAME)

# Replace all user placeholder information with the provided user information from the "docker run" command
perl /app/init/update_files.pl "docker" "${encryptedPassword}" "/app/init/ldapusers.ldif"
perl /app/init/update_files.pl "fullName" "$LDAP_NAME" "/app/init/ldapusers.ldif"
perl /app/init/update_files.pl "firstName" "${fullName[0]}" "/app/init/ldapusers.ldif"
perl /app/init/update_files.pl "lastName" "${fullName[1]}" "/app/init/ldapusers.ldif"
perl /app/init/update_files.pl "username" "$LDAP_USERNAME" "/app/init/ldapusers.ldif"
perl /app/init/update_files.pl "username" "$LDAP_USERNAME" "/app/init/ldapgroups.ldif"

# Add the users OU using the ldapusers.ldif file
ldapadd -x -D "$ADMINDN" -w "$LDAP_ADMIN_PASSWORD" -f /app/init/ldapusers.ldif > /dev/null 2>&1

# Add the groups OU using the ldapgroups.ldif file
ldapadd -x -D "$ADMINDN" -w "$LDAP_ADMIN_PASSWORD" -f /app/init/ldapgroups.ldif > /dev/null 2>&1

# Update the LDAP server to allow a password policy to be put in place so that you can restrict how many failed log in attempts a user can have
ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /app/init/load_ppolicy.ldif > /dev/null 2>&1
ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /app/init/ppolicy_module.ldif > /dev/null 2>&1
ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /app/init/ppolicy_overlay.ldif > /dev/null 2>&1

# This is the only one that's different that needs to be added this way
ldapadd -x -D "$ADMINDN" -w "$LDAP_ADMIN_PASSWORD" -f /app/init/ppolicy.ldif > /dev/null 2>&1

# Check to see if the LDAP_SSL_CERT and LDAP_SSL_KEY environment variable are set via the "docker run" command
if [[ -n "${LDAP_SSL_CERT+1}" && -n "${LDAP_SSL_KEY+1}" ]]; then
	outputDate "SSL set"
	# Copy SSL certs to the ca-certificates.crt file
	cp "$LDAP_SSL_KEY" /etc/ldap/sasl2/
	cp "$LDAP_SSL_CERT" /etc/ldap/sasl2/
	cp /etc/ssl/certs/ca-certificates.crt /etc/ldap/sasl2/
	outputDate "Successfully copied provided SSL certificates for LDAP server"
else
	outputDate "SSL not set"
	# Generate the SSL certificates
	openssl genrsa -out /app/ssl/ldap_server_ca.key 2048 > /dev/null 2>&1
	openssl req -new -x509 -days 365 -key /app/ssl/ldap_server_ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out /app/ssl/ldap_server_ca.crt > /dev/null 2>&1
	openssl req -newkey rsa:2048 -nodes -keyout /app/ssl/ldap_server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=*.$LDAP_HOST" -out /app/ssl/ldap_server.csr > /dev/null 2>&1
	openssl x509 -req -extfile <(printf "subjectAltName=DNS:$LDAP_HOST,DNS:www.$LDAP_HOST") -days 365 -in /app/ssl/ldap_server.csr -CA /app/ssl/ldap_server_ca.crt -CAkey /app/ssl/ldap_server_ca.key -CAcreateserial -out /app/ssl/ldap_server.crt > /dev/null 2>&1
	# Copy SSL certs to the ca-certificates.crt file
	cp /app/ssl/ldap_server.key /etc/ldap/sasl2/
	cp /app/ssl/ldap_server.crt /etc/ldap/sasl2/
	cp /etc/ssl/certs/ca-certificates.crt /etc/ldap/sasl2/
	outputDate "Successfully generated self-signed certificates for LDAP server"
fi

# Chown sasl2 folder using LDAP's user account
chown -R openldap:openldap /etc/ldap/sasl2

# Copy the slapd file to the appropriate folder location
cp /app/etc/default/slapd /etc/default/slapd

# Append to the end of the ldap.conf file
echo "TLS_REQCERT allow" >> /etc/ldap/ldap.conf

# Set LDAP log file
echo "logfile /var/log/ldap.log" >> /etc/ldap/ldap.conf

# Enable logging
echo "loglevel    256" >> /etc/ldap/ldap.conf

# Update the LDAP SSL configurations
ldapmodify -Y EXTERNAL -H ldapi:/// -f /app/init/ldap_ssl.ldif > /dev/null 2>&1

# Copy the ldap_disable_bind_anon.ldif file to the appropriate folder location
cp /app/usr/share/slapd/ldap_disable_bind_anon.ldif /usr/share/slapd/ldap_disable_bind_anon.ldif

# Disable anonymous binding
ldapadd -Y EXTERNAL -H ldapi:/// -f /usr/share/slapd/ldap_disable_bind_anon.ldif > /dev/null 2>&1

# Update the LDAP SSL configurations
ldapmodify -Y EXTERNAL -H ldapi:/// -f /app/init/ldap_ssl.ldif > /dev/null 2>&1

outputDate "OpenLDAP server has been configured!"
outputDate "Starting LDAP services..."

# Delete the init folders since we no longer need them
rm -rf /app/init
rm -rf /app/etc
rm -rf /app/usr

# Killing all LDAP services because there seems to be an issue where the LDAP services won't properly restart
# And restarting the service will fail due to an LDAP service already running.
killall -9 slapd

# Restarts the LDAP service
service slapd restart >/dev/null 2>&1 &

# Start the syslog service
rsyslogd >/dev/null 2>&1 &

outputDate "LDAP services have been started!"
outputDate "The OpenLDAP container is ready for use!"