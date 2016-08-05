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
# == Class: tripleo::profile::base::database::mongodb
#
# Mongodb profile for tripleo
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
class tripleo::profile::base::database::mongodb (
  $mongodb_replset,
  $bootstrap_node = downcase(hiera('bootstrap_nodeid')),
  $step           = hiera('step'),
) {
  if $step >= 2 {

    include ::mongodb::globals
    include ::mongodb::client
    include ::mongodb::server

    include ::tripleo::profile::base::database::mongodbcommon

    if $bootstrap_node == $::hostname {
      mongodb_replset { $mongodb_replset :
        members => $tripleo::profile::base::database::mongodbcommon::mongo_node_ips_with_port_nobr,
      }
    }

  }
}
