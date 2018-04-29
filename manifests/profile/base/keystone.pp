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
# [*ldap_backends_config*]
#   Configuration for keystone::ldap_backend. This takes a hash that will
#   create each backend specified.
#   Defaults to undef
#
# [*ldap_backend_enable*]
#   Enables creating per-domain LDAP backends for keystone.
#   Default to false
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
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_scheme', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_user_name', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_rpc_use_ssl', '0')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_scheme', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('oslo_messaging_notify_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_user_name', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_notify_use_ssl', '0')
#
# [*ceilometer_notification_topics*]
#   Notification topics that keystone should use for ceilometer to consume.
#   Defaults to []
#
# [*barbican_notification_topics*]
#   Notification topics that keystone should use for barbican to consume.
#   Defaults to []
#
# [*extra_notification_topics*]
#   Extra notification topics that keystone should produce.
#   Defaults to []
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*keystone_enable_member*]
#   (Optional) Whether _member_ role is managed or not (required for Horizon).
#   Defaults to hiera('keystone_enable_member', false)
#
class tripleo::profile::base::keystone (
  $admin_endpoint_network         = hiera('keystone_admin_api_network', undef),
  $bootstrap_node                 = hiera('bootstrap_nodeid', undef),
  $certificates_specs             = hiera('apache_certificates_specs', {}),
  $enable_internal_tls            = hiera('enable_internal_tls', false),
  $heat_admin_domain              = undef,
  $heat_admin_email               = undef,
  $heat_admin_password            = undef,
  $heat_admin_user                = undef,
  $ldap_backends_config           = undef,
  $ldap_backend_enable            = false,
  $manage_db_purge                = hiera('keystone_enable_db_purge', true),
  $public_endpoint_network        = hiera('keystone_public_api_network', undef),
  $oslomsg_rpc_proto              = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $oslomsg_rpc_hosts              = any2array(hiera('oslo_messaging_rpc_node_names', undef)),
  $oslomsg_rpc_password           = hiera('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port               = hiera('oslo_messaging_rpc_port', '5672'),
  $oslomsg_rpc_username           = hiera('oslo_messaging_rpc_user_name', 'guest'),
  $oslomsg_rpc_use_ssl            = hiera('oslo_messaging_rpc_use_ssl', '0'),
  $oslomsg_notify_proto           = hiera('oslo_messaging_notify_scheme', 'rabbit'),
  $oslomsg_notify_hosts           = any2array(hiera('oslo_messaging_notify_node_names', undef)),
  $oslomsg_notify_password        = hiera('oslo_messaging_notify_password'),
  $oslomsg_notify_port            = hiera('oslo_messaging_notify_port', '5672'),
  $oslomsg_notify_username        = hiera('oslo_messaging_notify_user_name', 'guest'),
  $oslomsg_notify_use_ssl         = hiera('oslo_messaging_notify_use_ssl', '0'),
  $ceilometer_notification_topics = [],
  $barbican_notification_topics   = [],
  $extra_notification_topics      = [],
  $step                           = Integer(hiera('step')),
  $keystone_enable_member         = hiera('keystone_enable_member', false),
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
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    class { '::keystone':
      sync_db                    => $sync_db,
      enable_bootstrap           => $sync_db,
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_notify_use_ssl_real,
      }),
      notification_topics        => union($ceilometer_notification_topics,
                                          $barbican_notification_topics,
                                          $extra_notification_topics)
    }

    if 'amqp' in [$oslomsg_rpc_proto, $oslomsg_notify_proto]{
      include ::keystone::messaging::amqp
    }

    include ::keystone::config
    include ::tripleo::profile::base::apache
    class { '::keystone::wsgi::apache':
      ssl_cert       => $tls_certfile,
      ssl_key        => $tls_keyfile,
      ssl_cert_admin => $tls_certfile_admin,
      ssl_key_admin  => $tls_keyfile_admin,
    }
    include ::keystone::cors
    include ::keystone::security_compliance

    if $ldap_backend_enable {
      validate_hash($ldap_backends_config)
      if !str2bool($::selinux) {
        selboolean { 'authlogin_nsswitch_use_ldap':
            value      => on,
            persistent => true,
        }
      }
      create_resources('::keystone::ldap_backend', $ldap_backends_config, {
        create_domain_entry => $manage_domain,
      })
    }
  }

  if $step >= 4 and $manage_db_purge {
    include ::keystone::cron::token_flush
  }

  if $step == 3 and $manage_domain {
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

  if $step == 3 and $manage_roles {
    include ::keystone::roles::admin
    if $keystone_enable_member {
      keystone_role { '_member_':
        ensure => present,
      }
    }
  }

  if $step == 3 and $manage_endpoint {
    include ::keystone::endpoint
    if hiera('aodh_api_enabled', false) {
      include ::aodh::keystone::auth
    }
    if hiera('barbican_api_enabled', false) {
      include ::barbican::keystone::auth
    }
    # ceilometer user is needed even when ceilometer api
    # not running, so it can authenticate with keystone
    # and dispatch data.
    if hiera('ceilometer_auth_enabled', false) {
      include ::ceilometer::keystone::auth
    }
    if hiera('ceph_rgw_enabled', false) {
      include ::ceph::rgw::keystone::auth
    }
    if hiera('cinder_api_enabled', false) {
      include ::cinder::keystone::auth
    }
    if hiera('congress_enabled', false) {
      include ::congress::keystone::auth
    }
    if hiera('designate_api_enabled', false) {
      include ::designate::keystone::auth
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
    if hiera('ironic_inspector_enabled', false) {
      include ::ironic::keystone::auth_inspector
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
    if hiera('octavia_api_enabled', false) {
      include ::octavia::keystone::auth
    }
    if hiera('panko_api_enabled', false) {
      include ::panko::keystone::auth
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::keystone::auth
    }
    if hiera('swift_proxy_enabled', false) or hiera('external_swift_proxy_enabled',false) {
      include ::swift::keystone::auth
    }
    if hiera('tacker_enabled', false) {
      include ::tacker::keystone::auth
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::keystone::auth
    }
    if hiera('zaqar_api_enabled', false) {
      include ::zaqar::keystone::auth
      include ::zaqar::keystone::auth_websocket
    }
    if hiera('ec2_api_enabled', false) {
      include ::ec2api::keystone::auth
    }
    if hiera('novajoin_enabled', false) {
      include ::nova::metadata::novajoin::auth
    }
    if hiera('veritas_hyperscale_controller_enabled', false) {
      include ::veritas_hyperscale::hs_keystone
    }
  }
}
