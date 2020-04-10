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
# == Class: tripleo::profile::base::octavia::api
#
# Octavia API server profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('octavia_api_short_bootstrap_node_name')
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
# [*octavia_network*]
#   (Optional) The network name where the barbican endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('octavia_api_network', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# DEPRECATED PARAMETERS
#
# [*ovn_db_host*]
#   (Optional) The IP-Address where OVN DBs are listening.
#   Defaults to undef
#
# [*ovn_nb_port*]
#   (Optional) Port number on which northbound database is listening
#   Defaults to undef
#
# [*neutron_driver*]
#   (Optional) The neutron driver for ml2 currently default tripleo value is ovn.
#   Defaults to hiera('neutron::plugins::ml2::mechanism_drivers'). Not used
#   any more.
#
class tripleo::profile::base::octavia::api (
  $bootstrap_node      = hiera('octavia_api_short_bootstrap_node_name', undef),
  $certificates_specs  = hiera('apache_certificates_specs', {}),
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $octavia_network     = hiera('octavia_api_network', undef),
  $step                = Integer(hiera('step')),
  $neutron_driver      = hiera('neutron::plugins::ml2::mechanism_drivers', []),
  $ovn_db_host         = undef,
  $ovn_nb_port         = undef,
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::octavia
  include tripleo::profile::base::octavia::authtoken

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$octavia_network {
        fail('octavia_api_network is not set in the hieradata.')
      }
      $tls_certfile = $certificates_specs["httpd-${octavia_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${octavia_network}"]['service_key']
    } else {
      $tls_certfile = undef
      $tls_keyfile = undef
    }
  }
  # We start the Octavia API server on the bootstrap node first, because
  # it will try to populate tables and we need to make sure this happens
  # before it starts on other nodes
  if ($step >= 4 and $sync_db) or ($step >= 5 and !$sync_db) {
    include octavia::controller
    if $ovn_db_host or $ovn_nb_port {
      warning('The ovn_db_host and ovn_nb_port parameters are deprecated from tripleo::profile::base::octavia::api. \
Use tripleo::profile::base::octavia::provider::ovn.')
    }
    class { 'octavia::api':
      sync_db           => $sync_db,
    }
    include tripleo::profile::base::apache
    class { 'octavia::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile
    }
  }
}
