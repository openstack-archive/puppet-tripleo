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
#   Defaults to lookup('nova_api_short_bootstrap_node_name')
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
# [*nova_api_network*]
#   (Optional) The network name where the nova API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('nova_api_network', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*nova_enable_db_archive*]
#   (Optional) Wheter to enable db archiving
#   Defaults to lookup('nova_enable_db_archive', undef, undef, true)
#
# [*nova_enable_db_purge*]
#   (Optional) Wheter to enable db purging
#   Defaults to lookup('nova_enable_db_purge', undef, undef, true)
#
# [*configure_apache*]
#   (Optional) Whether apache is configured via puppet or not.
#   Defaults to lookup('configure_apache', undef, undef, true)

class tripleo::profile::base::nova::api (
  $bootstrap_node         = lookup('nova_api_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs     = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls    = lookup('enable_internal_tls', undef, undef, false),
  $nova_api_network       = lookup('nova_api_network', undef, undef, undef),
  $step                   = Integer(lookup('step')),
  $nova_enable_db_archive = lookup('nova_enable_db_archive', undef, undef, true),
  $nova_enable_db_purge   = lookup('nova_enable_db_purge', undef, undef, true),
  $configure_apache       = lookup('configure_apache', undef, undef, true),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::nova
  include tripleo::profile::base::nova::authtoken

  if $step >= 4 or ($step >= 3 and $sync_db) {
    class { 'nova::api':
      sync_db                    => $sync_db,
      sync_db_api                => $sync_db,
      nova_metadata_wsgi_enabled => true
    }
    include nova::cors
    include nova::quota
    include nova::keystone
    include nova::network::neutron
    include nova::pci
    include nova::vendordata
  }

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
    if $configure_apache {
      include tripleo::profile::base::apache
      class { 'nova::wsgi::apache_api':
        ssl_cert => $tls_certfile,
        ssl_key  => $tls_keyfile,
      }
    }
  }

  if $step >= 5 {
    if $nova_enable_db_archive {
      include nova::cron::archive_deleted_rows
      if $nova_enable_db_purge {
        include nova::cron::purge_shadow_tables
      }
    }
  }
}

