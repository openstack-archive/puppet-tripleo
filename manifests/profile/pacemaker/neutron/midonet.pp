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
# == Class: tripleo::profile::pacemaker::neutron::midonet
#
# Neutron Midonet driver Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master
#   Defaults to hiera('bootstrap_nodeid', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::neutron::midonet (
  $pacemaker_master = hiera('bootstrap_nodeid', undef),
  $step             = hiera('step'),
) {
  include ::neutron::params
  include ::tripleo::profile::pacemaker::neutron
  include ::tripleo::profile::base::neutron::midonet

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {

    pacemaker::resource::service {'tomcat':
      clone_params => 'interleave=true',
    }

    #midonet-chain chain keystone-->neutron-server-->dhcp-->metadata->tomcat
    pacemaker::constraint::base { 'neutron-server-to-dhcp-agent-constraint':
      constraint_type => 'order',
      first_resource  => "${::neutron::params::server_service}-clone",
      second_resource => "${::neutron::params::dhcp_agent_service}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::neutron::params::server_service],
                          Pacemaker::Resource::Service[$::neutron::params::dhcp_agent_service]],
    }
    pacemaker::constraint::base { 'neutron-dhcp-agent-to-metadata-agent-constraint':
      constraint_type => 'order',
      first_resource  => "${::neutron::params::dhcp_agent_service}-clone",
      second_resource => "${::neutron::params::metadata_agent_service}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::neutron::params::dhcp_agent_service],
                          Pacemaker::Resource::Service[$::neutron::params::metadata_agent_service]],
    }
    pacemaker::constraint::base { 'neutron-metadata-agent-to-tomcat-constraint':
      constraint_type => 'order',
      first_resource  => "${::neutron::params::metadata_agent_service}-clone",
      second_resource => 'tomcat-clone',
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::neutron::params::metadata_agent_service],
                          Pacemaker::Resource::Service['tomcat']],
    }
    pacemaker::constraint::colocation { 'neutron-dhcp-agent-to-metadata-agent-colocation':
      source  => "${::neutron::params::metadata_agent_service}-clone",
      target  => "${::neutron::params::dhcp_agent_service}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::neutron::params::dhcp_agent_service],
                  Pacemaker::Resource::Service[$::neutron::params::metadata_agent_service]],
    }
  }
}
