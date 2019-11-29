#!/bin/bash

# This script is meant to reload HAProxy when certmonger triggers a certificate
# renewal. It'll concatenate the needed certificates for the PEM file that
# HAProxy reads.

die() { echo "$*" 1>&2 ; exit 1; }

[[ $# -eq 2 ]] || die "Invalid number of arguments"
[[ $1 == @(reload|restart) ]] || die "First argument must be one of 'reload' or 'restart'."


ACTION=$1
NETWORK=$2

certmonger_ca=$(hiera -c /etc/puppet/hiera.yaml certmonger_ca)
container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)
service_certificate="$(hiera -c /etc/puppet/hiera.yaml tripleo::certmonger::haproxy_dirs::certificate_dir)/overcloud-haproxy-$NETWORK.crt"
service_key="$(hiera -c /etc/puppet/hiera.yaml tripleo::certmonger::haproxy_dirs::key_dir)/overcloud-haproxy-$NETWORK.key"
ca_path=""

if [ "$certmonger_ca" == "local" ]; then
    ca_path="/etc/pki/ca-trust/source/anchors/cm-local-ca.pem"
elif [ "$certmonger_ca" == "IPA" ]; then
    ca_path="/etc/ipa/ca.crt"
fi

if [ "$NETWORK" != "external" ]; then
    service_pem="$(hiera -c /etc/puppet/hiera.yaml tripleo::certmonger::haproxy_dirs::certificate_dir)/overcloud-haproxy-$NETWORK.pem"
else
    service_pem="$(hiera -c /etc/puppet/hiera.yaml tripleo::haproxy::service_certificate)"
fi

cat "$service_certificate" "$ca_path" "$service_key" > "$service_pem"

haproxy_container_name=$($container_cli ps --format="{{.Names}}" | grep haproxy)

if [ "$ACTION" == "reload" ]; then
    # Copy the new cert from the mount-point to the real path
    $container_cli exec "$haproxy_container_name" cp "/var/lib/kolla/config_files/src-tls$service_pem" "$service_pem"

    # Set appropriate permissions
    $container_cli exec "$haproxy_container_name" chown haproxy:haproxy "$service_pem"

    # Trigger a reload for HAProxy to read the new certificates
    $container_cli kill --signal HUP "$haproxy_container_name"
elif [ "$ACTION" == "restart" ]; then
    # Copying the certificate and permissions will be handled by kolla's start
    # script.
    $container_cli restart "$haproxy_container_name"
fi
