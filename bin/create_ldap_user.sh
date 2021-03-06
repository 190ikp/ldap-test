#!/usr/bin/env bash
set -euo pipefail

source env/ldap_env.sh

# functions are ported from /usr/share/ldapscripts/runtime
get_last_uid() {
  ldapsearch -LLL -x -ZZ \
    -b ou=Users,"$LDAP_RDN" uidNumber |
  grep '^uidNumber' |
  sed 's/^uidNumber: //g' |
  uniq |
  sort -n |
  tail -n 1
}

local_uid_lookup() {
  getent passwd "$1" |
  head -n 1 |
  cut -d ':' -f 1
}

ldap_uid_lookup() {
  ldapsearch -LLL -x -ZZ \
    -b ou=Users,"$LDAP_RDN" \
    "(&(objectClass=posixAccount)(|(uid=$1)(uidNumber=$1)))" uid |
  grep "^uid: " |
  head -n 1 |
  sed "s/^uid: //g"
}

uid_to_username() {
  export USERNAME
  USERNAME=$(local_uid_lookup "$1")
  if [ -z "$USERNAME" ]; then
    USERNAME=$(ldap_uid_lookup "$1")
  fi
  echo "$USERNAME"
}

find_next_uid() {
  export NEXT_UID
  NEXT_UID=$(get_last_uid)
  if [ -z "$NEXT_UID" ] || [ "$NEXT_UID" -lt 10000 ]; then
    NEXT_UID=10000
  else
    NEXT_UID=$((NEXT_UID + 1))
  fi

  export USERNAME
  USERNAME=$(uid_to_username "$NEXT_UID")
  while [ -n "$USERNAME" ]; do
    NEXT_UID=$((NEXT_UID + 1))
    USERNAME=$(uid_to_username "$NEXT_UID")
  done

  echo "$NEXT_UID"
}

ldap_gid_lookup() {
  ldapsearch -LLL -x -ZZ \
    -b ou=Groups,"$LDAP_RDN" \
  "(&(objectClass=posixGroup)(|(cn=$1)(gidNumber=$1)))" gidNumber |
  grep "^gidNumber: " |
  head -n 1 |
  sed "s/^gidNumber: //g"
}

export _USERNAME=$1
export _GROUPNAME=$2
export _SURNAME=$3
export _GIVENNAME=$4
# export _EMAIL=$5
_USERPASSWD=$(./bin/generate_password.sh)
#shellcheck disable=SC2034
_PASSWD_HASH="$(slappasswd -s "$_USERPASSWD")"

export _UID
_UID=$(find_next_uid)
if [ -z "$_UID" ]; then
  echo "could not guess next free uid"
  exit 1
fi
export _GID
_GID=$(ldap_gid_lookup "$_GROUPNAME")
if [ -z "$_GID" ]; then
  echo "could not find gid for group $_GROUPNAME"
  exit 1
fi

envsubst \$LDAP_RDN\$_USERNAME\$_SURNAME\$_GIVENNAME\$_UID\$_GID\$_PASSWD_HASH \
  < conf/create_user.ldif |
  ldapadd -x -D "$LDAP_ADMIN_DN" -W

envsubst \$LDAP_RDN\$_USERNAME\$_GROUPNAME < conf/add_user_to_group.ldif |
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:///

echo -e "Username: $_USERNAME\nInitial Password: $_USERPASSWD"
