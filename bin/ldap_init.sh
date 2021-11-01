#!/usr/bin/env bash

set -euxo pipefail


source "env/ldap_env.sh"

setup_cert() {
  sudo openssl req -nodes -newkey rsa:2048 \
    -keyout /etc/ssl/private/server.key \
    -out /tmp/server.csr \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$LDAP_SERVER_FQDN"
  sudo openssl x509 \
    -in /tmp/server.csr \
    -out /etc/ssl/certs/server.crt -req \
    -signkey /etc/ssl/private/server.key \
    -days 3650

}

server() {
  sudo apt update

  sudo apt install --yes debconf-utils

  # automatically set values for slapd
  envsubst \$LDAP_DOMAIN\$ORG_SHORT < conf/slapd-debconf.preseed |
    sudo debconf-set-selections

  # setup_cert

  sudo apt install --yes slapd ldap-utils

  envsubst \$LDAP_SERVER_FQDN\$LDAP_RDN < conf/ldap.conf |
    sudo dd of=/etc/ldap/ldap.conf

  # add Users and Groups
  envsubst \$LDAP_RDN < "conf/init.ldif" |
    ldapadd -x -D "$LDAP_ADMIN_DN" -W

  # set log level to 'stats'. see  olcLogLevel in `man slapd-config`
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f conf/enable_logging.ldif

  # TODO: is there a need to set ACL on the priv key?
  sudo setfacl -R -m u:openldap:rx /etc/ssl/private
  sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f conf/enable_tls.ldif

  sudo systemctl restart slapd

}

client() {
  sudo apt update

  sudo apt install --yes debconf-utils ldap-utils

  # automatically set values for libnss-ldap
  envsubst \$LDAP_RDN\$LDAP_SERVER_FQDN\$LDAP_AUTH_DN < conf/ldap-auth-config-debconf.preseed |
    sudo debconf-set-selections

  sudo apt install --yes libnss-ldap

  sudo auth-client-config -t nss -p lac_ldap
  sudo pam-auth-update --enable mkhomedir

  # https://superuser.com/a/1163328
  sudo sed --in-place --expression="s/###DEBCONF###//" /etc/ldap.conf
  sudo sed --in-place --expression="s/#ssl start_tls/ssl start_tls/" /etc/ldap.conf
  sudo sed --in-place --expression="s/^rootbinddn/#rootbinddn/" /etc/ldap.conf

  # https://ubuntuforums.org/showthread.php?t=1640070
  sudo sed --in-place --expression="s/use_authtok //" /etc/pam.d/common-password

  envsubst \$LDAP_SERVER_FQDN < conf/ldap.conf |
    sudo dd of=/etc/ldap/ldap.conf

}

eval "$1"
