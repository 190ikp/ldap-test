#!/usr/bin/env bash
set -euxo pipefail

source env/ldap_env.sh

export LDAP_PASSWORD
LDAP_PASSWORD="$(sudo cat /etc/ldapscripts/ldapscripts.passwd)"

export _USERNAME
_USERNAME=$1

envsubst \$_USERNAME < conf/ldap/expire_password.ldif |
ldapadd -x -D "$LDAP_ADMIN_DN" -w "$LDAP_PASSWORD"
