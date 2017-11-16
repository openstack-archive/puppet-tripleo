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
# == Class: tripleo::profile::base::nova::migration
#
# Nova migration client profile for tripleo
#
# === Parameters
#
# [*libvirt_enabled*]
#   (Optional) Whether or not Libvirt is enabled.
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
# [*ssh_private_key*]
#   (Optional) SSH private_key for migration SSH tunnel.
#   Defaults to ''
#
# [*ssh_port*]
#   (Optional) Port that SSH target services is listening on.
#   Defaults to 22
#
# [*libvirt_tls*]
#   (Optional) Whether or not libvird TLS service is enabled.
#   Defaults to false

class tripleo::profile::base::nova::migration::client (
  $libvirt_enabled          = false,
  $nova_compute_enabled     = false,
  $step                     = Integer(hiera('step')),
  $ssh_private_key          = '',
  $ssh_port                 = 22,
  $libvirt_tls              = false,
) {

  include ::tripleo::profile::base::nova::migration

  if $step >= 4 {

    # Libvirt setup (live-migration)
    if $libvirt_tls {
      class { '::nova::migration::libvirt':
        transport         => 'tls',
        configure_libvirt => $libvirt_enabled,
        configure_nova    => $nova_compute_enabled,
        auth              => 'sasl'
      }
    } else {
      # Reuse the cold-migration SSH tunnel when TLS is not enabled
      class { '::nova::migration::libvirt':
        transport          => 'ssh',
        configure_libvirt  => $libvirt_enabled,
        configure_nova     => $nova_compute_enabled,
        client_user        => 'nova_migration',
        client_extraparams => {'keyfile' => '/etc/nova/migration/identity'},
        client_port        => $ssh_port
      }
    }

    if !empty($ssh_private_key) {
      # Nova SSH tunnel setup (cold-migration)
      $migration_identity = $ssh_private_key
    }
    else {
      $migration_identity = '# Migration over SSH disabled by TripleO'
    }

    file { '/etc/nova/migration/identity':
      content => $migration_identity,
      mode    => '0600',
      owner   => 'nova',
      group   => 'nova',
      require => Package['openstack-nova-migration']
    }

    file_line { 'nova_ssh_port':
      ensure => present,
      path   => '/var/lib/nova/.ssh/config',
      after  => '^Host \*$',
      line   => "    Port ${ssh_port}",
    }
  }
}
