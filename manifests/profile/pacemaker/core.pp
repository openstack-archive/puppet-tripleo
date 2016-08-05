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
# == Class: tripleo::profile::pacemaker::core
#
# Core Pacemaker HA profile for tripleo
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
class tripleo::profile::pacemaker::core (
  $bootstrap_node = hiera('bootstrap_nodeid'),
  $step           = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 2 and $pacemaker_master {
    pacemaker::resource::ocf { 'openstack-core':
      ocf_agent_name => 'heartbeat:Dummy',
      clone_params   => 'interleave=true',
    }
  }

  if $step >= 5 and $pacemaker_master {
    pacemaker::constraint::base { 'galera-then-openstack-core-constraint':
      constraint_type => 'order',
      first_resource  => 'galera-master',
      second_resource => 'openstack-core-clone',
      first_action    => 'promote',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Ocf['galera'],
                          Pacemaker::Resource::Ocf['openstack-core']],
    }
  }
}
