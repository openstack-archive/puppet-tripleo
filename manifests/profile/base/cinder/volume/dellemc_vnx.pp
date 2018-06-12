# Copyright (c) 2016-2018 Dell Inc, or its subsidiaries.
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
# == Class: tripleo::profile::base::cinder::volume::dellemc_vnx
#
# Cinder Volume dellemc_vnx profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_dellemc_vnx'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellemc_vnx (
  $backend_name = hiera('cinder::backend::emc_vnx::volume_backend_name', 'tripleo_dellemc_vnx'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    # Accept recently deprecated 'storage_vnx_pool_name'
    $storage_vnx_pool_names_real = pick(hiera('cinder::backend::emc_vnx::storage_vnx_pool_names',
                                        hiera('cinder::backend::emc_vnx::storage_vnx_pool_name',
                                        undef)))

    cinder::backend::emc_vnx { $backend_name :
      san_ip                        => hiera('cinder::backend::emc_vnx::san_ip', undef),
      san_login                     => hiera('cinder::backend::emc_vnx::san_login', undef),
      san_password                  => hiera('cinder::backend::emc_vnx::san_password', undef),
      storage_protocol              => hiera('cinder::backend::emc_vnx::storage_protocol', undef),
      storage_vnx_pool_names        => $storage_vnx_pool_names_real,
      default_timeout               => hiera('cinder::backend::emc_vnx::default_timeout', undef),
      max_luns_per_storage_group    => hiera('cinder::backend::emc_vnx::max_luns_per_storage_group', undef),
      initiator_auto_registration   => hiera('cinder::backend::emc_vnx::initiator_auto_registration', undef),
      storage_vnx_auth_type         => hiera('cinder::backend::emc_vnx::storage_vnx_auth_type', undef),
      storage_vnx_security_file_dir => hiera('cinder::backend::emc_vnx::storage_vnx_security_file_dir', undef),
      naviseccli_path               => hiera('cinder::backend::emc_vnx::naviseccli_path', undef),

    }
  }

}
