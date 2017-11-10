# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::designate::central
#
# Designate Central profile for tripleo
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
class tripleo::profile::base::designate::central (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  # TODO(bnemec): Make this configurable.
  file { 'designate pools':
    path    => '/etc/designate/pools.yaml',
    content => template('tripleo/designate/pools.yaml.erb'),
  }
  include ::tripleo::profile::base::designate
  if ($step >= 4 or ($step >= 3 and $sync_db)) {
    include ::designate::central
    class { '::designate::db':
      sync_db => $sync_db,
    }
  }
  if $step == 5 {
    exec { 'pool update':
      command => '/bin/designate-manage pool update',
      user    => 'designate',
    }
  }
}
