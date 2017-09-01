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
# == Class: tripleo::profile::pacemaker::manila
#
# Manila Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('manila_share_short_bootstrap_node_name')
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
class tripleo::profile::pacemaker::manila (
  $bootstrap_node          = hiera('manila_share_short_bootstrap_node_name'),
  $step                    = Integer(hiera('step')),
  $pcs_tries               = hiera('pcs_tries', 20),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  # make it so puppet can't restart the manila-share service, since that is
  # the only pacemaker managed one
  Service <| tag == 'manila-share' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  include ::tripleo::profile::base::manila::share

  if $step >= 2 {
    pacemaker::property { 'manila-share-role-node-property':
      property => 'manila-share-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }

  if $step >= 4 {
    if $pacemaker_master and hiera('stack_action') == 'UPDATE' {
      Manila_api_paste_ini<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::manila::params::share_service}"]
      Manila_config<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::manila::params::share_service}"]
      tripleo::pacemaker::resource_restart_flag { "${::manila::params::share_service}": }
    }
  }

  if $step >= 5 and $pacemaker_master {

    # only manila-share is pacemaker managed, and in a/p
    pacemaker::resource::service { $::manila::params::share_service :
      op_params     => 'start timeout=200s stop timeout=200s',
      tries         => $pcs_tries,
      location_rule => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['manila-share-role eq true'],
      },
    }

  }
}
