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
#   Defaults to hiera('designate_central_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pools_file_content*]
#   (Optional) The content of /etc/designate/pools.yaml
#   Defaults to the content of templates/designate/pools.yaml.erb
#
class tripleo::profile::base::designate::central (
  $bootstrap_node = hiera('designate_central_short_bootstrap_node_name', undef),
  $step = Integer(hiera('step')),
  $pools_file_content = undef,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $pools_file_content {
    $pools_file_content_real = $pools_file_content
  } else {
    $pools_file_content_real = template('tripleo/designate/pools.yaml.erb')
  }
  file { 'designate pools':
    path    => '/etc/designate/pools.yaml',
    content => $pools_file_content_real,
  }
  include ::tripleo::profile::base::designate
  if ($step >= 4 or ($step >= 3 and $sync_db)) {
    class { '::designate::db':
      sync_db => $sync_db,
    }
    include ::designate::central
    include ::designate::quota
  }
  if ($step == 5 and $sync_db) {
    exec { 'pool update':
      command => '/bin/designate-manage pool update',
      user    => 'designate',
    }
  }
}
