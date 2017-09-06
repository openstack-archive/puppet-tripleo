# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::nova::migration::proxy
#
# Nova migration proxy profile for tripleo.
# Used to proxy connections from baremetal sshd to dockerized sshd on a
# different port during rolling upgrades.
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*ssh_private_key*]
#   (Optional) SSH private_key for migration SSH tunnel.
#   Defaults to ''
#
# [*target_host*]
#   (Optional) SSH hostname to proxy.
#   Defaults to hiera('fqdn_internal_api', '127.0.0.1')
#
# [*target_port*]
#   (Optional) SSH port to proxy.
#   Defaults to 22

class tripleo::profile::base::nova::migration::proxy (
  $step            = Integer(hiera('step')),
  $ssh_private_key = '',
  $target_host  = hiera('fqdn_internal_api', '127.0.0.1'),
  $target_port  = 22
) {

  include ::tripleo::profile::base::nova::migration

  if $step >= 4 {
    if !empty($ssh_private_key) {
      class { '::tripleo::profile::base::nova::migration::target':
        step            => $step,
        wrapper_command => "/bin/ssh \
-p ${target_port} \
-i /etc/nova/migration/proxy_identity \
-o BatchMode=yes \
-o UserKnownHostsFile=/dev/null \
nova_migration@${target_host} \
\$SSH_ORIGINAL_COMMAND"
      }

      $migration_identity = $ssh_private_key
      $migration_identity_ensure = 'present'
    }
    else {
      $migration_identity = ''
      $migration_identity_ensure = 'absent'
    }

    file { '/etc/nova/migration/proxy_identity':
      ensure  => $migration_identity_ensure,
      content => $migration_identity,
      mode    => '0600',
      owner   => 'nova_migration',
      group   => 'nova_migration',
      require => Package['openstack-nova-migration']
    }
  }
}
