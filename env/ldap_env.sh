#!/usr/bin/env bash

export COUNTRY=JP
export STATE=Tokyo
export LOCATION=Tokyo
export ORGANIZATION='Example Inc.'
export ORGANIZATION_UNIT='Example Department'

export LDAP_SERVER_FQDN="server-1.example.com"
export LDAP_DOMAIN="example.com"
export LDAP_RDN="dc=example,dc=com"
export LDAP_ADMIN_DN="cn=admin,$LDAP_RDN"
export LDAP_AUTH_DN="cn=auth,$LDAP_RDN"
