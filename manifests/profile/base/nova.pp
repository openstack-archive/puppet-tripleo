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
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('messaging_rpc_service_name', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('nova::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('nova::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('nova::rabbit_password')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('messaging_notify_service_name', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('nova::rabbit_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('nova::rabbit_userid', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('nova::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
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
# [*migration_ssh_key*]
#   (Optional) SSH key pair for migration SSH tunnel.
#   Expects a hash with keys 'private_key' and 'public_key'.
#   Defaults to {}
#
# [*migration_ssh_localaddrs*]
#   (Optional) Restrict ssh migration to clients connecting via this list of
#   IPs.
#   Defaults to [] (no restriction)
#
# [*libvirt_tls*]
#   (Optional) Whether or not libvird TLS service is enabled.
#   Defaults to false

class tripleo::profile::base::nova (
  $bootstrap_node           = hiera('bootstrap_nodeid', undef),
  $libvirt_enabled          = false,
  $manage_migration         = false,
  $oslomsg_rpc_proto        = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts        = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_rpc_password     = hiera('nova::rabbit_password'),
  $oslomsg_rpc_port         = hiera('nova::rabbit_port', '5672'),
  $oslomsg_rpc_username     = hiera('nova::rabbit_userid', 'guest'),
  $oslomsg_notify_proto     = hiera('messaging_notify_service_name', 'rabbit'),
  $oslomsg_notify_hosts     = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_notify_password  = hiera('nova::rabbit_password'),
  $oslomsg_notify_port      = hiera('nova::rabbit_port', '5672'),
  $oslomsg_notify_username  = hiera('nova::rabbit_userid', 'guest'),
  $oslomsg_use_ssl          = hiera('nova::rabbit_use_ssl', '0'),
  $nova_compute_enabled     = false,
  $step                     = hiera('step'),
  $migration_ssh_key        = {},
  $migration_ssh_localaddrs = [],
  $libvirt_tls              = false
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
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    include ::nova::config
    class { '::nova::cache':
      enabled          => true,
      backend          => 'oslo_cache.memcache_pool',
      memcache_servers => $memcache_servers,
    }
    class { '::nova':
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
    }
    include ::nova::placement
  }

  if $step >= 4 {
    if $manage_migration {
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
          client_user        => 'nova_migration',
          client_extraparams => {'keyfile' => '/etc/nova/migration/identity'}
        }
      }

      $services_enabled = hiera('service_names', [])
      if !empty($migration_ssh_key) and 'sshd' in $services_enabled {
        # Nova SSH tunnel setup (cold-migration)

        # Server side
        if !empty($migration_ssh_localaddrs) {
          $allow_type = sprintf('LocalAddress %s User', join($migration_ssh_localaddrs,','))
          $deny_type = 'LocalAddress'
          $deny_name = sprintf('!%s', join($migration_ssh_localaddrs,',!'))

          ssh::server::match_block { 'nova_migration deny':
            name    => $deny_name,
            type    => $deny_type,
            order   => 2,
            options => {
              'DenyUsers' => 'nova_migration'
            },
            notify  => Service['sshd']
          }
        }
        else {
          $allow_type = 'User'
        }
        $allow_name = 'nova_migration'

        ssh::server::match_block { 'nova_migration allow':
          name    => $allow_name,
          type    => $allow_type,
          order   => 1,
          options => {
            'ForceCommand'           => '/bin/nova-migration-wrapper',
            'PasswordAuthentication' => 'no',
            'AllowTcpForwarding'     => 'no',
            'X11Forwarding'          => 'no',
            'AuthorizedKeysFile'     => '/etc/nova/migration/authorized_keys'
          },
          notify  => Service['sshd']
        }

        file { '/etc/nova/migration/authorized_keys':
          content => $migration_ssh_key['public_key'],
          mode    => '0640',
          owner   => 'root',
          group   => 'nova_migration',
          require => Package['openstack-nova-migration'],
        }

        # Client side
        file { '/etc/nova/migration/identity':
          content => $migration_ssh_key['private_key'],
          mode    => '0600',
          owner   => 'nova',
          group   => 'nova',
          require => Package['openstack-nova-migration'],
        }
        $migration_pkg_ensure = installed
      } else {
        $migration_pkg_ensure = absent
      }
    } else {
      $migration_pkg_ensure = absent
    }
    package {'openstack-nova-migration':
      ensure => $migration_pkg_ensure
    }
  }
}
