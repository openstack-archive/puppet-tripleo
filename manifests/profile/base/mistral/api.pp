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
# == Class: tripleo::profile::base::mistral::api
#
# Mistral API profile for tripleo
#
# === Parameters
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
# [*mistral_api_network*]
#   (Optional) The network name where the mistral API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('mistral_api_network', undef)
#
# [*mistral_api_wsgi_enabled*]
#   (Optional) Whether or not deploy Mistral API in WSGI with Apache.
#   Defaults to hiera('mistral_wsgi_enabled', true)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::mistral::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $mistral_api_network           = hiera('mistral_api_network', undef),
  $mistral_api_wsgi_enabled      = hiera('mistral_wsgi_enabled', true),
  $step                          = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $is_bootstrap = true
  } else {
    $is_bootstrap = false
  }

  include ::tripleo::profile::base::mistral

  if $enable_internal_tls {
    if !$mistral_api_network {
      fail('mistral_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${mistral_api_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${mistral_api_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ( $step >= 3 and $is_bootstrap ) {
    include ::mistral::api
    include ::mistral::cron_trigger
    # Temporarily disable Mistral API deployed in WSGI
    # https://bugs.launchpad.net/tripleo/+bug/1724607
    if $mistral_api_wsgi_enabled {
      include ::tripleo::profile::base::apache
      class { '::mistral::wsgi::apache':
        ssl_cert => $tls_certfile,
        ssl_key  => $tls_keyfile,
      }
    }
  }
}

