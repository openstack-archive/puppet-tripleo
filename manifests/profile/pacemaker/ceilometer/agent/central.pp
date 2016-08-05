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
# == Class: tripleo::profile::pacemaker::ceilometer::agent::central
#
# Ceilometer Central Agent Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*pacemaker_master*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::ceilometer::agent::central (
  $pacemaker_master = hiera('bootstrap_nodeid'),
  $step             = hiera('step'),
) {
  include ::ceilometer::params
  include ::tripleo::profile::pacemaker::ceilometer
  include ::tripleo::profile::base::ceilometer::agent::central

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {
    $ceilometer_backend = downcase(hiera('ceilometer_backend', 'mongodb'))
    case downcase(hiera('ceilometer_backend')) {
      /mysql/: {
        pacemaker::resource::service { $::ceilometer::params::agent_central_service_name:
          clone_params => 'interleave=true',
          require      => Pacemaker::Resource::Ocf['openstack-core'],
        }
      }
      default: {
        pacemaker::resource::service { $::ceilometer::params::agent_central_service_name:
          clone_params => 'interleave=true',
          require      => [Pacemaker::Resource::Ocf['openstack-core'],
                          Pacemaker::Resource::Service[$::mongodb::params::service_name]],
        }
      }
    }
  }

}
