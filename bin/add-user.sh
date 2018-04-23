#!/usr/bin/env bash

set -o errexit

. $(dirname $0)/iq-cli

USERID=""
PW=$(openssl rand -base64 12)

usage(){
  cat <<EOF
Add a local user to IQ
Usage: add-user.sh [-p password] <username> <first name> <last name> <email>
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

 while getopts "h?p:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    p)
        PW=$OPTARG
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [[ $# -lt 4 ]]; then
    fail "incorrect number of arguments"
  fi

  USERID=$1
  FNAME=$2
  LNAME=$3
  EMAIL=$4

}

main() {
  init $*
  cat <<EOF |
{
  "id":null,
  "username": "$USERID",
  "password":"$PW",
  "firstName": "$FNAME",
  "lastName": "$LNAME",
  "email": "$EMAIL"
}
EOF
  rest_client POST user
  echo 
  echo $?

  printf "username:%s\tpassword:%s:%s\n" $USERID $PW

}

main $*
