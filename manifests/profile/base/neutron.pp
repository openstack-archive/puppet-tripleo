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
# == Class: tripleo::profile::base::neutron
#
# Neutron server profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('neutron::rabbit_port', 5672
#
# [*dhcp_agents_per_network*]
#   (Optional) TripleO configured number of DHCP agents
#   to use per network. If left to the default value, neutron will be
#   configured with the number of DHCP agents being deployed.
#   Defaults to undef
#
# [*dhcp_nodes*]
#   (Optional) List of nodes running the DHCP agent. Used to
#   set neutron's dhcp_agents_per_network value to the number
#   of available agents.
#   Defaults to hiera('neutron_dhcp_short_node_names') or []
#

class tripleo::profile::base::neutron (
  $step         = hiera('step'),
  $rabbit_hosts = hiera('rabbitmq_node_names', undef),
  $rabbit_port  = hiera('neutron::rabbit_port', 5672),
  $dhcp_agents_per_network = undef,
  $dhcp_nodes              = hiera('neutron_dhcp_short_node_names', []),
) {
  if $step >= 3 {
    $dhcp_agent_count = size($dhcp_nodes)
    if $dhcp_agents_per_network {
      $dhcp_agents_per_net = $dhcp_agents_per_network
      if ($dhcp_agents_per_net > $dhcp_agent_count) {
        warning("dhcp_agents_per_network (${dhcp_agents_per_net}) is greater\
 than the number of deployed dhcp agents (${dhcp_agent_count})")
      }
    }
    elsif $dhcp_agent_count > 0 {
      $dhcp_agents_per_net = $dhcp_agent_count
    }

    $rabbit_endpoints = suffix(any2array($rabbit_hosts), ":${rabbit_port}")
    class { '::neutron' :
      rabbit_hosts            => $rabbit_endpoints,
      dhcp_agents_per_network => $dhcp_agents_per_net,
    }
    include ::neutron::config
  }
}
