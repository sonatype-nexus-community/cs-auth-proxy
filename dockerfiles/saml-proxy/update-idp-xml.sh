#!/usr/bin/env bash

set -o errexit

URL=http://keycloak:8080/auth/realms/sonatype/protocol/saml/descriptor
FILENAME=/etc/httpd/saml2/idp-metadata.xml

until curl -f -s -o /dev/null -f $URL; do
  >&2 echo "keycloak is unavailable - sleeping"
  sleep 5
done

>&2 echo "keycloak is up - retrieving idp descriptor"

curl -s -o $FILENAME $URL

sed -e 's|keycloak:8080|localhost:8080|g' -i $FILENAME

exec /run-httpd.sh
