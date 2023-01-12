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
# == Class: tripleo::profile::base::manila::api
#
# Manila API profile for tripleo
#
# === Parameters
#
# [*enabled_share_protocols*]
#   (Optional) Share protocols enabled on the manila API service.
#   Defaults to lookup('manila_enabled_share_protocols', undef, undef, undef)
#
# [*backend_generic_enabled*]
#   (Optional) Whether or not the generic backend is enabled
#   Defaults to lookup('manila_backend_generic_enabled', undef, undef, false)
#
# [*backend_netapp_enabled*]
#   (Optional) Whether or not the netapp backend is enabled
#   Defaults to lookup('manila_backend_netapp_enabled', undef, undef, false)
#
# [*backend_powermax_enabled*]
#   (Optional) Whether or not the powermax backend is enabled
#   Defaults to lookup('manila_backend_powermax_enabled', undef, undef, false)
#
# [*backend_isilon_enabled*]
#   (Optional) Whether or not the isilon backend is enabled
#   Defaults to lookup('manila_backend_isilon_enabled', undef, undef, false)
#
# [*backend_unity_enabled*]
#   (Optional) Whether or not the unity backend is enabled
#   Defaults to lookup('manila_backend_unity_enabled', undef, undef, false)
#
# [*backend_vnx_enabled*]
#   (Optional) Whether or not the vnx backend is enabled
#   Defaults to lookup('manila_backend_vnx_enabled', undef, undef, false)
#
# [*backend_flashblade_enabled*]
#   (Optional) Whether or not the flashblade backend is enabled
#   Defaults to lookup('manila_backend_flashblade_enabled', undef, undef, false)
#
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to lookup('manila_backend_cephfs_enabled', undef, undef, false)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('manila_api_short_bootstrap_node_name', undef, undef, undef)
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
# [*manila_api_network*]
#   (Optional) The network name where the manila API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('manila_api_network', undef, undef, undef)
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
# [*manila_enable_db_purge*]
#   (Optional) Whether to enable db purging
#   Defaults to true
#
# [*configure_apache*]
#   (Optional) Whether apache is configured via puppet or not.
#   Defaults to lookup('configure_apache', undef, undef, true)
#
class tripleo::profile::base::manila::api (
  $enabled_share_protocols    = lookup('manila_enabled_share_protocols', undef, undef, undef),
  $backend_generic_enabled    = lookup('manila_backend_generic_enabled', undef, undef, false),
  $backend_netapp_enabled     = lookup('manila_backend_netapp_enabled', undef, undef, false),
  $backend_powermax_enabled   = lookup('manila_backend_powermax_enabled', undef, undef, false),
  $backend_isilon_enabled     = lookup('manila_backend_isilon_enabled', undef, undef, false),
  $backend_unity_enabled      = lookup('manila_backend_unity_enabled', undef, undef, false),
  $backend_vnx_enabled        = lookup('manila_backend_vnx_enabled', undef, undef, false),
  $backend_flashblade_enabled = lookup('manila_backend_flashblade_enabled', undef, undef, false),
  $backend_cephfs_enabled     = lookup('manila_backend_cephfs_enabled', undef, undef, false),
  $bootstrap_node             = lookup('manila_api_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs         = lookup('apache_certificates_specs', undef, undef, {}),
  $manila_api_network         = lookup('manila_api_network', undef, undef, undef),
  $enable_internal_tls        = lookup('enable_internal_tls', undef, undef, false),
  $step                       = Integer(lookup('step')),
  $manila_enable_db_purge     = true,
  $configure_apache           = lookup('configure_apache', undef, undef, true),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::manila
  include tripleo::profile::base::manila::authtoken

  if $enable_internal_tls {
    if !$manila_api_network {
      fail('manila_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${manila_api_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${manila_api_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $configure_apache {
      include tripleo::profile::base::apache
    }

    unless empty($enabled_share_protocols) {
      $enabled_share_protocols_real = join(any2array($enabled_share_protocols), ',')
    } else {
      if $backend_generic_enabled or $backend_netapp_enabled
        or $backend_powermax_enabled or $backend_isilon_enabled
        or $backend_unity_enabled or $backend_vnx_enabled
        or $backend_flashblade_enabled{
          $nfs_protocol = 'NFS'
          $cifs_protocol = 'CIFS'
      } else {
          $nfs_protocol = undef
          $cifs_protocol = undef
      }
      if $backend_cephfs_enabled {
        $cephfs_protocol = lookup(
          'manila::backend::cephfs::cephfs_protocol_helper_type', undef, undef, 'CEPHFS')
      } else {
        $cephfs_protocol = undef
      }

      $enabled_share_protocols_real = join(delete_undef_values([$nfs_protocol,$cifs_protocol,$cephfs_protocol]), ',')

    }
    class { 'manila::api' :
      enabled_share_protocols => $enabled_share_protocols_real
    }
    include manila::healthcheck
    if $configure_apache {
      class { 'manila::wsgi::apache':
        ssl_cert => $tls_certfile,
        ssl_key  => $tls_keyfile,
      }
    }
  }

  if $step >= 5 {
    if $manila_enable_db_purge {
      include manila::cron::db_purge
    }
  }
}
