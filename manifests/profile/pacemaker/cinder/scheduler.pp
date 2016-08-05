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
# == Class: tripleo::profile::pacemaker::cinder::scheduler
#
# Cinder Scheduler Pacemaker HA profile for tripleo
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
class tripleo::profile::pacemaker::cinder::scheduler (
  $bootstrap_node = hiera('bootstrap_nodeid'),
  $step           = hiera('step'),
) {
  Service <| tag == 'cinder-service' |> {
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

  include ::tripleo::profile::base::cinder::scheduler

  if $step >= 5 and $pacemaker_master {
    pacemaker::resource::service { $::cinder::params::scheduler_service :
      clone_params => 'interleave=true',
    }
    pacemaker::constraint::base { 'cinder-api-then-cinder-scheduler-constraint':
      constraint_type => 'order',
      first_resource  => "${::cinder::params::api_service}-clone",
      second_resource => "${::cinder::params::scheduler_service}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::cinder::params::api_service],
                          Pacemaker::Resource::Service[$::cinder::params::scheduler_service]],
    }
    pacemaker::constraint::colocation { 'cinder-scheduler-with-cinder-api-colocation':
      source  => "${::cinder::params::scheduler_service}-clone",
      target  => "${::cinder::params::api_service}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::cinder::params::api_service],
                  Pacemaker::Resource::Service[$::cinder::params::scheduler_service]],
    }
    pacemaker::constraint::base { 'cinder-scheduler-then-cinder-volume-constraint':
      constraint_type => 'order',
      first_resource  => "${::cinder::params::scheduler_service}-clone",
      second_resource => $::cinder::params::volume_service,
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::cinder::params::scheduler_service],
                          Pacemaker::Resource::Service[$::cinder::params::volume_service]],
    }
    pacemaker::constraint::colocation { 'cinder-volume-with-cinder-scheduler-colocation':
      source  => $::cinder::params::volume_service,
      target  => "${::cinder::params::scheduler_service}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::cinder::params::scheduler_service],
                  Pacemaker::Resource::Service[$::cinder::params::volume_service]],
    }
  }

}
