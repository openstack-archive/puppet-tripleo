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
# == Class: tripleo::profile::pacemaker::database::mongodb
#
# Mongodb Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*mongodb_replset*]
#   Mongodb replicaset name
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
class tripleo::profile::pacemaker::database::mongodb (
  $mongodb_replset,
  $bootstrap_node = hiera('bootstrap_nodeid'),
  $step           = hiera('step'),
) {
  if $step >= 1 {
    include ::mongodb::globals
    include ::mongodb::client
    include ::mongodb::server
  }

  if $step >= 2 {

    include ::tripleo::profile::base::database::mongodbcommon

    if $::hostname == downcase($bootstrap_node) {
      $pacemaker_master = true
    } else {
      $pacemaker_master = false
    }

    if $pacemaker_master {
      pacemaker::resource::service { $::mongodb::params::service_name :
        op_params    => 'start timeout=370s stop timeout=200s',
        clone_params => true,
        require      => Class['::mongodb::server'],
      }
      # NOTE (spredzy) : The replset can only be run
      # once all the nodes have joined the cluster.
      tripleo::profile::pacemaker::database::mongodbvalidator {
        $tripleo::profile::base::database::mongodbcommon::mongodb_node_ips :
        port    => $tripleo::profile::base::database::mongodbcommon::port,
        require => Pacemaker::Resource::Service[$::mongodb::params::service_name],
        before  => Mongodb_replset[$mongodb_replset],
      }
      mongodb_replset { $mongodb_replset :
        members => $tripleo::profile::base::database::mongodbcommon::mongo_node_ips_with_port_nobr,
      }
    }
  }
}
