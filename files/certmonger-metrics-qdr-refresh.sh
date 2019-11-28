#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)

container_name=$($container_cli ps --format="{{.Names}}" | grep metrics_qdr)

service_certificate="$(hiera -c /etc/puppet/hiera.yaml tripleo::metrics::qdr::service_certificate)"

service_key="$(hiera -c /etc/puppet/hiera.yaml tripleo::metrics::qdr::service_key)"

# Copy the new cert from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_certificate" "$service_certificate"

# Copy the new key from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_key" "$service_key"

# Set appropriate permissions
$container_cli exec "$container_name" chown qdrouterd:qdrouterd "$service_certificate"

$container_cli exec "$container_name" chown qdrouterd:qdrouterd "$service_key"

# Trigger a container restart to read the new certificates
$container_cli restart $container_name
