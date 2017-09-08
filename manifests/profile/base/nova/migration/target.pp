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
# == Class: tripleo::profile::base::nova::migration::target
#
# Nova migration target profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*ssh_authorized_keys*]
#   (Optional) List of SSH public keys authorized for migration.
#   If no keys are provided then migration over ssh will be disabled.
#   Defaults to []
#
# [*ssh_localaddrs*]
#   (Optional) Restrict ssh migration to clients connecting via this list of
#   IPs.
#   Defaults to [] (no restriction)
#
# [*services_enabled*]
#   (Optional) List of services enabled on the current role.
#   If the nova_migration_target service is not enabled then migration over
#   ssh will be disabled.
#   Defaults to hiera('service_names', [])
#
# [*wrapper_command*]
#   (Internal) Used to override the wrapper command when proxying
#   Defaults to /bin/nova-migration-wrapper

class tripleo::profile::base::nova::migration::target (
  $step                = Integer(hiera('step')),
  $ssh_authorized_keys = [],
  $ssh_localaddrs      = [],
  $services_enabled    = hiera('service_names', []),
  $wrapper_command     = '/bin/nova-migration-wrapper',
) {

  include ::tripleo::profile::base::nova::migration

  validate_array($ssh_localaddrs)
  $ssh_localaddrs.each |$x| { validate_ip_address($x) }
  $ssh_localaddrs_real = unique($ssh_localaddrs)
  validate_array($ssh_authorized_keys)
  $ssh_authorized_keys_real = join($ssh_authorized_keys, '\n')

  if $step >= 4 {
    if !empty($ssh_authorized_keys_real) {
      if ('nova_migration_target' in $services_enabled) {
        if !empty($ssh_localaddrs_real) {
          $allow_type = sprintf('LocalAddress %s User', join($ssh_localaddrs_real,','))
          $deny_type = 'LocalAddress'
          $deny_name = sprintf('!%s', join($ssh_localaddrs_real,',!'))

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
            'ForceCommand'           => $wrapper_command,
            'PasswordAuthentication' => 'no',
            'AllowTcpForwarding'     => 'no',
            'X11Forwarding'          => 'no',
            'AuthorizedKeysFile'     => '/etc/nova/migration/authorized_keys'
          },
          notify  => Service['sshd']
        }
        $migration_authorized_keys = $ssh_authorized_keys_real
        $migration_user_shell = '/bin/bash'
      }
      else {
        # Remove the keys and prevent login when migration over SSH is not enabled
        $migration_authorized_keys = '# Migration over SSH disabled by TripleO'
        $migration_user_shell = '/sbin/nologin'
      }
    }
    else {
      # Remove the keys and prevent login when migration over SSH is not enabled
      $migration_authorized_keys = '# Migration over SSH disabled by TripleO'
      $migration_user_shell = '/sbin/nologin'
    }

    file { '/etc/nova/migration/authorized_keys':
      content => $migration_authorized_keys,
      mode    => '0640',
      owner   => 'root',
      group   => 'nova_migration',
      require => Package['openstack-nova-migration']
    }

    user {'nova_migration':
      shell   => $migration_user_shell,
      require => Package['openstack-nova-migration']
    }
  }
}
