#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)

container_name=$($container_cli ps --format="{{.Names}}" | grep nova_vnc_proxy)

service_crt="$(hiera -c /etc/puppet/hiera.yaml nova::cert)"
service_key="$(hiera -c /etc/puppet/hiera.yaml nova::key)"

# Copy the new cert from the mount-point to the real path
$container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_crt" "$service_crt"

# Copy the new key from the mount-point to the real path
$container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_key" "$service_key"

# No need to trigger a reload for novnc proxy since the cert is not cached
