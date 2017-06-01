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
# [*nova_compute_enabled*]
#   (Optional) Whether or not nova-compute is enabled.
#   Defaults to false
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('nova::rabbit_port', 5672)
#
# [*migration_ssh_key*]
#   (Optional) SSH key pair for migration SSH tunnel.
#   Expects a hash with keys 'private_key' and 'public_key'.
#   Defaults to {}
#
# [*libvirt_tls*]
#   (Optional) Whether or not libvird TLS service is enabled.
#   Defaults to false

class tripleo::profile::base::nova (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $libvirt_enabled      = false,
  $manage_migration     = false,
  $nova_compute_enabled = false,
  $step                 = hiera('step'),
  $rabbit_hosts         = hiera('rabbitmq_node_ips', undef),
  $rabbit_port          = hiera('nova::rabbit_port', 5672),
  $migration_ssh_key    = {},
  $libvirt_tls          = false
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
    $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    include ::nova::config
    class { '::nova::cache':
      enabled          => true,
      backend          => 'oslo_cache.memcache_pool',
      memcache_servers => $memcache_servers,
    }

    if $step >= 4 and $manage_migration {

      # Libvirt setup (live-migration)
      if $libvirt_tls {
        class { '::nova::migration::libvirt':
          transport         => 'tls',
          configure_libvirt => $libvirt_enabled,
          configure_nova    => $nova_compute_enabled,
        }
      } else {
        # Reuse the cold-migration SSH tunnel when TLS is not enabled
        class { '::nova::migration::libvirt':
          transport          => 'ssh',
          configure_libvirt  => $libvirt_enabled,
          configure_nova     => $nova_compute_enabled,
          client_user        => 'nova',
          client_extraparams => {
            'keyfile' => '/var/lib/nova/.ssh/id_rsa'
          }
        }
      }

      if $migration_ssh_key != {} {
        # Nova SSH tunnel setup (cold-migration)

        #TODO: Remove me when https://review.rdoproject.org/r/#/c/4008 lands
        user { 'nova':
          ensure => present,
          shell  => '/bin/bash',
        }

        $private_key_parts = split($migration_ssh_key['public_key'], ' ')
        $nova_public_key = {
          'type' => $private_key_parts[0],
          key    => $private_key_parts[1]
        }
        $nova_private_key = {
          'type' => $private_key_parts[0],
          key    => $migration_ssh_key['private_key']
        }
      } else {
        $nova_public_key = undef
        $nova_private_key = undef
      }
    } else {
      $nova_public_key = undef
      $nova_private_key = undef
    }

    class { '::nova' :
      rabbit_hosts     => $rabbit_endpoints,
      nova_public_key  => $nova_public_key,
      nova_private_key => $nova_private_key,
    }
  }
}
