#!/usr/bin/env bash

# Ensure "authenticated users" are in the root org development role

set -o errexit

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

. ${scriptdir}/iq-cli

cd ${scriptdir}

# get role id for development role
devRoleID=$(rest_client GET sidebar/organization/ROOT_ORGANIZATION_ID/details \
  | python2 -c 'from iq import *; print devRoleId()')

cat << EOF |
[{
  "type":"GROUP",
  "internalName":"(all-authenticated-users)",
  "displayName":"Authenticated Users",
  "email":null,
  "realm":"IQ Server"
}] 
EOF
  rest_client PUT membershipMapping/organization/ROOT_ORGANIZATION_ID/role/${devRoleID}

