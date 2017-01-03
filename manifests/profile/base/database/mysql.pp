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
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*generate_service_certificates*]
#   (Optional) Whether or not certmonger will generate certificates for
#   MySQL. This could be as many as specified by the $certificates_specs
#   variable.
#   Defaults to hiera('generate_service_certificate', false).
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
# [*remove_default_accounts*]
#   (Optional) Whether or not remove default MySQL accounts.
#   Defaults to true
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*nova_messaging_driver*]
#   Driver for messaging service. Will fallback to looking up in hiera
#   using hiera('messaging_service_name', 'rabbit') if the parameter is not
#   specified.
#   Defaults to undef.
#
# [*nova_messaging_hosts*]
#   list of the messaging host fqdns. Will fallback to looking up in hiera
#   using hiera('rabbitmq_node_names') if the parameter is not specified.
#   Defaults to undef.
#
# [*nova_messaging_port*]
#   IP port for messaging service. Will fallback to looking up in hiera using
#   hiera('nova::rabbit_port', 5672) if the parameter is not specified.
#   Defaults to undef.
#
# [*nova_messaging_username*]
#   Username for messaging nova queue. Will fallback to looking up in hiera
#   using hiera('nova::rabbit_userid', 'guest') if the parameter is not
#   specified.
#   Defaults to undef.
#
# [*nova_messaging_password*]
#   Password for messaging nova queue. Will fallback to looking up in hiera
#   using hiera('nova::rabbit_password') if the parameter is not specified.
#   Defaults to undef.
#
# [*nova_messaging_use_ssl*]
#   Flag indicating ssl usage. Will fallback to looking up in hiera using
#   hiera('nova::rabbit_use_ssl', '0') if the parameter is not specified.
#   Defaults to undef.
#
class tripleo::profile::base::database::mysql (
  $bind_address                  = $::hostname,
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificate_specs             = {},
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_service_certificates = hiera('generate_service_certificates', false),
  $manage_resources              = true,
  $mysql_server_options          = {},
  $remove_default_accounts       = true,
  $step                          = hiera('step'),
  $nova_messaging_driver         = undef,
  $nova_messaging_hosts          = undef,
  $nova_messaging_password       = undef,
  $nova_messaging_port           = undef,
  $nova_messaging_username       = undef,
  $nova_messaging_use_ssl        = undef,
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  validate_hash($mysql_server_options)
  validate_hash($certificate_specs)

  if $enable_internal_tls {
    if $generate_service_certificates {
      ensure_resource('class', 'tripleo::certmonger::mysql', $certificate_specs)
    }
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
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
        'bind-address'     => $bind_address,
        'max_connections'  => hiera('mysql_max_connections'),
        'open_files_limit' => '-1',
        'ssl'              => $enable_internal_tls,
        'ssl-key'          => $tls_keyfile,
        'ssl-cert'         => $tls_certfile,
        'ssl-ca'           => undef,
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
    if hiera('glance_api_enabled', false) {
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
      # NOTE(aschultz): I am generally opposed to this, however given that the
      # nova api is optional, we need to do this lookups only if not provided
      # via parameters.
      $messaging_driver_real = pick($nova_messaging_driver,
        hiera('messaging_service_name', 'rabbit'))
      $messaging_hosts_real = any2array(
        pick($nova_messaging_hosts, hiera('rabbitmq_node_names')))
      # TODO(aschultz): remove sprintf once we properly type the port, needs
      # to be a string for the os_transport_url function.
      $messaging_port_real = sprintf('%s',
        pick($nova_messaging_port, hiera('nova::rabbit_port', '5672')))
      $messaging_username_real = pick($nova_messaging_username,
        hiera('nova::rabbit_userid', 'guest'))
      $messaging_password_real = pick($nova_messaging_password,
        hiera('nova::rabbit_password'))
      $messaging_use_ssl_real = sprintf('%s', bool2num(str2bool(
        pick($nova_messaging_use_ssl, hiera('nova::rabbit_user_ssl', '0')))))

      # TODO(aschultz): switch this back to an include once setup_cell0 in THT
      class { '::nova::db::mysql_api':
        setup_cell0 => true,
      }
      class { '::nova::db::sync_cell_v2':
        transport_url => os_transport_url({
          'transport' => $messaging_driver_real,
          'hosts'     => $messaging_hosts_real,
          'port'      => $messaging_port_real,
          'username'  => $messaging_username_real,
          'password'  => $messaging_password_real,
          'ssl'       => $messaging_use_ssl_real,
        }),
      }
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::db::mysql
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::db::mysql
    }
    if hiera('panko_api_enabled', false) {
      include ::panko::db::mysql
    }
  }

}
