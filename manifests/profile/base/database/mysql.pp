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
#   Defaults to hiera('mysql_short_bootstrap_node_name')
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'mysql' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::database::mysql::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "mysql/<overcloud controller fqdn>"
#   Defaults to {}.
#
# [*cipher_list*]
#   (Optional) When enable_internal_tls is true, defines the list of allowed
#   ciphers for the mysql server.
#   Defaults to '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1'
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*generate_dropin_file_limit*]
#   (Optional) Generate a systemd drop-in file to raise the file descriptor
#   limit for the mysql service.
#   Defaults to false
#
# [*innodb_buffer_pool_size*]
#   (Optional) Configure the size of the MySQL buffer pool.
#   Defaults to hiera('innodb_buffer_pool_size', undef)
#
# [*innodb_log_file_size*]
#   (Optional) Configure the size in bytes of each log file in a log group.
#   Defaults to undef.
#
# [*innodb_flush_method*]
#   (Optional) Defines the method used to flush data to InnoDB data files and log files.
#   Defaults to undef.
#
# [*innodb_lock_wait_timeout*]
#   (Option) Time in seconds that an InnoDB transaction waits for an InnoDB row lock (not table lock).
#   When this occurs, the statement (not transaction) is rolled back.
#   Defaults to undef.
#
# [*table_open_cache*]
#   (Optional) Configure the number of open tables for all threads.
#   Increasing this value increases the number of file descriptors that mysqld requires.
#   Defaults to undef.
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
# [*mysql_auth_ed25519*]
#   (Optional) Use MariaDB's ed25519 authentication plugin to authenticate
#   a user when connecting to the server
#   Defaults to hiera('mysql_auth_ed25519', false)
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
#
class tripleo::profile::base::database::mysql (
  $bind_address                  = $::hostname,
  $bootstrap_node                = hiera('mysql_short_bootstrap_node_name', undef),
  $certificate_specs             = {},
  $cipher_list                   = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1',
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_dropin_file_limit    = false,
  $innodb_buffer_pool_size       = hiera('innodb_buffer_pool_size', undef),
  $innodb_log_file_size          = undef,
  $innodb_lock_wait_timeout      = hiera('innodb_lock_wait_timeout', undef),
  $table_open_cache              = undef,
  $innodb_flush_method           = undef,
  $manage_resources              = true,
  $mysql_server_options          = {},
  $mysql_max_connections         = hiera('mysql_max_connections', undef),
  $mysql_auth_ed25519            = hiera('mysql_auth_ed25519', false),
  $remove_default_accounts       = true,
  $step                          = Integer(hiera('step')),
) {

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  validate_legacy(Hash, 'validate_hash', $mysql_server_options)
  validate_legacy(Hash, 'validate_hash', $certificate_specs)

  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
    $tls_cipher_list = $cipher_list

    # Force users/grants created to use TLS connections
    Openstacklib::Db::Mysql <||> { tls_options => ['SSL'] }
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $tls_cipher_list = undef
  }

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
        'bind-address'            => $bind_address,
        'max_connections'         => $mysql_max_connections,
        'open_files_limit'        => '65536',
        'innodb_buffer_pool_size' => $innodb_buffer_pool_size,
        'innodb_file_per_table'   => 'ON',
        'innodb_log_file_size'    => $innodb_log_file_size,
        'innodb_lock_wait_timeout'    => $innodb_lock_wait_timeout,
        'table_open_cache'        => $table_open_cache,
        'innodb_flush_method'     => $innodb_flush_method,
        'query_cache_size'        => '0',
        'query_cache_type'        => '0',
        'ssl'                     => $enable_internal_tls,
        'ssl-key'                 => $tls_keyfile,
        'ssl-cert'                => $tls_certfile,
        'ssl-cipher'              => $tls_cipher_list,
        'ssl-ca'                  => undef,
        'plugin_load_add'         => 'auth_ed25519',
      }
    }
    $mysql_server_options_real = deep_merge($mysql_server_default, $mysql_server_options)
    class { 'mysql::server':
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

  $service_names = hiera('enabled_services', undef)

  if $service_names {
    tripleo::profile::base::database::mysql::users { $service_names: }
  }

  if $step >= 2 and $sync_db {
    Class['::mysql::server'] -> Mysql_database<||>
    if ($manage_resources) {
      # the mysql module handles password for user 'root@localhost', but it
      # doesn't modify 'root@%'. So make sure this user password is managed
      # as well by creating a resource appropriately.
      mysql_user { 'root@%':
        ensure        => present,
        password_hash => mysql_password(hiera('mysql::server::root_password')),
      }
    }
    if ($mysql_auth_ed25519) {
      ['root@localhost', 'root@%'].each |$user| {
        Mysql_user<| title == $user |> {
          plugin        => 'ed25519',
          password_hash => mysql_ed25519_password(hiera('mysql::server::root_password'))
        }
      }
    }
    # Note: use 'include_and_check_auth' below rather than 'include'
    # to support ed25519 authentication
    if hiera('aodh_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'aodh::db::mysql':}
    }
    if hiera('ceilometer_collector_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'ceilometer::db::mysql':}
    }
    if hiera('cinder_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'cinder::db::mysql':}
    }
    if hiera('barbican_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'barbican::db::mysql':}
    }
    if hiera('designate_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'designate::db::mysql':}
    }
    if hiera('glance_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'glance::db::mysql':}
    }
    if hiera('gnocchi_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'gnocchi::db::mysql':}
    }
    if hiera('heat_engine_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'heat::db::mysql':}
    }
    if hiera('ironic_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'ironic::db::mysql':}
    }
    if hiera('ironic_inspector_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'ironic::inspector::db::mysql':}
    }
    if hiera('keystone_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'keystone::db::mysql':}
    }
    if hiera('manila_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'manila::db::mysql':}
    }
    if hiera('mistral_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'mistral::db::mysql':}
    }
    if hiera('neutron_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'neutron::db::mysql':}
    }
    if hiera('nova_conductor_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'nova::db::mysql':}
    }
    if hiera('nova_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'nova::db::mysql_api':}
    }
    if hiera('placement_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'placement::db::mysql':}
    }
    if hiera('octavia_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'octavia::db::mysql':}
    }
    if hiera('sahara_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'sahara::db::mysql':}
    }
    if hiera('ec2_api_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'ec2api::db::mysql':}
    }
    if hiera('zaqar_api_enabled', false) and hiera('zaqar::db::mysql::user', '') == 'zaqar' {
      # NOTE: by default zaqar uses sqlalchemy
      tripleo::profile::base::database::mysql::include_and_check_auth{'zaqar::db::mysql':}
    }
    if hiera('veritas_hyperscale_controller_enabled', false) {
      tripleo::profile::base::database::mysql::include_and_check_auth{'veritas_hyperscale::db::mysql':}
    }
  }

}
