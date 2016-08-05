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
# == Class: tripleo::profile::pacemaker::neutron::ovs
#
# Neutron OVS Agent Pacemaker HA profile for tripleo
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
class tripleo::profile::pacemaker::neutron::ovs (
  $pacemaker_master = hiera('bootstrap_nodeid', undef),
  $step             = hiera('step'),
) {
  include ::neutron::params
  include ::tripleo::profile::pacemaker::neutron
  include ::tripleo::profile::base::neutron::ovs

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {

    pacemaker::resource::service { $::neutron::params::ovs_agent_service:
      clone_params => 'interleave=true',
    }

    pacemaker::resource::ocf { $::neutron::params::ovs_cleanup_service:
      ocf_agent_name => 'neutron:OVSCleanup',
      clone_params   => 'interleave=true',
    }
    pacemaker::resource::ocf { 'neutron-netns-cleanup':
      ocf_agent_name => 'neutron:NetnsCleanup',
      clone_params   => 'interleave=true',
    }

    # neutron - one chain ovs-cleanup-->netns-cleanup-->ovs-agent
    pacemaker::constraint::base { 'neutron-ovs-cleanup-to-netns-cleanup-constraint':
      constraint_type => 'order',
      first_resource  => "${::neutron::params::ovs_cleanup_service}-clone",
      second_resource => 'neutron-netns-cleanup-clone',
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Ocf[$::neutron::params::ovs_cleanup_service],
                          Pacemaker::Resource::Ocf['neutron-netns-cleanup']],
    }
    pacemaker::constraint::colocation { 'neutron-ovs-cleanup-to-netns-cleanup-colocation':
      source  => 'neutron-netns-cleanup-clone',
      target  => "${::neutron::params::ovs_cleanup_service}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Ocf[$::neutron::params::ovs_cleanup_service],
                  Pacemaker::Resource::Ocf['neutron-netns-cleanup']],
    }
    pacemaker::constraint::base { 'neutron-netns-cleanup-to-openvswitch-agent-constraint':
      constraint_type => 'order',
      first_resource  => 'neutron-netns-cleanup-clone',
      second_resource => "${::neutron::params::ovs_agent_service}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Ocf['neutron-netns-cleanup'],
                          Pacemaker::Resource::Service[$::neutron::params::ovs_agent_service]],
    }
    pacemaker::constraint::colocation { 'neutron-netns-cleanup-to-openvswitch-agent-colocation':
      source  => "${::neutron::params::ovs_agent_service}-clone",
      target  => 'neutron-netns-cleanup-clone',
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Ocf['neutron-netns-cleanup'],
                  Pacemaker::Resource::Service[$::neutron::params::ovs_agent_service]],
    }
  }
}
