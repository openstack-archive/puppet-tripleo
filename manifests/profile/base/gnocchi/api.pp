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
# == Class: tripleo::profile::base::gnocchi::api
#
# Gnocchi profile for tripleo api
#
# === Parameters
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
# [*generate_service_certificates*]
#   (Optional) Whether or not certmonger will generate certificates for
#   HAProxy. This could be as many as specified by the $certificates_specs
#   variable.
#   Note that this doesn't configure the certificates in haproxy, it merely
#   creates the certificates.
#   Defaults to hiera('generate_service_certificate', false).
#
# [*gnocchi_backend*]
#   (Optional) Gnocchi backend string file, swift or rbd
#   Defaults to swift
#
# [*gnocchi_network*]
#   (Optional) The network name where the gnocchi endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('gnocchi_api_network', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::gnocchi::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_service_certificates = hiera('generate_service_certificates', false),
  $gnocchi_backend               = downcase(hiera('gnocchi_backend', 'swift')),
  $gnocchi_network               = hiera('gnocchi_api_network', undef),
  $step                          = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::gnocchi

  if $enable_internal_tls {
    if $generate_service_certificates {
      ensure_resources('tripleo::certmonger::httpd', $certificates_specs)
    }

    if !$gnocchi_network {
      fail('gnocchi_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${gnocchi_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${gnocchi_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 3 and $sync_db {
    include ::gnocchi::db::sync
  }

  if $step >= 3 {
    include ::gnocchi::api
    include ::apache::mod::ssl
    class { '::gnocchi::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }

  if $step >= 4 {
    class { '::gnocchi::storage':
      coordination_url => join(['redis://:', hiera('gnocchi_redis_password'), '@', normalize_ip_for_uri(hiera('redis_vip')), ':6379/']),
    }
    case $gnocchi_backend {
      'swift': { include ::gnocchi::storage::swift }
      'file': { include ::gnocchi::storage::file }
      'rbd': { include ::gnocchi::storage::ceph }
      default: { fail('Unrecognized gnocchi_backend parameter.') }
    }
  }

  # Re-run gnochci upgrade with storage as swift/ceph should be up at this
  # stage.
  if $step >= 5 and $sync_db {
    exec {'run gnocchi upgrade with storage':
      command => 'gnocchi-upgrade --config-file=/etc/gnocchi/gnocchi.conf',
      path    => ['/usr/bin', '/usr/sbin'],
    }
  }
}
