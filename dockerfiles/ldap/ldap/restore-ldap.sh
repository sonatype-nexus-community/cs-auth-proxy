#!/usr/bin/env bash

# import a backup ldap schema and database
# IMPORTANT: this overwrites any existing LDAP directory on localhost
# this script should be run as root

set -o errexit
set -o nounset

mv /etc/openldap /etc/openldap.`date +%Y%m%d`-$$
mv /var/lib/ldap /var/lib/ldap.`date +%Y%m%d`-$$
mkdir -p /etc/openldap/slapd.d
mkdir /var/lib/ldap

slapadd -F /etc/openldap/slapd.d -b cn=config -l /tmp/config.master.ldif

slapadd -F /etc/openldap/slapd.d -b dc=sse,dc=sonatype,dc=com -l /tmp/dc.ldif

cp /tmp/DB_CONFIG /var/lib/ldap/

chown -R ldap:ldap /etc/openldap/slapd.d
chown -R ldap:ldap /var/lib/ldap
