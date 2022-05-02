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
# == Class: tripleo::profile::base::horizon
#
# Horizon profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('horizon_short_bootstrap_node_name', undef, undef, undef)
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
# [*horizon_network*]
#   (Optional) The network name where the horizon endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('horizon_network', undef, undef, undef)
#
# [*neutron_options*]
#   (Optional) A hash of parameters to enable features specific to Neutron
#   Defaults to lookup('horizon::neutron_options', undef, undef, {})
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to lookup('memcached_node_ips', undef, undef, [])
#
# [*heat_api_enabled*]
#   (Optional) Indicate whether Heat is available in the deployment.
#   Defaults to lookup('heat_api_enabled', undef, undef, false)
#
# [*octavia_api_enabled*]
#   (Optional) Indicate whether Octavia is available in the deployment.
#   Defaults to lookup('octavia_api_enabled', undef, undef, false)
#
# [*manila_api_enabled*]
#   (Optional) Indicate whether Manila is available in the deployment.
#   Defaults to lookup('manila_api_enabled', undef, undef, false)
#
class tripleo::profile::base::horizon (
  $step                = Integer(lookup('step')),
  $bootstrap_node      = lookup('horizon_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs  = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls = lookup('enable_internal_tls', undef, undef, false),
  $horizon_network     = lookup('horizon_network', undef, undef, undef),
  $neutron_options     = lookup('horizon::neutron_options', undef, undef, {}),
  $memcached_ips       = lookup('memcached_node_ips', undef, undef, []),
  $heat_api_enabled    = lookup('heat_api_enabled', undef, undef, false),
  $octavia_api_enabled = lookup('octavia_api_enabled', undef, undef, false),
  $manila_api_enabled  = lookup('manila_api_enabled', undef, undef, false),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $is_bootstrap = true
  } else {
    $is_bootstrap = false
  }

  if $enable_internal_tls {
    if !$horizon_network {
      fail('horizon_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${horizon_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${horizon_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ( $step >= 3 and $is_bootstrap ) {
    # Horizon
    include tripleo::profile::base::apache
    include apache::mod::remoteip

    if $memcached_ips[0] =~ Stdlib::Compat::Ipv6 {
      $horizon_memcached_servers = prefix(any2array(normalize_ip_for_uri($memcached_ips)), 'inet6:')
    } else {
      $horizon_memcached_servers = any2array(normalize_ip_for_uri($memcached_ips))
    }

    class { 'horizon':
      cache_server_ip => $horizon_memcached_servers,
      neutron_options => $neutron_options,
      ssl_cert        => $tls_certfile,
      ssl_key         => $tls_keyfile,
    }
    include horizon::policy

    if $heat_api_enabled {
      include horizon::dashboards::heat
    }

    if $octavia_api_enabled {
      include horizon::dashboards::octavia
    }

    if $manila_api_enabled {
      include horizon::dashboards::manila
    }
  }
}
