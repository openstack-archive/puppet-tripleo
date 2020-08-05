#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli docker)

container_name=$($container_cli ps --format="{{.Names}}" | grep -w -E 'rabbitmq(-bundle-.*-[0-9]+)?')

service_pem="$(hiera -c /etc/puppet/hiera.yaml tripleo::rabbitmq::service_certificate)"

# Copy the new cert from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_pem" "$service_pem"

# Set appropriate permissions
$container_cli exec "$container_name" chown rabbitmq:rabbitmq "$service_pem"

# Trigger a pem cache clear in RabbitMQ to read the new certificates
$container_cli exec $container_name rabbitmqctl eval "ssl:clear_pem_cache()."
