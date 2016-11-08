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
# == Class: tripleo::profile::base::aodh
#
# aodh profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('aodh::rabbit_port', 5672)

class tripleo::profile::base::aodh (
  $step           = hiera('step'),
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $rabbit_hosts   = hiera('rabbitmq_node_ips', undef),
  $rabbit_port    = hiera('aodh::rabbit_port', 5672),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    class { '::aodh' :
      rabbit_hosts => $rabbit_endpoints,
    }
    include ::aodh::auth
    include ::aodh::config
    include ::aodh::client
    include ::aodh::db::sync
  }

}
