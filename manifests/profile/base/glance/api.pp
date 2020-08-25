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
# == Class: tripleo::profile::base::glance::api
#
# Glance API profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('glance_api_short_bootstrap_node_name')
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
# [*glance_backend*]
#   (Optional) Default glance backend type.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*glance_backend_id*]
#   (Optional) Default glance backend identifier.
#   Defaults to 'default_backend'
#
# [*glance_network*]
#   (Optional) The network name where the glance endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('glance_api_network', undef)
#
# [*multistore_config*]
#   (Optional) Hash of settings for configuring additional glance-api backends.
#   Defaults to {}
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
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
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 9292
#
# [*glance_enable_db_purge*]
#   (optional) Whether to enable db purging
#   defaults to true
#
# DEPRECATED PARAMETERS
#
# [*glance_rbd_client_name*]
#   (optional) Deprecated. RBD client name
#   Defaults to undef
#
class tripleo::profile::base::glance::api (
  $bootstrap_node          = hiera('glance_api_short_bootstrap_node_name', undef),
  $certificates_specs      = hiera('apache_certificates_specs', {}),
  $enable_internal_tls     = hiera('enable_internal_tls', false),
  $glance_backend          = downcase(hiera('glance_backend', 'swift')),
  $glance_backend_id       = 'default_backend',
  $glance_network          = hiera('glance_api_network', undef),
  $multistore_config       = {},
  $step                    = Integer(hiera('step')),
  $oslomsg_rpc_proto       = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(hiera('oslo_messaging_rpc_node_names', undef)),
  $oslomsg_rpc_password    = hiera('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = hiera('oslo_messaging_rpc_port', '5672'),
  $oslomsg_rpc_username    = hiera('oslo_messaging_rpc_user_name', 'guest'),
  $oslomsg_rpc_use_ssl     = hiera('oslo_messaging_rpc_use_ssl', '0'),
  $oslomsg_notify_proto    = hiera('oslo_messaging_notify_scheme', 'rabbit'),
  $oslomsg_notify_hosts    = any2array(hiera('oslo_messaging_notify_node_names', undef)),
  $oslomsg_notify_password = hiera('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = hiera('oslo_messaging_notify_port', '5672'),
  $oslomsg_notify_username = hiera('oslo_messaging_notify_user_name', 'guest'),
  $oslomsg_notify_use_ssl  = hiera('oslo_messaging_notify_use_ssl', '0'),
  $tls_proxy_bind_ip       = undef,
  $tls_proxy_fqdn          = undef,
  $tls_proxy_port          = 9292,
  $glance_enable_db_purge  = true,
  # DEPRECATED PARAMETERS
  $glance_rbd_client_name  = undef,
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::glance::authtoken

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$glance_network {
        fail('glance_api_network is not set in the hieradata.')
      }
      if !$tls_proxy_bind_ip {
        fail('glance_api_tls_proxy_bind_ip is not set in the hieradata.')
      }
      if !$tls_proxy_fqdn {
        fail('tls_proxy_fqdn is required if internal TLS is enabled.')
      }
      $tls_certfile = $certificates_specs["httpd-${glance_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${glance_network}"]['service_key']

      ::tripleo::tls_proxy { 'glance-api':
        servername => $tls_proxy_fqdn,
        ip         => $tls_proxy_bind_ip,
        port       => $tls_proxy_port,
        tls_cert   => $tls_certfile,
        tls_key    => $tls_keyfile,
        notify     => Class['::glance::api'],
      }
      include tripleo::profile::base::apache
    }

    $multistore_backends = $multistore_config.map |$backend_config| {
      unless has_key($backend_config[1], 'GlanceBackend') {
        fail("multistore_config '${backend_config[0]}' does not specify a glance_backend.")
      }
      "${backend_config[0]}:${backend_config[1]['GlanceBackend']}"
    }

    $enabled_backends = ["${glance_backend_id}:${glance_backend}"] + $multistore_backends

    include glance
    include glance::config
    include glance::api::logging
    class { 'glance::api':
      enabled_backends => $enabled_backends,
      default_backend  => $glance_backend_id,
      sync_db          => $sync_db,
    }

    ['cinder', 'file', 'rbd', 'swift'].each |String $backend_type| {

      # Generate a list of backend names for a given backend type
      $backend_names = $enabled_backends.reduce([]) |$accum, String $backend| {
        $backend_info = $backend.split(':')
        if $backend_info[1] == $backend_type {
          $accum << $backend_info[0]
        } else {
          $accum
        }
      }

      unless empty($backend_names) {
        class { "tripleo::profile::base::glance::backend::${backend_type}":
          backend_names     => $backend_names,
          multistore_config => $multistore_config,
        }
      }
    }

    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    class { 'glance::notify::rabbitmq' :
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
    }
  }

  if $step >= 5 {
    if $glance_enable_db_purge {
      include glance::cron::db_purge
    }
  }

}
