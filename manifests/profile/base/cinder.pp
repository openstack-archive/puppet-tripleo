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
# == Class: tripleo::profile::base::cinder
#
# Cinder common profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*cinder_enable_db_purge*]
#   (Optional) Wheter to enable db purging
#   Defaults to true
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')

class tripleo::profile::base::cinder (
  $bootstrap_node         = hiera('bootstrap_nodeid', undef),
  $cinder_enable_db_purge = true,
  $step                   = hiera('step'),
  $rabbit_hosts           = hiera('rabbitmq_node_ips', undef),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    class { '::cinder' :
      rabbit_hosts => $rabbit_hosts,
    }
    include ::cinder::config
  }

  if $step >= 5 {
    if $cinder_enable_db_purge {
      include ::cinder::cron::db_purge
    }
  }

}
