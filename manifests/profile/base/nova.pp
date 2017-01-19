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
# == Class: tripleo::profile::base::nova
#
# Nova base profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*libvirt_enabled*]
#   (Optional) Whether or not Libvirt is enabled.
#   Defaults to false
#
# [*manage_migration*]
#   (Optional) Whether or not manage Nova Live migration
#   Defaults to false
#
# [*messaging_driver*]
#   Driver for messaging service.
#   Defaults to hiera('messaging_service_name', 'rabbit')
#
# [*messaging_hosts*]
#   list of the messaging host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*messaging_password*]
#   Password for messaging nova queue
#   Defaults to hiera('nova::rabbit_password')
#
# [*messaging_port*]
#   IP port for messaging service
#   Defaults to hiera('nova::rabbit_port', 5672)
#
# [*messaging_username*]
#   Username for messaging nova queue
#   Defaults to hiera('nova::rabbit_userid', 'guest')
#
# [*messaging_use_ssl*]
#   Flag indicating ssl usage.
#   Defaults to hiera('nova::rabbit_use_ssl', '0')
#
# [*nova_compute_enabled*]
#   (Optional) Whether or not nova-compute is enabled.
#   Defaults to false
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::nova (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $libvirt_enabled      = false,
  $manage_migration     = false,
  $messaging_driver     = hiera('messaging_service_name', 'rabbit'),
  $messaging_hosts      = any2array(hiera('rabbitmq_node_names', undef)),
  $messaging_password   = hiera('nova::rabbit_password'),
  $messaging_port       = hiera('nova::rabbit_port', '5672'),
  $messaging_username   = hiera('nova::rabbit_userid', 'guest'),
  $messaging_use_ssl    = hiera('nova::rabbit_use_ssl', '0'),
  $nova_compute_enabled = false,
  $step                 = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if hiera('nova::use_ipv6', false) {
    $memcache_servers = suffix(hiera('memcached_node_ips_v6'), ':11211')
  } else {
    $memcache_servers = suffix(hiera('memcached_node_ips'), ':11211')
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $messaging_use_ssl_real = sprintf('%s', bool2num(str2bool($messaging_use_ssl)))
    # TODO(ccamacho): remove sprintf once we properly type the port, needs
    # to be a string for the os_transport_url function.
    class { '::nova' :
      default_transport_url => os_transport_url({
        'transport' => $messaging_driver,
        'hosts'     => $messaging_hosts,
        'port'      => sprintf('%s', $messaging_port),
        'username'  => $messaging_username,
        'password'  => $messaging_password,
        'ssl'       => $messaging_use_ssl_real,
      }),
    }
    include ::nova::config
    class { '::nova::cache':
      enabled          => true,
      backend          => 'oslo_cache.memcache_pool',
      memcache_servers => $memcache_servers,
    }
  }

  if $step >= 4 {
    include ::nova::placement
    if $manage_migration {
      class { '::nova::migration::libvirt':
        configure_libvirt => $libvirt_enabled,
        configure_nova    => $nova_compute_enabled,
      }
    }
  }

}
