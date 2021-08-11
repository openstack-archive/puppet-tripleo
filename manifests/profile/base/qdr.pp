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
# == Class: tripleo::profile::base::qdr
#
# Qpid dispatch router profile for tripleo
#
# === Parameters
#
# [*qdr_username*]
#   Username for the qdrouter daemon
#   Defaults to undef
#
# [*qdr_password*]
#   Password for the qdrouter daemon
#   Defaults to undef
#
# [*qdr_listener_port*]
#   Port for the listener (note that we do not use qdr::listener_port
#   directly because it requires a string and we have a number.
#   Defaults to 5672
#
# [*listener_require_ssl*]
#   (optional) Require the use of SSL on the connection
#   Defaults to false
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
# [*qdr_log_enable*]
#   Log level for the qdrouterd module
#   Defaults to 'info+'
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::qdr (
  $qdr_username      = undef,
  $qdr_password      = undef,
  $qdr_listener_port = 5672,
  $listener_require_ssl      = false,
  $listener_ssl_cert_db      = undef,
  $listener_ssl_cert_file    = undef,
  $listener_ssl_key_file     = undef,
  $qdr_log_enable    = 'info+',
  $oslomsg_rpc_hosts = hiera('oslo_messaging_rpc_node_names', undef),
  $step              = Integer(hiera('step')),
) {
  $qdr_node_names = $oslomsg_rpc_hosts

  if $listener_require_ssl {
      $ssl_opts = {'sslProfile' => "Router.${::fqdn}"}
  } else {
      $ssl_opts = {}
  }

  if $step >= 1 {
    # For multi-node deployments of the dispatch router, a mesh of
    # inter-router links is created. Bi-directional links must
    # not be configured.
    #
    # Example: For nodes A, B, C
    #    Node      Inter-Router Link
    #     A:             []
    #     B:             [A]
    #     C:             [A,B]
    #
    # NB: puppet 4.8 introduces break(), which would be favord to
    # the following
    $connectors = $qdr_node_names.reduce([]) |$memo, $node| {
      if $::hostname in $node {
        $memo + true
      } else {
        if true in $memo {
          $memo
        } else {
          $memo + [merge($ssl_opts,
                    { 'host' => $node,
                      'role' => 'inter-router',
                      'port' => '31460'})]
        }
      }
    } - true

    $router_mode = size($qdr_node_names) ? {
      1       => 'standalone',
      default => 'interior',
    }

    $extra_listeners = size($qdr_node_names) ? {
      1       => [],
      default => [merge($ssl_opts,
                  { 'host' => '0.0.0.0',
                    'port' => '31460',
                    'role' => 'inter-router'})],
    }

    $extra_addresses = [{'prefix'       => 'openstack.org/om/rpc/multicast',
                        'distribution' => 'multicast'},
                        {'prefix'       => 'openstack.org/om/rpc/unicast',
                        'distribution' => 'closest'},
                        {'prefix'       => 'openstack.org/om/rpc/anycast',
                        'distribution' => 'balanced'},
                        {'prefix'       => 'openstack.org/om/notify/multicast',
                        'distribution' => 'multicast'},
                        {'prefix'       => 'openstack.org/om/notify/unicast',
                        'distribution' => 'closest'},
                        {'prefix'       => 'openstack.org/om/notify/anycast',
                        'distribution' => 'balanced'}]

    class { 'qdr':
      listener_addr          => '0.0.0.0',
      listener_port          => "${qdr_listener_port}",
      listener_require_ssl   => $listener_require_ssl,
      listener_ssl_cert_db   => $listener_ssl_cert_db,
      listener_ssl_cert_file => $listener_ssl_cert_file,
      listener_ssl_key_file  => $listener_ssl_key_file,
      router_mode            => $router_mode,
      connectors             => $connectors,
      extra_listeners        => $extra_listeners,
      extra_addresses        => $extra_addresses,
      log_enable             => "${qdr_log_enable}",
    }

    qdr_user { $qdr_username:
      ensure   => present,
      password => $qdr_password,
    }
  }
}
