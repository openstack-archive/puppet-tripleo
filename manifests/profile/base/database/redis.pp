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
# == Class: tripleo::profile::base::database::redis
#
# Redis profile for tripleo
#
# === Parameters
#
# [*bootstrap_nodeid*]
#   (Optional) Hostname of Redis master
#   Defaults to hiera('bootstrap_nodeid')
#
# [*redis_node_ips*]
#   (Optional) List of Redis node ips
#   Defaults to hiera('redis_node_ips')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::database::redis (
  $bootstrap_nodeid = hiera('bootstrap_nodeid'),
  $redis_node_ips   = hiera('redis_node_ips'),
  $step             = hiera('step'),
) {
  if $step >= 2 {
    if $bootstrap_nodeid == $::hostname {
      $slaveof = undef
    } else {
      $slaveof = "${bootstrap_nodeid} 6379"
    }
    class { '::redis' :
      slaveof => $slaveof,
    }

    if count($redis_node_ips) > 1 {
      Class['::tripleo::redis_notification'] -> Service['redis-sentinel']
      include ::redis::sentinel
      include ::tripleo::redis_notification
    }
  }
}
