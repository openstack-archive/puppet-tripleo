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
#   (Optional) List of names given to the Cinder backend stanza
#   Defaults to lookup('cinder::backend::emc_vnx::volume_backend_name', undef, undef, ['tripleo_dellemc_vnx'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::emc_vnx::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_vnx (
  $backend_name = lookup('cinder::backend::emc_vnx::volume_backend_name', undef, undef, ['tripleo_dellemc_vnx']),
  $multi_config = lookup('cinder::backend::emc_vnx::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderDellEMCVNXAvailabilityZone'          => lookup('cinder::backend::emc_vnx::backend_availability_zone', undef, undef, undef),
      'CinderDellEMCVNXSanIp'                     => lookup('cinder::backend::emc_vnx::san_ip', undef, undef, undef),
      'CinderDellEMCVNXSanLogin'                  => lookup('cinder::backend::emc_vnx::san_login', undef, undef, undef),
      'CinderDellEMCVNXSanPassword'               => lookup('cinder::backend::emc_vnx::san_password', undef, undef, undef),
      'CinderDellEMCVNXStorageProtocol'           => lookup('cinder::backend::emc_vnx::storage_protocol', undef, undef, undef),
      'CinderDellEMCVNXStoragePoolNames'          => lookup('cinder::backend::emc_vnx::storage_vnx_pool_names', undef, undef, undef),
      'CinderDellEMCVNXDefaultTimeout'            => lookup('cinder::backend::emc_vnx::default_timeout', undef, undef, undef),
      'CinderDellEMCVNXMaxLunsPerStorageGroup'    => lookup('cinder::backend::emc_vnx::max_luns_per_storage_group', undef, undef, undef),
      'CinderDellEMCVNXInitiatorAutoRegistration' => lookup('cinder::backend::emc_vnx::initiator_auto_registration', undef, undef, undef),
      'CinderDellEMCVNXAuthType'                  => lookup('cinder::backend::emc_vnx::storage_vnx_auth_type', undef, undef, undef),
      'CinderDellEMCVNXStorageSecurityFileDir'    => lookup('cinder::backend::emc_vnx::storage_vnx_security_file_dir', undef, undef, undef),
      'CinderDellEMCVNXNaviseccliPath'            => lookup('cinder::backend::emc_vnx::naviseccli_path', undef, undef, undef),
    }
    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::emc_vnx', { $backend => delete_undef_values({
        'backend_availability_zone'     => $backend_config['CinderDellEMCVNXAvailabilityZone'],
        'san_ip'                        => $backend_config['CinderDellEMCVNXSanIp'],
        'san_login'                     => $backend_config['CinderDellEMCVNXSanLogin'],
        'san_password'                  => $backend_config['CinderDellEMCVNXSanPassword'],
        'storage_protocol'              => $backend_config['CinderDellEMCVNXStorageProtocol'],
        'storage_vnx_pool_names'        => $backend_config['CinderDellEMCVNXStoragePoolNames'],
        'default_timeout'               => $backend_config['CinderDellEMCVNXDefaultTimeout'],
        'max_luns_per_storage_group'    => $backend_config['CinderDellEMCVNXMaxLunsPerStorageGroup'],
        'initiator_auto_registration'   => $backend_config['CinderDellEMCVNXInitiatorAutoRegistration'],
        'storage_vnx_auth_type'         => $backend_config['CinderDellEMCVNXAuthType'],
        'storage_vnx_security_file_dir' => $backend_config['CinderDellEMCVNXStorageSecurityFileDir'],
        'naviseccli_path'               => $backend_config['CinderDellEMCVNXNaviseccliPath'],
      })})
    }
  }

}
