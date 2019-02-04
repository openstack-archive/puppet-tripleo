#!/bin/bash


container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli docker)

container_name=$($container_cli ps --format="{{.Names}}" | grep neutron_dhcp)

# The certificate is also installed on the computes, but neutron_dhcp is only
# present on the controllers, so we exit if the container could not be found.
[[ -z $container_name ]] && exit 0

service_crt="$(hiera -c /etc/puppet/hiera.yaml neutron::agents::dhcp::ovsdb_agent_ssl_cert_file)"
service_key="$(hiera -c /etc/puppet/hiera.yaml neutron::agents::dhcp::ovsdb_agent_ssl_key_file)"

# Copy the new cert from the mount-point to the real path
$container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_crt" "$service_crt"

# Copy the new key from the mount-point to the real path
$container_cli exec -u root "$container_name" cp "/var/lib/kolla/config_files/src-tls$service_key" "$service_key"

# No need to trigger a reload for neutron dhcpd since the cert is not cached
