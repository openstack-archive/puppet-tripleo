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
# == Class: tripleo::profile::base::pacemaker::instance_ha
#
# Pacemaker profile for configuring instance HA on the control plane in tripleo
# Note that this class is included under the condition $pacemaker_master and $enable_instanceha
#
# === Parameters
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
# [*keystone_endpoint_url*]
#   The keystone public endpoint url
#   Defaults to hiera('keystone::endpoint::public_url')
#
# [*keystone_password*]
#   The keystone admin password
#   Defaults to hiera('keystone::admin_password')
#
# [*keystone_admin*]
#   The keystone admin username
#   Defaults to hiera('keystone::roles::admin::admin_tenant', 'admin')
#
# [*keystone_tenant*]
#   The keystone tenant
#   Defaults to hiera('keystone::roles::admin::admin_tenant', 'admin')
#
# [*keystone_domain*]
#   The keystone domain
#   Defaults to hiera('tripleo::clouddomain', 'localdomain')
#
# [*user_domain*]
#   The keystone user domain for nova
#   Defaults to hiera('nova::keystone::authtoken::user_domain_name', 'Default')
#
# [*project_domain*]
#   The keystone project domain for nova
#   Defaults to hiera('nova::keystone::authtoken::project_domain_name', 'Default')
#
# [*region_name*]
#   (Optional) String. Region name for authenticating to Keystone.
#   Defaults to hiera('nova::keystone::authtoken::region_name', 'regionOne')
#
# [*no_shared_storage*]
#   Variable that defines the no_shared_storage for the nova evacuate resource
#   Defaults to hiera('tripleo::instanceha::no_shared_storage', true)
#
# [*evacuate_delay*]
#   (Optional) Integer, seconds to wait before starting the nova evacuate
#   Defaults to hiera('tripleo::instanceha::evacuate_delay', 0)
#
# [*deep_compare_fencing*]
#   (Optional) Boolean, should fence_compute be deep compared in order to
#   update the existing fencing resource when puppet is being rerun
#   Defaults to hiera('tripleo::fencing', true)
#
# [*deep_compare_ocf*]
#   (Optional) Boolean, should the IHA ocf resource nova evacuate be deep
#   compared in order to update the resource when puppet is being rerun
#   Defaults to hiera('pacemaker::resource::ocf::deep_compare', true)
#
class tripleo::profile::base::pacemaker::instance_ha (
  $step                  = Integer(hiera('step')),
  $pcs_tries             = hiera('pcs_tries', 20),
  $keystone_endpoint_url = hiera('keystone::endpoint::public_url'),
  $keystone_password     = hiera('keystone::admin_password'),
  $keystone_admin        = hiera('keystone::roles::admin::admin_tenant', 'admin'),
  $keystone_tenant       = hiera('keystone::roles::admin::admin_tenant', 'admin'),
  $keystone_domain       = hiera('tripleo::clouddomain', 'localdomain'),
  $user_domain           = hiera('nova::keystone::authtoken::user_domain_name', 'Default'),
  $project_domain        = hiera('nova::keystone::authtoken::project_domain_name', 'Default'),
  $region_name           = hiera('nova::keystone::authtoken::region_name', 'regionOne'),
  $no_shared_storage     = hiera('tripleo::instanceha::no_shared_storage', true),
  $evacuate_delay        = hiera('tripleo::instanceha::evacuate_delay', 0),
  $deep_compare_fencing  = hiera('tripleo::fencing', true),
  $deep_compare_ocf      = hiera('pacemaker::resource::ocf::deep_compare', true),
) {
  if $step >= 2 {
    class { 'pacemaker::resource_defaults':
      tries    => $pcs_tries,
      defaults => {
        'fencing-default' => {
          name  => 'requires',
          value => 'fencing',
        },
      },
    }
  }
  # We need the guarantee that keystone is configured before creating the next resources
  if $step >= 4 {
    # This passes the explicit host list of compute nodes that the fence_compute stonith device
    # is in charge of
    $compute_list = downcase(join(any2array(hiera('compute_instanceha_short_node_names', '')), ','))
    pacemaker::stonith::fence_compute { 'fence-nova':
      auth_url       => $keystone_endpoint_url,
      login          => $keystone_admin,
      passwd         => $keystone_password,
      tenant_name    => $keystone_admin,
      project_domain => $project_domain,
      user_domain    => $user_domain,
      domain         => $keystone_domain,
      region_name    => $region_name,
      record_only    => 1,
      meta_attr      => 'provides=unfencing',
      pcmk_host_list => $compute_list,
      tries          => $pcs_tries,
      deep_compare   => $deep_compare_fencing,
    }

    pacemaker::resource::ocf { 'compute-unfence-trigger':
      ocf_agent_name => 'pacemaker:Dummy',
      meta_params    => 'requires=unfencing',
      clone_params   => true,
      op_params      => 'stop timeout=20 on-fail=block',
      tries          => $pcs_tries,
      deep_compare   => $deep_compare_ocf,
      location_rule  => {
        resource_discovery => 'never',
        score              => '-INFINITY',
        expression         => ['compute-instanceha-role ne true'],
      }
    }
    if $no_shared_storage {
      $iha_no_shared_storage = 'no_shared_storage=true'
    } else {
      $iha_no_shared_storage = 'no_shared_storage=false'
    }
    if $evacuate_delay > 0 {
      $evacuate_param = " evacuate_delay=${evacuate_delay}"
    } else {
      $evacuate_param = ''
    }
    pacemaker::resource::ocf { 'nova-evacuate':
      ocf_agent_name  => 'openstack:NovaEvacuate',
      # lint:ignore:140chars
      resource_params => "auth_url=${keystone_endpoint_url} username=${keystone_admin} password=${keystone_password} user_domain=${user_domain} project_domain=${project_domain} tenant_name=${keystone_tenant} region_name=${region_name} ${iha_no_shared_storage}${evacuate_param}",
      # lint:endignore
      tries           => $pcs_tries,
      deep_compare    => $deep_compare_ocf,
      location_rule   => {
        resource_discovery => 'never',
        score              => '-INFINITY',
        expression         => ['compute-instanceha-role eq true'],
      }
    }
  }
}
