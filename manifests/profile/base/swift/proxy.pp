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
# [*ceilometer_messaging_driver*]
#   Driver for messaging service.
#   Defaults to hiera('messaging_notify_service_name', 'rabbit')
#
# [*ceilometer_messaging_hosts*]
#   list of the messaging host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*ceilometer_messaging_password*]
#   Password for messaging nova queue
#   Defaults to hiera('swift::proxy::ceilometer::rabbit_password', undef)
#
# [*ceilometer_messaging_port*]
#   IP port for messaging service
#   Defaults to hiera('tripleo::profile::base::swift::proxy::rabbit_port', 5672)
#
# [*ceilometer_messaging_use_ssl*]
#   Flag indicating ssl usage.
#   Defaults to '0'
#
# [*ceilometer_messaging_username*]
#   Username for messaging nova queue
#   Defaults to hiera('swift::proxy::ceilometer::rabbit_user', 'guest')
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
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names', undef)
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
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $ceilometer_enabled            = true,
  $ceilometer_messaging_driver   = hiera('messaging_notify_service_name', 'rabbit'),
  $ceilometer_messaging_hosts    = hiera('rabbitmq_node_names', undef),
  $ceilometer_messaging_password = hiera('swift::proxy::ceilometer::rabbit_password', undef),
  $ceilometer_messaging_port     = hiera('tripleo::profile::base::swift::proxy::rabbit_port', '5672'),
  $ceilometer_messaging_use_ssl  = '0',
  $ceilometer_messaging_username = hiera('swift::proxy::ceilometer::rabbit_user', 'guest'),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $memcache_port                 = 11211,
  $memcache_servers              = hiera('memcached_node_ips'),
  $oslomsg_rpc_hosts             = hiera('oslo_messaging_rpc_node_names', undef),
  $step                          = Integer(hiera('step')),
  $swift_proxy_network           = hiera('swift_proxy_network', undef),
  $tls_proxy_bind_ip             = undef,
  $tls_proxy_fqdn                = undef,
  $tls_proxy_port                = 8080,
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
    $ceilometer_messaging_use_ssl_real = sprintf('%s', bool2num(str2bool($ceilometer_messaging_use_ssl)))
    $ceilometer_messaging_hosts_real = any2array(pick($ceilometer_messaging_hosts,$oslomsg_rpc_hosts, []))
    if $ceilometer_enabled {
      class { '::swift::proxy::ceilometer':
        default_transport_url => os_transport_url({
          'transport' => $ceilometer_messaging_driver,
          'hosts'     => $ceilometer_messaging_hosts_real,
          'port'      => sprintf('%s', $ceilometer_messaging_port),
          'username'  => $ceilometer_messaging_username,
          'password'  => $ceilometer_messaging_password,
          'ssl'       => $ceilometer_messaging_use_ssl_real,
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


    class { '::swift::objectexpirer':
      pipeline         => ['catch_errors', 'cache', 'proxy-server'],
      memcache_servers => $swift_memcache_servers
    }
  }
}
