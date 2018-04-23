#!/usr/bin/env bash

set -o errexit

usage(){
  cat <<EOF
Add a member to the global admin role
Usage: add-admin.sh <username> <full name> <email>
EOF
}

fail() {
  echo $1 >&2
  exit 1
}

init() {

  scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

  . ${scriptdir}/iq-cli

  cd ${scriptdir}

  while getopts "h?" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [[ $# -lt 3 ]]; then
    fail "incorrect number of arguments"
  fi

  USERID=$1
  NAME=$2
  EMAIL=$3

}

get_admin_role_id() {
  rest_client GET membershipMapping/global/global \
  | sed -E 's/(^.*roleId":")(.*)(","roleName":"System Administrator".*$)/\2/'
}

main() {
  init $*

  # get role id for system administrator
  roleID=$(get_admin_role_id)

  # create updated members list w/ new member
  new_members_list=$(rest_client GET membershipMapping/global/global/ \
    | python2 -c 'from iq import *; print addMemberToAdminRole()' \
    $USERID $NAME $EMAIL)

  # put the updated members list to the role

  echo $new_members_list | rest_client PUT membershipMapping/global/global/role/${roleID}
}

main $*
