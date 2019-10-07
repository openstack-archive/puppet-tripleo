# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::metrics::qdr
#
# Qpid dispatch router profile for tripleo
#
# === Parameters
#
# [*username*]
#   Username for the qdrouter daemon
#   Defaults to undef
#
# [*password*]
#   Password for the qdrouter daemon
#   Defaults to undef
#
# [*external_listener_addr*]
#   (optional) Bind address for external connections (CloudForms for example)
#   Defaults to 'localhost'
#
# [*listener_addr*]
#   (optional) Service host name
#   Defaults to 'localhost'
#
# [*listener_port*]
#   Service name or port number on which the qdrouterd will accept connections.
#   This argument must be string, even if the numeric form is used.
#   Defaults to '5666'
#
# [*listener_require_encrypt*]
#   (optional) Require the connection to the peer to be encrypted
#   Defaults to  'no'
#
# [*listener_require_ssl*]
#   (optional) Require the use of SSL on the connection
#   Defaults to false
#
# [*listener_sasl_mech*]
#   (optional) List of accepted SASL auth mechanisms
#   Defaults to 'ANONYMOUS'
#
# [*listener_ssl_cert_db*]
#   (optional) Path to certificate db
#   Defaults to undef
#
# [*listener_ssl_cert_file*]
#   (optional) Path to certificat file
#   Defaults to undef
#
# [*listener_ssl_key_file*]
#   (optional) Path to private key file
#   Defaults to undef
#
# [*listener_ssl_pw_file*]
#   (optional) Path to password file for certificate key
#   Defaults to undef
#
# [*listener_ssl_password*]
#   (optional) Password to be supplied
#   Defaults to undef
#
# [*listener_trusted_certs*]
#   (optional) Path to file containing trusted certificates
#   Defaults to 'UNSET'
#
# [*interior_mesh_nodes*]
#   (optional) Comma separated list of controller nodes' fqdns
#   Defaults to hiera('controller_node_names', '')
#
# [*connectors*]
#   (optional) List of hashes containing configuration for outgoing connections
#   from the router. Each hash should contain 'host', 'role' and 'port' key.
#   Defaults to []
#
# [*ssl_profiles*]
#   (optional) List of hashes containing configuration for ssl profiles
#   Defaults to []
#
# [*ssl_internal_profile_name*]
#   (optional) SSL Profile name for internal connections.
#   Defaults to undef.
#
# [*addresses*]
#   (optional) List of hashes containing configuration for addresses.
#   Defaults to []
#
# [*autolink_addresses*]
#   (optional) List of hashes containing configuration for autoLinks
#   Defaults to []
#
# [*router_mode*]
#   (optional) Mode in which the qdrouterd service should run.
#   Defaults to 'edge'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::metrics::qdr (
  $username                  = undef,
  $password                  = undef,
  $external_listener_addr    = 'localhost',
  $listener_addr             = 'localhost',
  $listener_port             = '5666',
  $listener_require_ssl      = false,
  $listener_require_encrypt  = false,
  $listener_sasl_mech        = undef,
  $listener_ssl_cert_db      = undef,
  $listener_ssl_cert_file    = undef,
  $listener_ssl_key_file     = undef,
  $listener_ssl_pw_file      = undef,
  $listener_ssl_password     = undef,
  $listener_trusted_certs    = undef,
  $interior_mesh_nodes       = hiera('controller_node_names', ''),
  $connectors                = [],
  $ssl_profiles              = [],
  $ssl_internal_profile_name = undef,
  $addresses                 = [],
  $autolink_addresses        = [],
  $router_mode               = 'edge',
  $step                      = Integer(hiera('step')),
) {
  if $step >= 1 {
    $interior_nodes = any2array(split($interior_mesh_nodes, ','))

    if $router_mode == 'edge' {
      if length($interior_nodes) > 0 {
        # ignore explicitly set connectors and connect just to one of the interior nodes (choose randomly)
        $all_connectors = [
          {'host' => $interior_nodes[fqdn_rand(length($interior_nodes))],
          'port' => '5668',
          'role' => 'edge',
          'verifyHostname' => false,
          'saslMechanisms' => 'ANONYMOUS',
          'sslProfile' => $ssl_internal_profile_name}
        ]
      } else {
        # in case we don't have interior_nodes, eg. we run in all-edge mode
        $all_connectors = $connectors
      }
      # and don't provide any internal listener
      $internal_listeners = []
    } else {
      # provide listener for edge node and listener for other interior nodes (if required)
      $edge_listener = {'host' => $listener_addr,
                        'port' => '5668',
                        'role' => 'edge',
                        'authenticatePeer' => 'no',
                        'saslMechanisms' => 'ANONYMOUS',
                        'sslProfile' => $ssl_internal_profile_name}
      if length($interior_nodes) > 1 {
        $internal_listeners = [
          $edge_listener,
          {'host' => $listener_addr,
          'port' => '5667',
          'role' => 'inter-router',
          'authenticatePeer' => 'no',
          'saslMechanisms' => 'ANONYMOUS',
          'sslProfile' => $ssl_internal_profile_name}
        ]
        # build mesh with other interior nodes
        $internal_connectors = $interior_nodes.reduce([]) |$memo, $node| {
          if $::hostname in $node {
            $memo << true
          } elsif true in $memo {
            $memo
          } else {
            $memo << {'host' => $node,
                      'port' => '5667',
                      'role' => 'inter-router',
                      'verifyHostname' => false,
                      'sslProfile' => $ssl_internal_profile_name}
          }
        } - true
      } else {
        # single controller does not need to listen on / connect to other inter-router connections
        $internal_listeners = [$edge_listener]
        $internal_connectors = []
      }
      $all_connectors = $connectors + $internal_connectors
    }

    $listen_on = $router_mode ? {
      'edge'     => $listener_addr,
      'interior' => $external_listener_addr
    }

    class { '::qdr':
      listener_addr            => $listen_on,
      listener_port            => $listener_port,
      listener_require_encrypt => $listener_require_encrypt,
      listener_require_ssl     => $listener_require_ssl,
      listener_ssl_cert_db     => $listener_ssl_cert_db,
      listener_ssl_cert_file   => $listener_ssl_cert_file,
      listener_ssl_key_file    => $listener_ssl_key_file,
      listener_ssl_pw_file     => $listener_ssl_pw_file,
      listener_ssl_password    => $listener_ssl_password,
      listener_trusted_certs   => $listener_trusted_certs,
      router_mode              => $router_mode,
      connectors               => $all_connectors,
      ssl_profiles             => $ssl_profiles,
      extra_addresses          => $addresses,
      autolink_addresses       => $autolink_addresses,
      extra_listeners          => $internal_listeners,
    }

    qdr_user { $username:
      ensure   => present,
      password => $password,
    }
  }
}
