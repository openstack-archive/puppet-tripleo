# Copyright 2014 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron::server
#
# Neutron server profile for tripleo
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
# [*dvr_enabled*]
#   (Optional) Is dvr enabled, used when no override is passed to
#   l3_ha_override to calculate enabling l3 HA.
#   Defaults to  hiera('neutron::server::router_distributed') or false
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*l3_ha_override*]
#   (Optional) Override the calculated value for neutron::server::l3_ha
#   by default this is calculated to enable when DVR is not enabled
#   and the number of nodes running neutron api is more than one.
#   Defaults to '' which aligns with the t-h-t default, and means use
#   the calculated value.  Other possible values are 'true' or 'false'
#
# [*l3_nodes*]
#   (Optional) List of nodes running the l3 agent, used when no override
#   is passed to l3_ha_override to calculate enabling l3 HA.
#   Defaults to hiera('neutron_l3_short_node_names') or []
#   (we need to default neutron_l3_short_node_names to an empty list
#   because some neutron backends disable the l3 agent)
#
# [*neutron_network*]
#   (Optional) The network name where the neutron endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('neutron_api_network', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 9696
#
class tripleo::profile::base::neutron::server (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $dvr_enabled                   = hiera('neutron::server::router_distributed', false),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $l3_ha_override                = '',
  $l3_nodes                      = hiera('neutron_l3_short_node_names', []),
  $neutron_network               = hiera('neutron_api_network', undef),
  $step                          = Integer(hiera('step')),
  $tls_proxy_bind_ip             = undef,
  $tls_proxy_fqdn                = undef,
  $tls_proxy_port                = 9696,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::neutron

  # Calculate neutron::server::l3_ha based on the number of API nodes
  # combined with if DVR is enabled.
  if $l3_ha_override != '' {
    $l3_ha = str2bool($l3_ha_override)
  } elsif ! str2bool($dvr_enabled) {
    $l3_ha = size($l3_nodes) > 1
  } else {
    $l3_ha = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$neutron_network {
        fail('neutron_api_network is not set in the hieradata.')
      }
      $tls_certfile = $certificates_specs["httpd-${neutron_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${neutron_network}"]['service_key']

      ::tripleo::tls_proxy { 'neutron-api':
        servername => $tls_proxy_fqdn,
        ip         => $tls_proxy_bind_ip,
        port       => $tls_proxy_port,
        tls_cert   => $tls_certfile,
        tls_key    => $tls_keyfile,
      }
      Tripleo::Tls_proxy['neutron-api'] ~> Anchor<| title == 'neutron::service::begin' |>
    }
  }
  # We start neutron-server on the bootstrap node first, because
  # it will try to populate tables and we need to make sure this happens
  # before it starts on other nodes
  if $step >= 4 and $sync_db or $step >= 5 and !$sync_db {

    include ::neutron::server::notifications
    # We need to override the hiera value neutron::server::sync_db which is set
    # to true
    class { '::neutron::server':
      sync_db => $sync_db,
      l3_ha   => $l3_ha,
    }
    include ::neutron::quota
  }
}
