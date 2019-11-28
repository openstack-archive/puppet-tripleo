#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)

container_name=$($container_cli ps --format="{{.Names}}" | grep redis_tls_proxy)

service_pem="$(hiera -c /etc/puppet/hiera.yaml tripleo::redis::service_certificate)"

# Copy the new cert from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_pem" "$service_pem"

# Trigger a reload for stunnel to read the new certificates
pkill -o -HUP stunnel
