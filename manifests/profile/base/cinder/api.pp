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
# == Class: tripleo::profile::base::cinder::api
#
# Cinder API profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('cinder_api_short_bootstrap_node_name', undef, undef, undef)
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
# [*cinder_api_network*]
#   (Optional) The network name where the cinder API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('cinder_api_network', undef, undef, undef)
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
class tripleo::profile::base::cinder::api (
  $bootstrap_node      = lookup('cinder_api_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs  = lookup('apache_certificates_specs', undef, undef, {}),
  $cinder_api_network  = lookup('cinder_api_network', undef, undef, undef),
  $enable_internal_tls = lookup('enable_internal_tls', undef, undef, false),
  $step                = Integer(lookup('step')),
) {

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::cinder
  include tripleo::profile::base::cinder::authtoken

  if $enable_internal_tls {
    if !$cinder_api_network {
      fail('cinder_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${cinder_api_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${cinder_api_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    class { 'cinder::api':
      sync_db => $sync_db,
    }
    include cinder::healthcheck
    include tripleo::profile::base::apache
    class { 'cinder::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }
}
