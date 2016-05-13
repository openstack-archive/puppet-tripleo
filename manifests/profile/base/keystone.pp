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
# == Class: tripleo::profile::base::keystone
#
# Keystone profile for tripleo
#
# === Parameters
#
# [*sync_db*]
#   (Optional) Whether to run db sync
#   Defaults to true
#
# [*manage_service*]
#   (Optional) Whether to manage the keystone service
#   Defaults to undef
#
# [*enabled*]
#   (Optional) Whether to enable the keystone service
#   Defaults to undef
#
# [*bootstrap_master*]
#   (Optional) The hostname of the node responsible for bootstrapping
#   Defaults to hiera('bootstrap_nodeid')
#
# [*manage_roles*]
#   (Optional) whether to create keystone admin role
#   Defaults to true
#
# [*manage_endpoint*]
#   (Optional) Whether to create keystone endpoints
#   Defaults to true
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::keystone (
  $sync_db          = true,
  $manage_service   = undef,
  $enabled          = undef,
  $bootstrap_master = undef,
  $manage_roles     = true,
  $manage_endpoint  = true,
  $manage_db_purge  = hiera('keystone_enable_db_purge', true),
  $step             = hiera('step'),
) {

  if $step >= 3 and $sync_db {
    include ::keystone::db::mysql
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    class { '::keystone':
      sync_db          => $sync_db,
      manage_service   => $manage_service,
      enabled          => $enabled,
      enable_bootstrap => $bootstrap_master,
    }

    include ::keystone::config
    include ::keystone::wsgi::apache

    if $manage_roles {
      include ::keystone::roles::admin
    }

    if $manage_endpoint {
      include ::keystone::endpoint
    }

    #TODO: need a cleanup-keystone-tokens.sh solution here
    file { [ '/etc/keystone/ssl', '/etc/keystone/ssl/certs', '/etc/keystone/ssl/private' ]:
      ensure  => 'directory',
      owner   => 'keystone',
      group   => 'keystone',
      require => Package['keystone'],
    }
    file { '/etc/keystone/ssl/certs/signing_cert.pem':
      content => hiera('keystone_signing_certificate'),
      owner   => 'keystone',
      group   => 'keystone',
      notify  => Service[$::apache::params::service_name],
      require => File['/etc/keystone/ssl/certs'],
    }
    file { '/etc/keystone/ssl/private/signing_key.pem':
      content => hiera('keystone_signing_key'),
      owner   => 'keystone',
      group   => 'keystone',
      notify  => Service[$::apache::params::service_name],
      require => File['/etc/keystone/ssl/private'],
    }
    file { '/etc/keystone/ssl/certs/ca.pem':
      content => hiera('keystone_ca_certificate'),
      owner   => 'keystone',
      group   => 'keystone',
      notify  => Service[$::apache::params::service_name],
      require => File['/etc/keystone/ssl/certs'],
    }
  }

  if $step >= 5 and $manage_db_purge {
    include ::keystone::cron::token_flush
  }
}

