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
# == Class: tripleo::profile::pacemaker::nova::conductor
#
# Nova Conductor with Pacemaker profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master
#   Defaults to hiera('bootstrap_nodeid')
#
class tripleo::profile::pacemaker::nova::conductor (
  $step             = hiera('step'),
  $pacemaker_master = hiera('bootstrap_nodeid'),
) {

  include ::nova::params
  include ::tripleo::profile::pacemaker::nova
  include ::tripleo::profile::base::nova::conductor

  Service<| title == 'nova-conductor' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {
    pacemaker::resource::service { $::nova::params::conductor_service_name:
      clone_params => 'interleave=true',
    }
    # If Service['nova-compute'] is in catalog, make sure we start it after
    # nova-conductor pcmk resource.
    # Also make sure to restart nova-compute if nova-conductor pcmk resource changed
    # the state, since nova-compute is deployed at a previous step.
    Pacemaker::Resource::Service[$::nova::params::conductor_service_name] ~> Service<| title == 'nova-compute' |>
  }

}
