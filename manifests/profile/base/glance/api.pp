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
# == Class: tripleo::profile::base::glance::api
#
# Glance API profile for tripleo
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
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*glance_network*]
#   (Optional) The network name where the glance endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('glance_api_network', undef)
#
# [*glance_nfs_enabled*]
#   (Optional) Whether to use NFS mount as 'file' backend storage location.
#   Defaults to false
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('glance::notify::rabbitmq::rabbit_port', 5672)
#
class tripleo::profile::base::glance::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $generate_service_certificates = hiera('generate_service_certificates', false),
  $glance_backend                = downcase(hiera('glance_backend', 'swift')),
  $glance_network                = hiera('glance_api_network', undef),
  $glance_nfs_enabled            = false,
  $step                          = hiera('step'),
  $rabbit_hosts                  = hiera('rabbitmq_node_names', undef),
  $rabbit_port                   = hiera('glance::notify::rabbitmq::rabbit_port', 5672),
) {
  if $enable_internal_tls and $generate_service_certificates {
    ensure_resources('tripleo::certmonger::httpd', $certificates_specs)
  }

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 1 and $glance_nfs_enabled {
    include ::tripleo::glance::nfs_mount
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$glance_network {
        fail('glance_api_network is not set in the hieradata.')
      }
      $tls_certfile = $certificates_specs["httpd-${glance_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${glance_network}"]['service_key']

      ::tripleo::tls_proxy { 'glance-api':
        servername => hiera("fqdn_${glance_network}"),
        ip         => hiera('glance::api::bind_host'),
        port       => hiera('glance::api::bind_port'),
        tls_cert   => $tls_certfile,
        tls_key    => $tls_keyfile,
        notify     => Class['::glance::api'],
      }
      # TODO(jaosorior): Remove this when we pass it via t-h-t
      $bind_host = 'localhost'
    } else {
      # TODO(jaosorior): Remove this when we pass it via t-h-t
      $bind_host = hiera('glance::api::bind_host')
    }
    case $glance_backend {
        'swift': { $backend_store = 'glance.store.swift.Store' }
        'file': { $backend_store = 'glance.store.filesystem.Store' }
        'rbd': { $backend_store = 'glance.store.rbd.Store' }
        default: { fail('Unrecognized glance_backend parameter.') }
    }
    $http_store = ['glance.store.http.Store']
    $glance_store = concat($http_store, $backend_store)

    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    # TODO(jaosorior): Remove bind_host when we set it up conditionally in t-h-t
    class { '::glance::api':
      bind_host => $bind_host,
      stores    => $glance_store,
      sync_db   => $sync_db,
    }
    $rabbit_endpoints = suffix(any2array($rabbit_hosts), ":${rabbit_port}")
    class { '::glance::notify::rabbitmq' :
      rabbit_hosts => $rabbit_endpoints,
    }
    include join(['::glance::backend::', $glance_backend])
  }

}
