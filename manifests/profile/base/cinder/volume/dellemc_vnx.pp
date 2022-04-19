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
#   Defaults to lookup('cinder::backend::emc_vnx::volume_backend_name', undef, undef, 'tripleo_dellemc_vnx')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_vnx (
  $backend_name = lookup('cinder::backend::emc_vnx::volume_backend_name', undef, undef, 'tripleo_dellemc_vnx'),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    # Accept recently deprecated 'storage_vnx_pool_name'
    $storage_vnx_pool_names_real = pick(lookup('cinder::backend::emc_vnx::storage_vnx_pool_names', undef, undef,
                                        lookup('cinder::backend::emc_vnx::storage_vnx_pool_name',
                                        undef, undef, undef)))

    create_resources('cinder::backend::emc_vnx', { $backend_name => delete_undef_values({
      'backend_availability_zone'     => lookup('cinder::backend::emc_vnx::backend_availability_zone', undef, undef, undef),
      'san_ip'                        => lookup('cinder::backend::emc_vnx::san_ip', undef, undef, undef),
      'san_login'                     => lookup('cinder::backend::emc_vnx::san_login', undef, undef, undef),
      'san_password'                  => lookup('cinder::backend::emc_vnx::san_password', undef, undef, undef),
      'storage_protocol'              => lookup('cinder::backend::emc_vnx::storage_protocol', undef, undef, undef),
      'storage_vnx_pool_names'        => lookup('cinder::backend::emc_vnx::storage_vnx_pool_names', undef, undef, undef),
      'default_timeout'               => lookup('cinder::backend::emc_vnx::default_timeout', undef, undef, undef),
      'max_luns_per_storage_group'    => lookup('cinder::backend::emc_vnx::max_luns_per_storage_group', undef, undef, undef),
      'initiator_auto_registration'   => lookup('cinder::backend::emc_vnx::initiator_auto_registration', undef, undef, undef),
      'storage_vnx_auth_type'         => lookup('cinder::backend::emc_vnx::storage_vnx_auth_type', undef, undef, undef),
      'storage_vnx_security_file_dir' => lookup('cinder::backend::emc_vnx::storage_vnx_security_file_dir', undef, undef, undef),
      'naviseccli_path'               => lookup('cinder::backend::emc_vnx::naviseccli_path', undef, undef, undef),
    })})
  }

}
