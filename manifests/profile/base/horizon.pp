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
#   Defaults to hiera('step')
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
# [*horizon_network*]
#   (Optional) The network name where the horizon endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('horizon_network', undef)
#
# [*neutron_options*]
#   (Optional) A hash of parameters to enable features specific to Neutron
#   Defaults to hiera('horizon::neutron_options', {})
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to hiera('memcached_node_ips')
#
class tripleo::profile::base::horizon (
  $step                = Integer(hiera('step')),
  $bootstrap_node      = hiera('bootstrap_nodeid', undef),
  $certificates_specs  = hiera('apache_certificates_specs', {}),
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $horizon_network     = hiera('horizon_network', undef),
  $neutron_options     = hiera('horizon::neutron_options', {}),
  $memcached_ips       = hiera('memcached_node_ips')
) {
  if $::hostname == downcase($bootstrap_node) {
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
    include ::apache::mod::remoteip
    include ::tripleo::profile::base::apache

    if 'cisco_n1kv' in hiera('neutron::plugins::ml2::mechanism_drivers', undef) {
      $_profile_support = 'cisco'
    } else {
      $_profile_support = 'None'
    }
    $neutron_options_real = merge({'profile_support' => $_profile_support }, $neutron_options)

    if is_ipv6_address($memcached_ips[0]) {
        $horizon_memcached_servers = prefix(any2array(normalize_ip_for_uri($memcached_ips)), 'inet6:')

    } else {
        $horizon_memcached_servers = any2array(normalize_ip_for_uri($memcached_ips))
    }

    class { '::horizon':
      cache_server_ip => $horizon_memcached_servers,
      neutron_options => $neutron_options_real,
      horizon_cert    => $tls_certfile,
      horizon_key     => $tls_keyfile,
    }
  }
}
