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
# == Class: tripleo::profile::pacemaker::cinder::volume
#
# Cinder Volume Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('cinder_volume_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::cinder::volume (
  $bootstrap_node = hiera('cinder_volume_short_bootstrap_node_name'),
  $step           = Integer(hiera('step')),
  $pcs_tries      = hiera('pcs_tries', 20),
) {
  Service <| tag == 'cinder::volume' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::cinder::volume

  if $step >= 2 {
    pacemaker::property { 'cinder-volume-role-node-property':
      property => 'cinder-volume-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }

  if $step >= 3 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    Cinder_api_paste_ini<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::cinder::params::volume_service}"]
    Cinder_config<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::cinder::params::volume_service}"]
    tripleo::pacemaker::resource_restart_flag { "${::cinder::params::volume_service}": }
  }

  if $step >= 5 and $pacemaker_master {
    pacemaker::resource::service { $::cinder::params::volume_service :
      op_params     => 'start timeout=200s stop timeout=200s',
      tries         => $pcs_tries,
      location_rule => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['cinder-volume-role eq true'],
      }
    }
  }

}
