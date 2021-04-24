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

haproxy_container_name=$($container_cli ps --format="{{.Names}}" | grep -w -E 'haproxy(-bundle-.*-[0-9]+)?')

if [ "$ACTION" == "reload" ]; then
    # Inject the new certificate into the running container
    if echo "$haproxy_container_name" | grep -q "^haproxy-bundle"; then
        # lp#1917868: Do not use podman cp with HA containers as they get
        # frozen temporarily and that can make pacemaker operation fail.
        tar -c "$service_pem" | $container_cli exec -i "$haproxy_container_name" tar -C / -xv
        # no need to update the mount point, because pacemaker
        # recreates the container when it's restarted
    else
        # Refresh the pem at the mount-point
        $container_cli cp $service_pem "$haproxy_container_name:/var/lib/kolla/config_files/src-tls${service_pem}"
        # Copy the new pem from the mount-point to the real path
        $container_cli exec "$haproxy_container_name" cp "/var/lib/kolla/config_files/src-tls${service_pem}" "$service_pem"
    fi

    # Set appropriate permissions
    $container_cli exec "$haproxy_container_name" chown haproxy:haproxy "$service_pem"

    # Trigger a reload for HAProxy to read the new certificates
    $container_cli kill --signal HUP "$haproxy_container_name"
elif [ "$ACTION" == "restart" ]; then
    # Copying the certificate and permissions will be handled by kolla's start
    # script.
    $container_cli restart "$haproxy_container_name"
fi
