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
# == Class: tripleo::profile::pacemaker::glance
#
# Glance Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*glance_file_pcmk_device*]
#   (Optional) Device to mount glance file backend.
#   Defaults to hiera('glance_file_pcmk_device', '')
#
# [*glance_file_pcmk_directory*]
#   (Optional) Directory to mount glance file backend.
#   Defaults to hiera('glance_file_pcmk_directory', '')
#
# [*glance_file_pcmk_fstype*]
#   (Optional) Filesystem type to mount glance file backend.
#   Defaults to hiera('glance_file_pcmk_fstype', '')
#
# [*glance_file_pcmk_manage*]
#   (Optional) Whether or not manage glance_file_pcmk.
#   Defaults to hiera('glance_file_pcmk_manage', false)
#
# [*glance_file_pcmk_options*]
#   (Optional) pcmk options to mount Glance file backend..
#   Defaults to hiera('glance_file_pcmk_options', '')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::glance (
  $bootstrap_node             = hiera('bootstrap_nodeid'),
  $glance_backend             = downcase(hiera('glance_backend', 'swift')),
  $glance_file_pcmk_device    = hiera('glance_file_pcmk_device', ''),
  $glance_file_pcmk_directory = hiera('glance_file_pcmk_directory', ''),
  $glance_file_pcmk_fstype    = hiera('glance_file_pcmk_fstype', ''),
  $glance_file_pcmk_manage    = hiera('glance_file_pcmk_manage', false),
  $glance_file_pcmk_options   = hiera('glance_file_pcmk_options', ''),
  $step                       = hiera('step'),
) {
  Service <| tag == 'glance-service' |> {
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

  include ::tripleo::profile::base::glance::api
  include ::tripleo::profile::base::glance::registry

  if $step >= 4 {
    if $glance_backend == 'file' and $glance_file_pcmk_manage {
      $secontext = 'context="system_u:object_r:glance_var_lib_t:s0"'
      pacemaker::resource::filesystem { 'glance-fs':
        device       => $glance_file_pcmk_device,
        directory    => $glance_file_pcmk_directory,
        fstype       => $glance_file_pcmk_fstype,
        fsoptions    => join([$secontext, $glance_file_pcmk_options],','),
        clone_params => '',
      }
    }
  }

  if $step >= 5 and $pacemaker_master {
    pacemaker::resource::service { $::glance::params::registry_service_name :
      clone_params => 'interleave=true',
      require      => Pacemaker::Resource::Ocf['openstack-core'],
    }
    pacemaker::resource::service { $::glance::params::api_service_name :
      clone_params => 'interleave=true',
    }

    pacemaker::constraint::base { 'keystone-then-glance-registry-constraint':
      constraint_type => 'order',
      first_resource  => 'openstack-core-clone',
      second_resource => "${::glance::params::registry_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::glance::params::registry_service_name],
                          Pacemaker::Resource::Ocf['openstack-core']],
    }
    pacemaker::constraint::base { 'glance-registry-then-glance-api-constraint':
      constraint_type => 'order',
      first_resource  => "${::glance::params::registry_service_name}-clone",
      second_resource => "${::glance::params::api_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::glance::params::registry_service_name],
                          Pacemaker::Resource::Service[$::glance::params::api_service_name]],
    }
    pacemaker::constraint::colocation { 'glance-api-with-glance-registry-colocation':
      source  => "${::glance::params::api_service_name}-clone",
      target  => "${::glance::params::registry_service_name}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::glance::params::registry_service_name],
                  Pacemaker::Resource::Service[$::glance::params::api_service_name]],
    }
  }

}
