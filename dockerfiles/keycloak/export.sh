#!/usr/bin/env bash

keycloak/bin/standalone.sh \
  -Dkeycloak.migration.action=export \
  -Dkeycloak.migration.provider=singleFile \
  -Dkeycloak.migration.file=/tmp/sonatype-realm.json \
  -Dkeycloak.migration.realmName=sonatype \
  -Dkeycloak.migration.usersExportStrategy=REALM_FILE
