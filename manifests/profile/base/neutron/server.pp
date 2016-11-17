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
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
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
# [*dvr_enabled*]
#   (Optional) Is dvr enabled, used when no override is passed to
#   l3_ha_override to calculate enabling l3 HA.
#   Defaults to  hiera('neutron::server::router_distributed') or false
class tripleo::profile::base::neutron::server (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step           = hiera('step'),
  $l3_ha_override = '',
  $l3_nodes       = hiera('neutron_l3_short_node_names', []),
  $dvr_enabled    = hiera('neutron::server::router_distributed', false)
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

  # We start neutron-server on the bootstrap node first, because
  # it will try to populate tables and we need to make sure this happens
  # before it starts on other nodes
  if $step >= 4 and $sync_db {
    include ::neutron::server::notifications
    # We need to override the hiera value neutron::server::sync_db which is set
    # to true
    class { '::neutron::server':
      sync_db => $sync_db,
      l3_ha   => $l3_ha,
    }
  }
  if $step >= 5 and !$sync_db {
    include ::neutron::server::notifications
    class { '::neutron::server':
      sync_db => $sync_db,
      l3_ha   => $l3_ha,
    }
  }
}
