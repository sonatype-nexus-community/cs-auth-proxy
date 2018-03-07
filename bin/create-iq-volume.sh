#!/usr/bin/env bash
#
# create data container w/ license and sample policies on vanilla iq server
#

set -o errexit

POLICY_URL=${POLICY_URL:=https://books.sonatype.com/sonatype-clm-book/resources/Sonatype-Sample-Policy-Set-1.22.json}

container_id=""
container_ip=""

usage() {
  cat <<EOF >&2
USAGE: create-iq-volume <license file>

DESCRIPTION

Create a new, populated volume for use w/ jswank/iq-server.  The volume is populated
with the sample policy (URL defined via env variable POLICY_URL) and the license
specified.

EXAMPLES

  $ ./create-iq-volume sonatype-dev-nexus-firewall-bundle-2015.lic

  $ POLICY_URL=https://books.sonatype.com/sonatype-clm-book/resources/Sonatype-Sample-Policy-Set-1.22.json \
    ./create-iq-volume sonatype-dev-nexus-firewall-bundle-2015.lic

ENVIRONMENT

  POLICY_URL defaults to $POLICY_URL


EOF
}

init() {

  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  if [[ ! -f $1 ]]; then
    usage
    exit 1
  fi

  license_file=$1

  if docker volume ls -q |grep -q iq-server-data; then
    echo 'iq-server-data docker volume exists; to remove it, run "docker volume rm iq-server-data"' >&2
    exit 1
  fi
  
  is_darwin=false
  if [ "$(uname)" == "Darwin" ]; then
    is_darwin=true
  fi

  tmpdir=$(mktemp -d)

}

cleanup() {

  if [[ -d $tmpdir ]]; then
    rm -rf $tmpdir
  fi

  if [[ -n "$container_id" ]]; then
    echo -n "killing scratch container" >&2
    docker kill -s HUP $container_id >/dev/null
    while [ 1 ]; do
      echo -n "." >&2
      docker inspect -f '{{.State.Running}}' $container_id |grep -q -v "true" && break
      sleep 2
    done
    echo " done." >&2
    echo "removing scratch container" >&2
    docker rm $container_id >/dev/null
  fi

}

fetch_policy() {
  echo "fetching policy from $POLICY_URL" >&2
  curl -f -s -o $tmpdir/policy.json $POLICY_URL
}

create_volume() {
  echo "creating volume iq-server-data" >&2
  docker volume create --label iq-server-data --name iq-server-data >/dev/null
}

start_iq_server() {
  echo "starting scratch container" >&2

  if [ "$is_darwin" = true ]; then
    container_id=$(docker run -d -v iq-server-data:/sonatype-work -e JVM_OPTIONS="-server -Ddw.csrfProtection=false" -p 8070:8070 -p 8071:8071 jswank/iq-server)
    container_ip="127.0.0.1"
  else
    container_id=$(docker run -d -v iq-server-data:/sonatype-work -e JVM_OPTIONS="-server -Ddw.csrfProtection=false" jswank/iq-server)
    container_ip=$(docker inspect  -f '{{ .NetworkSettings.IPAddress }}' $container_id)
  fi
}

function wait_for_iq {
  echo -n "waiting for iq-server to become available" >&2
  # eventually, iq starts.  once it does, update its license
  while [ 1 ]; do
    docker inspect $container_id >/dev/null || ( echo "the iq container is not running: exiting" && exit )
    curl --output /dev/null --silent --fail http://${container_ip}:8071/healthcheck && break
    echo -n "." >&2
    sleep 5
  done
  echo " done." >&2
}

apply_license() {
  echo "applying license" >&2
  curl --fail -s -u 'admin:admin123' -F file=@$license_file http://${container_ip}:8070/rest/product/license >/dev/null
}

load_policy() {
  echo "loading policy" >&2
  curl --fail -s -u 'admin:admin123' -F file=@${tmpdir}/policy.json http://${container_ip}:8070/rest/policy/organization/ROOT_ORGANIZATION_ID/import >/dev/null
}

add_root_organization_access() {
  echo "add root organization access" >&2
  ownerRoleId=$(curl -s --fail  -u 'admin:admin123' http://${container_ip}:8070/api/v2/applications/roles | sed -E 's/(^.*id":")(.*)(","name":"Owner".*$)/\2/')
  curl -s --fail -u 'admin:admin123' -X PUT -H "Content-type: application/json" \
      http://${container_ip}:8070/api/v2/organizations/ROOT_ORGANIZATION_ID/roleMembers \
      -d "{\"memberMappings\":[{\"roleId\":\"$ownerRoleId\",\"members\":[{\"type\":\"GROUP\",\"userOrGroupName\":\"administrator\"}]}]}"
}

configure_ldap() {
  echo "configuring ldap" >&2
  # add ldap
  resp=$(curl -s --fail -u 'admin:admin123' -X POST -H "Content-type: application/json" \
    http://${container_ip}:8070/rest/config/ldap \
    -d '{"$new":true,"id":null,"name":"ldap"}')
  # response: {"id":"a2908e08fb40400fa35fdcbbeff6afcd","name":"ldap","nameLowercaseNoWhitespace":"ldap"}

  # super awesome json parse to get the id
  if [ "$is_darwin" = true ]; then
    id=$(echo $resp | sed -E 's/(^{"id":")(.*)(","name".*)/\2/')
  else
    id=$(echo $resp | grep -Po '"'"id"'"\s*:\s*"\K([^"]*)')
  fi
  
  # add basic connection info
  curl -s --fail -u 'admin:admin123' -X PUT -H "Content-type: application/json" \
    http://${container_ip}:8070/rest/config/ldap/$id/connection \
    -d "{\"id\":null,\"serverId\":\"$id\",\"protocol\":\"LDAP\",\"hostname\":\"ldap\",\"port\":389,\"searchBase\":\"dc=sse,dc=sonatype,dc=com\",\"authenticationMethod\":\"SIMPLE\",\"saslRealm\":\"\",\"systemUsername\":\"cn=root,dc=sse,dc=sonatype,dc=com\",\"systemPassword\":\"eatmyshorts\",\"connectionTimeout\":30,\"retryDelay\":30}"  >/dev/null

  # add user / group configuration
  curl -s --fail -u 'admin:admin123' -X PUT -H "Content-type: application/json" \
    http://${container_ip}:8070/rest/config/ldap/$id/userMapping \
    -d "{\"id\":null,\"serverId\":\"$id\",\"userBaseDN\":\"ou=users\",\"userSubtree\":false,\"userObjectClass\":\"inetOrgPerson\",\"userFilter\":\"\",\"userIDAttribute\":\"cn\",\"userRealNameAttribute\":\"displayName\",\"userEmailAttribute\":\"mail\",\"userPasswordAttribute\":\"userPassword\",\"groupMappingType\":\"STATIC\",\"groupBaseDN\":\"ou=groups\",\"groupSubtree\":false,\"groupObjectClass\":\"groupOfUniqueNames\",\"groupIDAttribute\":\"cn\",\"groupMemberAttribute\":\"uniqueMember\",\"groupMemberFormat\":\"cn=\${username},ou=users,dc=sse,dc=sonatype,dc=com\",\"userMemberOfGroupAttribute\":null,\"dynamicGroupSearchEnabled\":true}" >/dev/null

  # get the System Administrator role id
  roleid=$(curl -s --fail -u 'admin:admin123' http://${container_ip}:8070/rest/membershipMapping/global/global | sed -E 's/(^.*roleId":")(.*)(","roleName":"System Administrator".*$)/\2/')

  # add ldap admininstrator group as system admin
  if [[ -n "$id" ]]; then
    curl -s --fail -u 'admin:admin123' -X PUT -H "Content-type: application/json" \
      http://${container_ip}:8070/rest/membershipMapping/global/global/role/$roleid \
      -d '[{"type":"USER","internalName":"admin","displayName":"Admin BuiltIn","email":"admin@localhost","realm":"IQ Server"},{"type":"GROUP","displayName":"administrator","internalName":"administrator","email":null,"realm":"ldap"}]'
  fi

}

main() {

  init $@

  trap cleanup INT TERM EXIT

  fetch_policy
  create_volume
  start_iq_server
  wait_for_iq

  apply_license
  sleep 10
  load_policy
  add_root_organization_access
  configure_ldap
  echo "volume creation complete" >&2 && exit 0

}

main $@
