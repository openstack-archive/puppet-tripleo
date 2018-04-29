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
#   Defaults to hiera('tripleo::profile::base::qdr::qdr_listener_port', 5672)
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
  $qdr_listener_port = hiera('tripleo::profile::base::qdr::qdr_listener_port', 5672),
  $oslomsg_rpc_hosts = hiera('oslo_messaging_rpc_node_names', undef),
  $step              = Integer(hiera('step')),
) {
  $qdr_node_names = $oslomsg_rpc_hosts
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
          $memo + [{'host' => $node,
                    'role' => 'inter-router',
                    'port' => '31460'}]
        }
      }
    } - true

    $router_mode = size($qdr_node_names) ? {
      1       => 'standalone',
      default => 'interior',
    }

    $extra_listeners = size($qdr_node_names) ? {
      1       => [],
      default => [{'host' => '0.0.0.0',
                  'port' => '31460',
                  'role' => 'inter-router'}],
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

    class { '::qdr':
      listener_addr   => '0.0.0.0',
      listener_port   => "${qdr_listener_port}",
      router_mode     => $router_mode,
      connectors      => $connectors,
      extra_listeners => $extra_listeners,
      extra_addresses => $extra_addresses,
    }

    qdr_user { $qdr_username:
      ensure   => present,
      password => $qdr_password,
    }
  }
}
