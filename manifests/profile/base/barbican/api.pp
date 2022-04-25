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
# == Class: tripleo::profile::base::barbican::api
#
# Barbican profile for tripleo api
#
# === Parameters
#
# [*barbican_network*]
#   (Optional) The network name where the barbican endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('barbican_api_network', undef, undef, undef)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('barbican_api_bootstrap_node_name', undef, undef, undef)
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
#   Defaults to lookup('apache_certificates_specs', undef, undef, {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to any2array(lookup('oslo_messaging_rpc_node_names', unef, undef, undef))
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_port', undef, undef, '5672')
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef))
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_port', undef, undef, '5672')
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_user_name', undef, undef, 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_notify_use_ssl', undef, undef, '0')

class tripleo::profile::base::barbican::api (
  $barbican_network        = lookup('barbican_api_network', undef, undef, undef),
  $bootstrap_node          = lookup('barbican_api_bootstrap_node_name', undef, undef, undef),
  $certificates_specs      = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls     = lookup('enable_internal_tls', undef, undef, false),
  $step                    = Integer(lookup('step')),
  $oslomsg_rpc_proto       = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef)),
  $oslomsg_rpc_password    = lookup('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = lookup('oslo_messaging_rpc_port', undef, undef, '5672'),
  $oslomsg_rpc_username    = lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest'),
  $oslomsg_rpc_use_ssl     = lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0'),
  $oslomsg_notify_proto    = lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit'),
  $oslomsg_notify_hosts    = any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef)),
  $oslomsg_notify_password = lookup('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = lookup('oslo_messaging_notify_port', undef, undef, '5672'),
  $oslomsg_notify_username = lookup('oslo_messaging_notify_user_name', undef, undef, 'guest'),
  $oslomsg_notify_use_ssl  = lookup('oslo_messaging_notify_use_ssl', undef, undef, '0'),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $enable_internal_tls {
    if !$barbican_network {
      fail('barbican_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${barbican_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${barbican_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  include tripleo::profile::base::barbican
  include tripleo::profile::base::barbican::authtoken

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    include tripleo::profile::base::barbican::backends

    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    class { 'barbican::api':
      sync_db                        => $sync_db,
      default_transport_url          => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
      notification_transport_url     => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_notify_use_ssl_real,
      }),
      multiple_secret_stores_enabled => true,
      enabled_secret_stores          => $::tripleo::profile::base::barbican::backends::enabled_secret_stores,
    }
    include barbican::api::logging
    include barbican::healthcheck
    include barbican::keystone::notification
    include barbican::quota
    include tripleo::profile::base::apache
    class { 'barbican::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }
}
