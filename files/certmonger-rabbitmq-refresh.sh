#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli docker)

container_name=$($container_cli ps --format="{{.Names}}" | grep -w -E 'rabbitmq(-bundle-.*-[0-9]+)?')

service_crt="$(hiera -c /etc/puppet/hiera.yaml tripleo::rabbitmq::service_certificate.service_certificate)"
service_key="$(hiera -c /etc/puppet/hiera.yaml tripleo::rabbitmq::service_certificate.service_key)"

if echo "$container_name" | grep -q "^rabbitmq-bundle"; then
  # lp#1917868: Do not use podman cp with HA containers as they get
  # frozen temporarily and that can make pacemaker operation fail.
  tar -c "$service_crt" "$service_key" | $container_cli exec -i "$container_name" tar -C / -xv
  # no need to update the mount point, because pacemaker
  # recreates the container when it's restarted
else
  # Refresh the cert at the mount-point
  $container_cli cp $service_crt "$container_name:/var/lib/kolla/config_files/src-tls/$service_crt"
  # Refresh the key at the mount-point
  $container_cli cp $service_key "$container_name:/var/lib/kolla/config_files/src-tls/$service_key"
  # Copy the new cert from the mount-point to the real path
  $container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_crt" "$service_crt"
  # Copy the new key from the mount-point to the real path
  $container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_key" "$service_key"
fi

# Copy the new cert from the mount-point to the real path
$container_cli exec "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_pem" "$service_pem"

# Set appropriate permissions
$container_cli exec -u root "$container_name" chown rabbitmq:rabbitmq "$service_crt"
$container_cli exec -u root "$container_name" chown rabbitmq:rabbitmq "$service_key"

# Trigger a pem cache clear in RabbitMQ to read the new certificates
$container_cli exec $container_name rabbitmqctl eval "ssl:clear_pem_cache()."
