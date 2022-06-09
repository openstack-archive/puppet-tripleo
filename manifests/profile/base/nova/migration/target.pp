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
#   Defaults to Integer(lookup('step'))
#
# [*ssh_authorized_keys*]
#   (Optional) List of SSH public keys authorized for migration.
#   If no keys are provided then migration over ssh will be disabled.
#   Defaults to []
#
# [*wrapper_command*]
#   (Internal) Used to override the wrapper command when proxying
#   Defaults to /bin/nova-migration-wrapper
#
class tripleo::profile::base::nova::migration::target (
  $step                = Integer(lookup('step')),
  $ssh_authorized_keys = [],
  $wrapper_command     = '/bin/nova-migration-wrapper',
) {

  include tripleo::profile::base::nova::migration

  validate_legacy(Array, 'validate_array', $ssh_authorized_keys)
  $ssh_authorized_keys_real = join($ssh_authorized_keys, '\n')

  if $step >= 4 {
    if !empty($ssh_authorized_keys_real) {
      $allow_type = 'User'
      $allow_name = 'nova_migration'

      ssh::server::match_block { 'nova_migration allow':
        name    => $allow_name,
        type    => $allow_type,
        order   => 1,
        options => {
          'AllowUsers'             => $allow_name,
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

    file_line { 'nova_migration_logindefs':
      ensure => present,
      path   => '/etc/login.defs',
      line   => 'UMASK           022',
      match  => '^UMASK',
    }
  }
}
