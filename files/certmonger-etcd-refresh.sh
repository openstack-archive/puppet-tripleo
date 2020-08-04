#!/bin/bash

container_cli=$(hiera -c /etc/puppet/hiera.yaml container_cli podman)

# cinder uses etcd, so its containers also need to be refreshed
container_names=$($container_cli ps --format="{{.Names}}" | grep -E 'cinder|etcd')

service_crt="$(hiera -c /etc/puppet/hiera.yaml tripleo::profile::base::etcd::certificate_specs.service_certificate)"
service_key="$(hiera -c /etc/puppet/hiera.yaml tripleo::profile::base::etcd::certificate_specs.service_key)"

kolla_dir="/var/lib/kolla/config_files/src-tls"

# For each container, check whether the cert and key files need to be updated.
# The check is necessary because the original THT design directly bind mounted
# the files to their final location, and did not copy them in via $kolla_dir.
# Regardless of whether the container is directly using the files, or a copy,
# there's no need to trigger a reload because the cert is not cached.

for container_name in ${container_names[*]}; do
    $container_cli exec -u root "$container_name" bash -c "
[[ -f ${kolla_dir}/${service_crt} ]] && cp ${kolla_dir}/${service_crt} $service_crt;
[[ -f ${kolla_dir}/${service_key} ]] && cp ${kolla_dir}/${service_key} $service_key;
true
"
done
