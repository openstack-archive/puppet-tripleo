#!/bin/bash

container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)
container_name=$($container_cli ps --format="{{.Names}}" | grep metrics_qdr)

service_certificate="$(hiera -c /etc/puppet/hiera.yaml tripleo::profile::base::memcached::certificate_specs.service_certificate)"
service_key="$(hiera -c /etc/puppet/hiera.yaml tripleo::profile::base::memcached::certificate_specs.service_key)"

# Copy the new cert and key from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_certificate" "$service_certificate"
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_key" "$service_key"

# Set appropriate permissions
$container_cli exec "$container_name" chown qdrouterd:qdrouterd "$service_certificate"
$container_cli exec "$container_name" chown qdrouterd:qdrouterd "$service_key"

# Send refresh_certs command to memcached
memcached_ip="$(hiera -c /etc/puppet/hiera.yaml memcached::listen.0 127.0.0.1)"
memcached_port="$(hiera -c /etc/puppet/hiera.yaml memcached::tcp_port 11211)"
echo refresh_certs | openssl s_client -connect $memcached_ip:$memcached_port
