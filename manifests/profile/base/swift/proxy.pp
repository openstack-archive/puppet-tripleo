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
#   Defaults to lookup('swift_proxy_short_bootstrap_node_name', undef, undef, undef)
#
# [*ceilometer_enabled*]
#   Whether the ceilometer pipeline is enabled.
#   Defaults to true
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_scheme', undef, undef, rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef))
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_port', undef, undef, 5672)
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
# [*memcache_port*]
#   (Optional) Memcached port to use.
#   Defaults to lookup('memcached_port', undef, undef, 11211)
#
# [*memcache_servers*]
#   (Optional) List of memcache servers
#   Defaults to lookup('memcached_node_names', undef, undef, [])
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*swift_proxy_network*]
#   (Optional) The network name where the swift proxy endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('swift_proxy_network', undef, undef, undef)
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
# [*audit_enabled*]
#   Whether the pycadf audit middleware is is enabled.
#   Defaults to false
#
class tripleo::profile::base::swift::proxy (
  $bootstrap_node       = lookup('swift_proxy_short_bootstrap_node_name', undef, undef, undef),
  $ceilometer_enabled   = true,
  $oslomsg_rpc_proto    = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $oslomsg_rpc_hosts    = any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef)),
  $oslomsg_rpc_password = lookup('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port     = lookup('oslo_messaging_rpc_port', undef, undef, '5672'),
  $oslomsg_rpc_username = lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest'),
  $oslomsg_rpc_use_ssl  = lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0'),
  $certificates_specs   = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls  = lookup('enable_internal_tls', undef, undef, false),
  $memcache_port        = lookup('memcached_port', undef, undef, 11211),
  $memcache_servers     = lookup('memcached_node_names', undef, undef, []),
  $step                 = Integer(lookup('step')),
  $swift_proxy_network  = lookup('swift_proxy_network', undef, undef, undef),
  $tls_proxy_bind_ip    = undef,
  $tls_proxy_fqdn       = undef,
  $tls_proxy_port       = 8080,
  $audit_enabled        = false,
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
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
      include tripleo::profile::base::apache
    }
  }
  include tripleo::profile::base::swift
  if $step >= 4 {
    $swift_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcache_servers)), ":${memcache_port}")
    include swift
    include swift::config
    include swift::proxy
    include swift::proxy::catch_errors
    include swift::proxy::gatekeeper
    include swift::proxy::healthcheck
    include swift::proxy::proxy_logging
    class { 'swift::proxy::cache':
      memcache_servers => $swift_memcache_servers
    }
    include swift::proxy::listing_formats
    include swift::proxy::ratelimit
    include swift::proxy::bulk
    include swift::proxy::tempurl
    include swift::proxy::formpost
    include swift::proxy::authtoken
    include swift::proxy::s3api
    include swift::proxy::s3token
    include swift::proxy::keystone
    include swift::proxy::staticweb
    include swift::proxy::copy
    include swift::proxy::container_quotas
    include swift::proxy::account_quotas
    include swift::proxy::slo
    include swift::proxy::dlo
    include swift::proxy::versioned_writes
    if $ceilometer_enabled {
      $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
      class { 'swift::proxy::ceilometer':
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
    include swift::proxy::kms_keymaster
    include swift::proxy::encryption
    include swift::keymaster
    if $audit_enabled {
      include swift::proxy::audit
    }
  }
}
