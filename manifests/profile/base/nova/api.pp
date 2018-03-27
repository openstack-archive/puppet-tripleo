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
# == Class: tripleo::profile::base::nova::api
#
# Nova API profile for tripleo
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
# [*nova_api_network*]
#   (Optional) The network name where the nova API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('nova_api_network', undef)
#
# [*nova_api_wsgi_enabled*]
#   (Optional) Whether or not deploy Nova API in WSGI with Apache.
#   Nova Team discourages it.
#   Defaults to hiera('nova_wsgi_enabled', false)
#
# [*nova_metadata_network*]
#   (Optional) The network name where the nova metadata endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('nova_metadata_network', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*metadata_tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*metadata_tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*metadata_tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 8080
#
class tripleo::profile::base::nova::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $nova_api_network              = hiera('nova_api_network', undef),
  $nova_api_wsgi_enabled         = hiera('nova_wsgi_enabled', false),
  $nova_metadata_network         = hiera('nova_metadata_network', undef),
  $step                          = Integer(hiera('step')),
  $metadata_tls_proxy_bind_ip    = undef,
  $metadata_tls_proxy_fqdn       = undef,
  $metadata_tls_proxy_port       = 8775,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::nova
  include ::tripleo::profile::base::nova::authtoken

  if $step >= 3 and $sync_db {
    include ::nova::cell_v2::simple_setup
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$nova_metadata_network {
        fail('nova_metadata_network is not set in the hieradata.')
      }
      $metadata_tls_certfile = $certificates_specs["httpd-${nova_metadata_network}"]['service_certificate']
      $metadata_tls_keyfile = $certificates_specs["httpd-${nova_metadata_network}"]['service_key']

      ::tripleo::tls_proxy { 'nova-metadata-api':
        servername => $metadata_tls_proxy_fqdn,
        ip         => $metadata_tls_proxy_bind_ip,
        port       => $metadata_tls_proxy_port,
        tls_cert   => $metadata_tls_certfile,
        tls_key    => $metadata_tls_keyfile,
      }
      Tripleo::Tls_proxy['nova-metadata-api'] ~> Anchor<| title == 'nova::service::begin' |>
    }

    class { '::nova::api':
      sync_db     => $sync_db,
      sync_db_api => $sync_db,
    }
    include ::nova::cors
    include ::nova::network::neutron
  }
  # Temporarily disable Nova API deployed in WSGI
  # https://bugs.launchpad.net/nova/+bug/1661360
  if $nova_api_wsgi_enabled {
    if $enable_internal_tls {
      if !$nova_api_network {
        fail('nova_api_network is not set in the hieradata.')
      }
      $tls_certfile = $certificates_specs["httpd-${nova_api_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${nova_api_network}"]['service_key']
    } else {
      $tls_certfile = undef
      $tls_keyfile = undef
    }
    if $step >= 4 or ($step >= 3 and $sync_db) {
      include ::tripleo::profile::base::apache
      class { '::nova::wsgi::apache_api':
        ssl_cert => $tls_certfile,
        ssl_key  => $tls_keyfile,
      }
    }
  }

  if $step >= 5 {
    if hiera('nova_enable_db_archive', true) {
      include ::nova::cron::archive_deleted_rows
      if hiera('nova_enable_db_purge', true) {
        include ::nova::cron::purge_shadow_tables
      }
    }

    # At step 5, we consider all nova-compute services started and registred to nova-conductor
    # So we want to update Nova Cells database to be aware of these hosts by executing the
    # nova-cell_v2-discover_hosts command again.
    # Doing it on a single nova-api node to avoid race condition.
    if $sync_db {
      Exec<| title == 'nova-cell_v2-discover_hosts' |> { refreshonly => false }
    }
  }
}

