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
# == Class: tripleo::profile::base::database::mysql
#
# MySQL profile for tripleo
#
# === Parameters
#
# [*bind_address*]
#   (Optional) The address that the local mysql instance should bind to.
#   Defaults to $::hostname
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*generate_dropin_file_limit*]
#   (Optional) Generate a systemd drop-in file to raise the file descriptor
#   limit for the mysql service.
#   Defaults to false
#
# [*manage_resources*]
#   (Optional) Whether or not manage root user, root my.cnf, and service.
#   Defaults to true
#
# [*mysql_server_options*]
#   (Optional) Extras options to deploy MySQL. Useful when deploying Galera cluster.
#   Should be an hash.
#   Defaults to {}
#
# [*mysql_max_connections*]
#   (Optional) Maximum number of connections to MySQL.
#   Defaults to hiera('mysql_max_connections', undef)
#
# [*remove_default_accounts*]
#   (Optional) Whether or not remove default MySQL accounts.
#   Defaults to true
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::database::mysql (
  $bind_address               = $::hostname,
  $bootstrap_node             = hiera('bootstrap_nodeid', undef),
  $generate_dropin_file_limit = false,
  $manage_resources           = true,
  $mysql_server_options       = {},
  $mysql_max_connections      = hiera('mysql_max_connections', undef),
  $remove_default_accounts    = true,
  $step                       = hiera('step'),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  validate_hash($mysql_server_options)

  # non-ha scenario
  if $manage_resources {
    $mysql_step = 2
  } else {
  # ha scenario
    $mysql_step = 1
  }
  if $step >= $mysql_step {
    if str2bool(hiera('enable_galera', true)) {
      $mysql_config_file = '/etc/my.cnf.d/galera.cnf'
    } else {
      $mysql_config_file = '/etc/my.cnf.d/server.cnf'
    }
    # TODO Galera
    # FIXME: due to https://bugzilla.redhat.com/show_bug.cgi?id=1298671 we
    # set bind-address to a hostname instead of an ip address; to move Mysql
    # from internal_api on another network we'll have to customize both
    # MysqlNetwork and ControllerHostnameResolveNetwork in ServiceNetMap
    $mysql_server_default = {
      'mysqld' => {
        'bind-address'     => $bind_address,
        'max_connections'  => $mysql_max_connections,
        'open_files_limit' => '-1',
      }
    }
    $mysql_server_options_real = deep_merge($mysql_server_default, $mysql_server_options)
    class { '::mysql::server':
      config_file             => $mysql_config_file,
      override_options        => $mysql_server_options_real,
      create_root_user        => $manage_resources,
      create_root_my_cnf      => $manage_resources,
      service_manage          => $manage_resources,
      service_enabled         => $manage_resources,
      remove_default_accounts => $remove_default_accounts,
    }

    if $generate_dropin_file_limit and $manage_resources {
      # Raise the mysql file limit
      ::systemd::service_limits { 'mariadb.service':
        limits => {
          'LimitNOFILE' => 16384
        }
      }
    }
  }

  if $step >= 2 and $sync_db {
    Class['::mysql::server'] -> Mysql_database<||>
    if hiera('aodh_api_enabled', false) {
      include ::aodh::db::mysql
    }
    if hiera('ceilometer_collector_enabled', false) {
      include ::ceilometer::db::mysql
    }
    if hiera('cinder_api_enabled', false) {
      include ::cinder::db::mysql
    }
    if hiera('glance_registry_enabled', false) {
      include ::glance::db::mysql
    }
    if hiera('gnocchi_api_enabled', false) {
      include ::gnocchi::db::mysql
    }
    if hiera('heat_engine_enabled', false) {
      include ::heat::db::mysql
    }
    if hiera('ironic_api_enabled', false) {
      include ::ironic::db::mysql
    }
    if hiera('keystone_enabled', false) {
      include ::keystone::db::mysql
    }
    if hiera('manila_api_enabled', false) {
      include ::manila::db::mysql
    }
    if hiera('mistral_api_enabled', false) {
      include ::mistral::db::mysql
    }
    if hiera('neutron_api_enabled', false) {
      include ::neutron::db::mysql
    }
    if hiera('nova_api_enabled', false) {
      include ::nova::db::mysql
      include ::nova::db::mysql_api
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::db::mysql
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::db::mysql
    }
  }

}
