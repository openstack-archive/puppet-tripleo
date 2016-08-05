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
# == Class: tripleo::profile::pacemaker::nova::consoleauth
#
# Nova Consoleauth with Pacemaker profile for tripleo
#
# === Parameters
#
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::nova::consoleauth (
  $pacemaker_master = hiera('bootstrap_nodeid'),
  $step             = hiera('step'),
) {

  include ::nova::params
  include ::tripleo::profile::pacemaker::nova
  include ::tripleo::profile::base::nova::consoleauth

  Service<| title == 'nova-consoleauth' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {
    pacemaker::resource::service { $::nova::params::consoleauth_service_name:
      clone_params => 'interleave=true',
    }

    pacemaker::constraint::base { 'keystone-then-nova-consoleauth-constraint':
      constraint_type => 'order',
      first_resource  => 'openstack-core-clone',
      second_resource => "${::nova::params::consoleauth_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::nova::params::consoleauth_service_name],
                          Pacemaker::Resource::Ocf['openstack-core']],
    }
    pacemaker::constraint::colocation { 'nova-consoleauth-with-openstack-core':
      source  => "${::nova::params::consoleauth_service_name}-clone",
      target  => 'openstack-core-clone',
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::nova::params::consoleauth_service_name],
                  Pacemaker::Resource::Ocf['openstack-core']],
    }
    pacemaker::constraint::base { 'nova-consoleauth-then-nova-vncproxy-constraint':
      constraint_type => 'order',
      first_resource  => "${::nova::params::consoleauth_service_name}-clone",
      second_resource => "${::nova::params::vncproxy_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::nova::params::consoleauth_service_name],
                          Pacemaker::Resource::Service[$::nova::params::vncproxy_service_name]],
    }
    pacemaker::constraint::colocation { 'nova-vncproxy-with-nova-consoleauth-colocation':
      source  => "${::nova::params::vncproxy_service_name}-clone",
      target  => "${::nova::params::consoleauth_service_name}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::nova::params::consoleauth_service_name],
                  Pacemaker::Resource::Service[$::nova::params::vncproxy_service_name]],
    }

  }

}
