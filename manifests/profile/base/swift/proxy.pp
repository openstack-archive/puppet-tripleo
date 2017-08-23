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
# == Class: tripleo::profile::base::swift::proxy
#
# Swift proxy profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*ceilometer_enabled*]
#   Whether the ceilometer pipeline is enabled.
#   Defaults to true
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
# [*memcache_port*]
#   (Optional) memcache port
#   Defaults to 11211
#
# [*memcache_servers*]
#   (Optional) List of memcache servers
#   Defaults to hiera('memcached_node_ips')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*swift_proxy_network*]
#   (Optional) The network name where the swift proxy endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('swift_proxy_network', undef)
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
#   defaults to 8080
#
class tripleo::profile::base::swift::proxy (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $ceilometer_enabled   = true,
  $oslomsg_rpc_proto    = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $oslomsg_rpc_hosts    = any2array(hiera('oslo_messaging_rpc_node_names', undef)),
  $oslomsg_rpc_password = hiera('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port     = hiera('oslo_messaging_rpc_port', '5672'),
  $oslomsg_rpc_username = hiera('oslo_messaging_rpc_user_name', 'guest'),
  $oslomsg_rpc_use_ssl  = hiera('oslo_messaging_rpc_use_ssl', '0'),
  $certificates_specs   = hiera('apache_certificates_specs', {}),
  $enable_internal_tls  = hiera('enable_internal_tls', false),
  $memcache_port        = 11211,
  $memcache_servers     = hiera('memcached_node_ips'),
  $step                 = Integer(hiera('step')),
  $swift_proxy_network  = hiera('swift_proxy_network', undef),
  $tls_proxy_bind_ip    = undef,
  $tls_proxy_fqdn       = undef,
  $tls_proxy_port       = 8080,
) {
  if $::hostname == downcase($bootstrap_node) {
    $is_bootstrap = true
  } else {
    $is_bootstrap = false
  }
  if $step >= 4 or ($step >= 3 and $is_bootstrap) {
    if $enable_internal_tls {
      if !$swift_proxy_network {
        fail('swift_proxy_network is not set in the hieradata.')
      }
      $tls_certfile = $certificates_specs["httpd-${swift_proxy_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${swift_proxy_network}"]['service_key']

      ::tripleo::tls_proxy { 'swift-proxy-api':
        servername => $tls_proxy_fqdn,
        ip         => $tls_proxy_bind_ip,
        port       => $tls_proxy_port,
        tls_cert   => $tls_certfile,
        tls_key    => $tls_keyfile,
      }
      Tripleo::Tls_proxy['swift-proxy-api'] ~> Anchor<| title == 'swift::service::begin' |>
    }
  }
  if $step >= 4 {
    $swift_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcache_servers)), ":${memcache_port}")
    include ::swift
    include ::swift::config
    include ::swift::proxy
    include ::swift::proxy::proxy_logging
    include ::swift::proxy::healthcheck
    class { '::swift::proxy::cache':
      memcache_servers => $swift_memcache_servers
    }
    include ::swift::proxy::keystone
    include ::swift::proxy::authtoken
    include ::swift::proxy::staticweb
    include ::swift::proxy::ratelimit
    include ::swift::proxy::catch_errors
    include ::swift::proxy::tempurl
    include ::swift::proxy::formpost
    include ::swift::proxy::bulk
    if $ceilometer_enabled {
      $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
      class { '::swift::proxy::ceilometer':
        default_transport_url      => os_transport_url({
          'transport' => $oslomsg_rpc_proto,
          'hosts'     => $oslomsg_rpc_hosts,
          'port'      => $oslomsg_rpc_port,
          'username'  => $oslomsg_rpc_username,
          'password'  => $oslomsg_rpc_password,
          'ssl'       => $oslomsg_rpc_use_ssl_real,
        }),
      }
    }
    include ::swift::proxy::versioned_writes
    include ::swift::proxy::slo
    include ::swift::proxy::dlo
    include ::swift::proxy::copy
    include ::swift::proxy::container_quotas
    include ::swift::proxy::account_quotas
    include ::swift::proxy::encryption
    include ::swift::proxy::kms_keymaster
    include ::swift::keymaster
    include ::swift::proxy::s3api
    include ::swift::proxy::s3token

    class { '::swift::objectexpirer':
      pipeline         => ['catch_errors', 'cache', 'proxy-server'],
      memcache_servers => $swift_memcache_servers
    }
  }
}
