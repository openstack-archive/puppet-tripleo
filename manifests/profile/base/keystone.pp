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
# [*admin_endpoint_network*]
#   (Optional) The network name where the admin endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('keystone_admin_api_network', undef)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     apache_certificates_specs:
#       httpd-internal_api:
#         hostname: <overcloud controller fqdn>
#         service_certificate: <service certificate path>
#         service_key: <service key path>
#         principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to hiera('apache_certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*generate_service_certificates*]
#   (Optional) Whether or not certmonger will generate certificates for
#   HAProxy. This could be as many as specified by the $certificates_specs
#   variable.
#   Note that this doesn't configure the certificates in haproxy, it merely
#   creates the certificates.
#   Defaults to hiera('generate_service_certificate', false).
#
# [*heat_admin_domain*]
#   domain name for heat admin
#   Defaults to undef
#
# [*heat_admin_email*]
#   heat admin email address
#   Defaults to undef
#
# [*heat_admin_password*]
#   heat admin password
#   Defaults to undef
#
# [*heat_admin_user*]
#   heat admin user name
#   Defaults to undef
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
# [*public_endpoint_network*]
#   (Optional) The network name where the admin endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('keystone_public_api_network', undef)
#
#
# [*rabbit_hosts*]
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('keystone::rabbit_port', 5672)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::keystone (
  $admin_endpoint_network        = hiera('keystone_admin_api_network', undef),
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_service_certificates = hiera('generate_service_certificates', false),
  $heat_admin_domain             = undef,
  $heat_admin_email              = undef,
  $heat_admin_password           = undef,
  $heat_admin_user               = undef,
  $manage_db_purge               = hiera('keystone_enable_db_purge', true),
  $public_endpoint_network       = hiera('keystone_public_api_network', undef),
  $rabbit_hosts                  = hiera('rabbitmq_node_names', undef),
  $rabbit_port                   = hiera('keystone::rabbit_port', 5672),
  $step                          = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
    $manage_roles = true
    $manage_endpoint = true
    $manage_domain = true
  } else {
    $sync_db = false
    $manage_roles = false
    $manage_endpoint = false
    $manage_domain = false
  }

  if $enable_internal_tls {
    if $generate_service_certificates {
      ensure_resources('tripleo::certmonger::httpd', $certificates_specs)
    }

    if !$public_endpoint_network {
      fail('keystone_public_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${public_endpoint_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${public_endpoint_network}"]['service_key']

    if !$admin_endpoint_network {
      fail('keystone_admin_api_network is not set in the hieradata.')
    }
    $tls_certfile_admin = $certificates_specs["httpd-${admin_endpoint_network}"]['service_certificate']
    $tls_keyfile_admin = $certificates_specs["httpd-${admin_endpoint_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $tls_certfile_admin = undef
    $tls_keyfile_admin = undef
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    $rabbit_endpoints = suffix(any2array($rabbit_hosts), ":${rabbit_port}")
    class { '::keystone':
      sync_db          => $sync_db,
      enable_bootstrap => $sync_db,
      rabbit_hosts     => $rabbit_endpoints,
    }

    include ::keystone::config
    class { '::keystone::wsgi::apache':
      ssl_cert       => $tls_certfile,
      ssl_key        => $tls_keyfile,
      ssl_cert_admin => $tls_certfile_admin,
      ssl_key_admin  => $tls_keyfile_admin,
    }
    include ::keystone::cors

    if $manage_roles {
      include ::keystone::roles::admin
    }

    if $manage_endpoint {
      include ::keystone::endpoint
    }

  }

  if $step >= 5 and $manage_db_purge {
    include ::keystone::cron::token_flush
  }

  if $step >= 5 and $manage_domain {
    if hiera('heat_engine_enabled', false) {
      # create these seperate and don't use ::heat::keystone::domain since
      # that class writes out the configs
      keystone_domain { $heat_admin_domain:
        ensure  => 'present',
        enabled => true
      }
      keystone_user { "${heat_admin_user}::${heat_admin_domain}":
        ensure   => 'present',
        enabled  => true,
        email    => $heat_admin_email,
        password => $heat_admin_password
      }
      keystone_user_role { "${heat_admin_user}::${heat_admin_domain}@::${heat_admin_domain}":
        roles   => ['admin'],
        require => Class['::keystone::roles::admin']
      }
    }
  }

  if $step >= 5 and $manage_endpoint{
    if hiera('aodh_api_enabled', false) {
      include ::aodh::keystone::auth
    }
    if hiera('barbican_api_enabled', false) {
      include ::barbican::keystone::auth
    }
    if hiera('ceilometer_api_enabled', false) {
      include ::ceilometer::keystone::auth
    }
    if hiera('ceph_rgw_enabled', false) {
      include ::ceph::rgw::keystone::auth
    }
    if hiera('cinder_api_enabled', false) {
      include ::cinder::keystone::auth
    }
    if hiera('glance_api_enabled', false) {
      include ::glance::keystone::auth
    }
    if hiera('gnocchi_api_enabled', false) {
      include ::gnocchi::keystone::auth
    }
    if hiera('heat_api_enabled', false) {
      include ::heat::keystone::auth
    }
    if hiera('heat_api_cfn_enabled', false) {
      include ::heat::keystone::auth_cfn
    }
    if hiera('ironic_api_enabled', false) {
      include ::ironic::keystone::auth
    }
    if hiera('manila_api_enabled', false) {
      include ::manila::keystone::auth
    }
    if hiera('mistral_api_enabled', false) {
      include ::mistral::keystone::auth
    }
    if hiera('neutron_api_enabled', false) {
      include ::neutron::keystone::auth
    }
    if hiera('nova_api_enabled', false) {
      include ::nova::keystone::auth
    }
    if hiera('nova_placement_enabled', false) {
      include ::nova::keystone::auth_placement
    }
    if hiera('panko_api_enabled', false) {
      include ::panko::keystone::auth
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::keystone::auth
    }
    if hiera('swift_proxy_enabled', false) {
      include ::swift::keystone::auth
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::keystone::auth
    }
    if hiera('zaqar_enabled', false) {
      include ::zaqar::keystone::auth
      include ::zaqar::keystone::auth_websocket
    }
  }
}

