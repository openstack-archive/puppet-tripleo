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
# == Class: tripleo::profile::base::gnocchi
#
# Gnocchi profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('gnocchi_api_short_bootstrap_node_name')
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
# [*gnocchi_redis_password*]
#  (Required) Password for the gnocchi redis user for the coordination url
#  Defaults to hiera('gnocchi_redis_password')
#
# [*gnocchi_network*]
#   (Optional) The network name where the gnocchi endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('gnocchi_api_network', undef)
#
# [*redis_vip*]
#  (Required) Redis ip address for the coordination url
#  Defaults to hiera('redis_vip')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::gnocchi (
  $bootstrap_node         = hiera('gnocchi_api_short_bootstrap_node_name', undef),
  $certificates_specs     = hiera('apache_certificates_specs', {}),
  $enable_internal_tls    = hiera('enable_internal_tls', false),
  $gnocchi_network        = hiera('gnocchi_api_network', undef),
  $gnocchi_redis_password = hiera('gnocchi_redis_password'),
  $redis_vip              = hiera('redis_vip'),
  $step                   = Integer(hiera('step')),
) {
  warning('Gnocchi is deprecated and is going to be removed in future.')

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $enable_internal_tls {
    if !$gnocchi_network {
      fail('gnocchi_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${gnocchi_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${gnocchi_network}"]['service_key']
    $tls_query_param = '?ssl=true'
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $tls_query_param = ''
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {

    class { 'gnocchi':
      coordination_url => join(['redis://:', $gnocchi_redis_password, '@', normalize_ip_for_uri($redis_vip), ':6379/', $tls_query_param]),
    }
    include gnocchi::config
    include gnocchi::cors
    include gnocchi::client
    include gnocchi::logging
  }
}
