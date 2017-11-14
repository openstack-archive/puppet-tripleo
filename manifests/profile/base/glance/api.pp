# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::glance::api
#
# Glance API profile for tripleo
#
# === Parameters
#
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*glance_nfs_enabled*]
#   (Optional) Whether to use NFS mount as 'file' backend storage location.
#   Defaults to false
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('glance::notify::rabbitmq::rabbit_port', 5672)
#
# [*glance_rbd_client_name*]
# Name used by the glance ceph key
# defaults to 'openstack'

class tripleo::profile::base::glance::api (
  $glance_backend = downcase(hiera('glance_backend', 'swift')),
  $glance_nfs_enabled = false,
  $step           = hiera('step'),
  $rabbit_hosts   = hiera('rabbitmq_node_ips', undef),
  $rabbit_port    = hiera('glance::notify::rabbitmq::rabbit_port', 5672),
  $glance_rbd_client_name = hiera('glance::backend::rbd::rbd_store_user','openstack'),
) {

  if $step >= 1 and $glance_nfs_enabled {
    include ::tripleo::glance::nfs_mount
  }

  if $step >= 4 {
    case $glance_backend {
        'swift': { $backend_store = 'glance.store.swift.Store' }
        'file': { $backend_store = 'glance.store.filesystem.Store' }
        'rbd': {
          $backend_store = 'glance.store.rbd.Store'
          exec{ "exec-setfacl-${glance_rbd_client_name}-glance":
            path    => ['/bin', '/usr/bin'],
            command => "setfacl -m u:glance:r-- /etc/ceph/ceph.client.${glance_rbd_client_name}.keyring",
            unless  => "getfacl /etc/ceph/ceph.client.${glance_rbd_client_name}.keyring | grep -q user:glance:r--",
          }
          Ceph::Key<| title == "client.${glance_rbd_client_name}" |> -> Exec["exec-setfacl-${glance_rbd_client_name}-glance"]
        }
        default: { fail('Unrecognized glance_backend parameter.') }
    }
    $http_store = ['glance.store.http.Store']
    $glance_store = concat($http_store, $backend_store)

    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    class { '::glance::api':
      stores => $glance_store,
    }
    $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    class { '::glance::notify::rabbitmq' :
      rabbit_hosts => $rabbit_endpoints,
    }
    include join(['::glance::backend::', $glance_backend])
  }

}
