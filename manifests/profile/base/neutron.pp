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
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_scheme', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_user_name', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_rpc_use_ssl', '0')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_scheme', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('oslo_messaging_notify_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_user_name', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_notify_use_ssl', '0')
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
# [*designate_api_enabled*]
#   (Optional) Indicate whether Designate is available in the deployment.
#   Defaults to hiera('designate_api_enabled') or false
#

class tripleo::profile::base::neutron (
  $step                    = Integer(hiera('step')),
  $oslomsg_rpc_proto       = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(hiera('oslo_messaging_rpc_node_names', undef)),
  $oslomsg_rpc_password    = hiera('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = hiera('oslo_messaging_rpc_port', '5672'),
  $oslomsg_rpc_username    = hiera('oslo_messaging_rpc_user_name', 'guest'),
  $oslomsg_rpc_use_ssl     = hiera('oslo_messaging_rpc_use_ssl', '0'),
  $oslomsg_notify_proto    = hiera('oslo_messaging_notify_scheme', 'rabbit'),
  $oslomsg_notify_hosts    = any2array(hiera('oslo_messaging_notify_node_names', undef)),
  $oslomsg_notify_password = hiera('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = hiera('oslo_messaging_notify_port', '5672'),
  $oslomsg_notify_username = hiera('oslo_messaging_notify_user_name', 'guest'),
  $oslomsg_notify_use_ssl  = hiera('oslo_messaging_notify_use_ssl', '0'),
  $dhcp_agents_per_network = undef,
  $dhcp_nodes              = hiera('neutron_dhcp_short_node_names', []),
  $designate_api_enabled   = hiera('designate_api_enabled', false),
) {
  if $step >= 3 {
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
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
    class { '::neutron' :
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_notify_use_ssl_real,
      }),
      dhcp_agents_per_network    => $dhcp_agents_per_net,
    }
    include ::neutron::config

    if $designate_api_enabled {
      include ::neutron::designate
    }
  }
}
