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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
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
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('glance::notify::rabbitmq::rabbit_port', 5672)

class tripleo::profile::base::glance::api (
  $bootstrap_node     = hiera('bootstrap_nodeid', undef),
  $glance_backend     = downcase(hiera('glance_backend', 'swift')),
  $glance_nfs_enabled = false,
  $step               = hiera('step'),
  $rabbit_hosts       = hiera('rabbitmq_node_names', undef),
  $rabbit_port        = hiera('glance::notify::rabbitmq::rabbit_port', 5672),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 1 and $glance_nfs_enabled {
    include ::tripleo::glance::nfs_mount
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    case $glance_backend {
        'swift': { $backend_store = 'glance.store.swift.Store' }
        'file': { $backend_store = 'glance.store.filesystem.Store' }
        'rbd': { $backend_store = 'glance.store.rbd.Store' }
        default: { fail('Unrecognized glance_backend parameter.') }
    }
    $http_store = ['glance.store.http.Store']
    $glance_store = concat($http_store, $backend_store)

    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    class { '::glance::api':
      stores  => $glance_store,
      sync_db => false,
    }
    # When https://review.openstack.org/#/c/408554 is merged,
    # Remove this block and set sync_db to $sync_db in glance::api.
    if $sync_db {
      class { '::glance::db::sync':
        extra_params => '',
      }
    }
    $rabbit_endpoints = suffix(any2array($rabbit_hosts), ":${rabbit_port}")
    class { '::glance::notify::rabbitmq' :
      rabbit_hosts => $rabbit_endpoints,
    }
    include join(['::glance::backend::', $glance_backend])
  }

}
