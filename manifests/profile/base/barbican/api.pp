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
#   Defaults to hiera('barbican_api_network', undef)
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
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('messaging_rpc_service_name', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('barbican::api::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('barbican::api::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('barbican::api::rabbit_password')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('messaging_notify_service_name', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('barbican::api::rabbit_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('barbican::api::rabbit_userid', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('barbican::api::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('barbican::api::rabbit_use_ssl', '0')

class tripleo::profile::base::barbican::api (
  $barbican_network              = hiera('barbican_api_network', undef),
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $step                          = Integer(hiera('step')),
  $oslomsg_rpc_proto             = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts             = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_rpc_password          = hiera('barbican::api::rabbit_password'),
  $oslomsg_rpc_port              = hiera('barbican::api::rabbit_port', '5672'),
  $oslomsg_rpc_username          = hiera('barbican::api::rabbit_userid', 'guest'),
  $oslomsg_notify_proto          = hiera('messaging_notify_service_name', 'rabbit'),
  $oslomsg_notify_hosts          = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_notify_password       = hiera('barbican::api::rabbit_password'),
  $oslomsg_notify_port           = hiera('barbican::api::rabbit_port', '5672'),
  $oslomsg_notify_username       = hiera('barbican::api::rabbit_userid', 'guest'),
  $oslomsg_use_ssl               = hiera('barbican::api::rabbit_use_ssl', '0'),
) {
  if $::hostname == downcase($bootstrap_node) {
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

  include ::tripleo::profile::base::barbican

  if $step >= 3 and $sync_db {
    include ::barbican::db::mysql
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    class { '::barbican::api':
      sync_db                    => $sync_db,
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
    }
    include ::barbican::keystone::authtoken
    include ::barbican::api::logging
    include ::barbican::keystone::notification
    include ::barbican::quota
    include ::apache::mod::ssl
    class { '::barbican::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }
}
