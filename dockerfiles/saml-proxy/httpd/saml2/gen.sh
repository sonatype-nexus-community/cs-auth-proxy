#!/usr/bin/env bash

fqdn="localhost:8000"
mellon_endpoint_url="http://${fqdn}/mellon"
mellon_entity_id=sonatype
file_prefix="$(echo "$mellon_entity_id" | sed 's/[^A-Za-z.]/_/g' | sed 's/__*/_/g')"

/usr/libexec/mod_auth_mellon/mellon_create_metadata.sh $mellon_entity_id $mellon_endpoint_url
