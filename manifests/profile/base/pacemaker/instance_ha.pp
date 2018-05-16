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
# [*no_shared_storage*]
#   Variable that defines the no_shared_storage for the nova evacuate resource
#   Defaults to hiera('tripleo::instanceha::no_shared_storage', true)
#
class tripleo::profile::base::pacemaker::instance_ha (
  $step                  = Integer(hiera('step')),
  $pcs_tries             = hiera('pcs_tries', 20),
  $keystone_endpoint_url = hiera('keystone::endpoint::public_url'),
  $keystone_password     = hiera('keystone::admin_password'),
  $keystone_admin        = hiera('keystone::roles::admin::admin_tenant', 'admin'),
  $keystone_domain       = hiera('tripleo::clouddomain', 'localdomain'),
  $user_domain           = hiera('nova::keystone::authtoken::user_domain_name', 'Default'),
  $project_domain        = hiera('nova::keystone::authtoken::project_domain_name', 'Default'),
  $no_shared_storage     = hiera('tripleo::instanceha::no_shared_storage', true),
) {
  if $step >= 2 {
    class { '::pacemaker::resource_defaults':
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
    pacemaker::stonith::fence_compute { 'fence-nova':
      auth_url       => $keystone_endpoint_url,
      login          => $keystone_admin,
      passwd         => $keystone_password,
      tenant_name    => $keystone_admin,
      project_domain => $project_domain,
      user_domain    => $user_domain,
      domain         => $keystone_domain,
      record_only    => 1,
      meta_attr      => 'provides=unfencing',
      pcmk_host_list => '',
      tries          => $pcs_tries,
    }

    pacemaker::resource::ocf { 'compute-unfence-trigger':
      ocf_agent_name => 'pacemaker:Dummy',
      meta_params    => 'requires=unfencing',
      clone_params   => true,
      tries          => $pcs_tries,
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
    pacemaker::resource::ocf { 'nova-evacuate':
      ocf_agent_name  => 'openstack:NovaEvacuate',
      # lint:ignore:140chars
      resource_params => "auth_url=${keystone_endpoint_url} username=${keystone_admin} password=${keystone_password} user_domain=${user_domain} project_domain=${project_domain} tenant_name=${keystone_admin} ${iha_no_shared_storage}",
      # lint:endignore
      tries           => $pcs_tries,
      location_rule   => {
        resource_discovery => 'never',
        score              => '-INFINITY',
        expression         => ['compute-instanceha-role eq true'],
      }
    }
  }
}
