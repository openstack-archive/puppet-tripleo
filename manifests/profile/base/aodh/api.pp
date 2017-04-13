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
# == Class: tripleo::profile::base::aodh::api
#
# aodh API profile for tripleo
#
# === Parameters
#
# [*aodh_network*]
#   (Optional) The network name where the aodh endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('aodh_api_network', undef)
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
# [*generate_service_certificates*]
#   (Optional) Whether or not certmonger will generate certificates for
#   HAProxy. This could be as many as specified by the $certificates_specs
#   variable.
#   Note that this doesn't configure the certificates in haproxy, it merely
#   creates the certificates.
#   Defaults to hiera('generate_service_certificate', false).
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#

class tripleo::profile::base::aodh::api (
  $aodh_network                  = hiera('aodh_api_network', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_service_certificates = hiera('generate_service_certificates', false),
  $step                          = hiera('step'),
) {

  include ::tripleo::profile::base::aodh

  if $enable_internal_tls {
    if $generate_service_certificates {
      ensure_resources('tripleo::certmonger::httpd', $certificates_specs)
    }

    if !$aodh_network {
      fail('aodh_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${aodh_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${aodh_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }


  if $step >= 3 {
    include ::aodh::api
    include ::apache::mod::ssl
    class { '::aodh::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }
}
