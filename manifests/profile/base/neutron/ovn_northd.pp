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
# == Class: tripleo::profile::base::neutron::plugins::ml2::ovn
#
# OVN Neutron northd profile for tripleo
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('ovn_dbs_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::ovn_northd (
  $bootstrap_node = hiera('ovn_dbs_short_bootstrap_node_name', undef),
  $step           = Integer(hiera('step')),
) {
  if $step >= 4 {
    # Note this only runs on the first node in the cluster when
    # deployed on a role where multiple nodes exist.
    if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
      include ovn::northd
    }
  }
}

