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
# == Class: tripleo::profile::pacemaker::sahara
#
# Sahara Pacemaker HA profile for tripleo
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
class tripleo::profile::pacemaker::sahara (
  $bootstrap_node       = hiera('bootstrap_nodeid'),
  $step                 = hiera('step'),
) {

  Service <| tag == 'sahara-service' |> {
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

  include ::tripleo::profile::base::sahara-api
  class { '::tripleo::profile::base::sahara-engine':
    sync_db => $pacemaker_master,
  }

  if $step >= 5 and $pacemaker_master {
    # Sahara
    pacemaker::resource::service { $::sahara::params::api_service_name :
      clone_params => 'interleave=true',
      require      => Pacemaker::Resource::Ocf['openstack-core'],
    }
    pacemaker::resource::service { $::sahara::params::engine_service_name :
      clone_params => 'interleave=true',
    }
    pacemaker::constraint::base { 'keystone-then-sahara-api-constraint':
      constraint_type => 'order',
      first_resource  => 'openstack-core-clone',
      second_resource => "${::sahara::params::api_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::sahara::params::api_service_name],
                          Pacemaker::Resource::Ocf['openstack-core']],
    }
    pacemaker::constraint::base { 'sahara-api-then-sahara-engine-constraint':
      constraint_type => 'order',
      first_resource  => "${::sahara::params::api_service_name}-clone",
      second_resource => "${::sahara::params::engine_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::sahara::params::api_service_name],
                          Pacemaker::Resource::Service[$::sahara::params::engine_service_name]],
    }
  }
}
