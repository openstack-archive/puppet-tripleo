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
# [*backend_generic_enabled*]
#   (Optional) Whether or not the generic backend is enabled
#   Defaults to hiera('manila_backend_generic_enabled', false)
#
# [*backend_netapp_enabled*]
#   (Optional) Whether or not the netapp backend is enabled
#   Defaults to hiera('manila_backend_netapp_enabled', false)
#
# [*backend_vmax_enabled*]
#   (Optional) Whether or not the vmax backend is enabled
#   Defaults to hiera('manila_backend_vmax_enabled', false)
#
# [*backend_isilon_enabled*]
#   (Optional) Whether or not the isilon backend is enabled
#   Defaults to hiera('manila_backend_isilon_enabled', false)
#
# [*backend_unity_enabled*]
#   (Optional) Whether or not the unity backend is enabled
#   Defaults to hiera('manila_backend_unity_enabled', false)
#
# [*backend_vnx_enabled*]
#   (Optional) Whether or not the vnx backend is enabled
#   Defaults to hiera('manila_backend_vnx_enabled', false)
#
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to hiera('manila_backend_cephfs_enabled', false)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('manila_api_short_bootstrap_node_name')
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
# [*manila_api_network*]
#   (Optional) The network name where the manila API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('manila_api_network', undef)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')

class tripleo::profile::base::manila::api (
  $backend_generic_enabled = hiera('manila_backend_generic_enabled', false),
  $backend_netapp_enabled  = hiera('manila_backend_netapp_enabled', false),
  $backend_vmax_enabled    = hiera('manila_backend_vmax_enabled', false),
  $backend_isilon_enabled  = hiera('manila_backend_isilon_enabled', false),
  $backend_unity_enabled   = hiera('manila_backend_unity_enabled', false),
  $backend_vnx_enabled     = hiera('manila_backend_vnx_enabled', false),
  $backend_cephfs_enabled  = hiera('manila_backend_cephfs_enabled', false),
  $bootstrap_node          = hiera('manila_api_short_bootstrap_node_name', undef),
  $certificates_specs      = hiera('apache_certificates_specs', {}),
  $manila_api_network      = hiera('manila_api_network', undef),
  $enable_internal_tls     = hiera('enable_internal_tls', false),
  $step                    = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::manila

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
    include ::tripleo::profile::base::apache
    if $backend_generic_enabled or $backend_netapp_enabled or $backend_vmax_enabled or
      $backend_isilon_enabled or $backend_unity_enabled or $backend_vnx_enabled {
        $nfs_protocol = 'NFS'
        $cifs_protocol = 'CIFS'
    } else {
      $nfs_protocol = undef
      $cifs_protocol = undef
    }
    if $backend_cephfs_enabled {
      $cephfs_protocol = hiera('manila::backend::cephfs::cephfs_protocol_helper_type', 'CEPHFS')
    } else {
      $cephfs_protocol = undef
    }
    class { '::manila::api' :
      enabled_share_protocols => join(delete_undef_values([$nfs_protocol,$cifs_protocol,$cephfs_protocol]), ',')
    }
    class { '::manila::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
  }
}
