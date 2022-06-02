# Copyright (c) 2016-2017 Dell Inc, or its subsidiaries.
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
# == Class: tripleo::profile::base::cinder::volume::dellemc_unity
#
# Cinder Volume dellemc_unity profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to lookup('cinder::backend::dellemc_unity::volume_backend_name', undef, undef, ['tripleo_dellemc_unity'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::dellemc_unity::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_unity (
  $backend_name = lookup('cinder::backend::dellemc_unity::volume_backend_name', undef, undef, ['tripleo_dellemc_unity']),
  $multi_config = lookup('cinder::backend::dellemc_unity::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderDellEMCUnityAvailabilityZone' => lookup('cinder::backend::dellemc_unity::backend_availability_zone', undef, undef, undef),
      'CinderDellEMCUnitySanIp'            => lookup('cinder::backend::dellemc_unity::san_ip', undef, undef, undef),
      'CinderDellEMCUnitySanLogin'         => lookup('cinder::backend::dellemc_unity::san_login', undef, undef, undef),
      'CinderDellEMCUnitySanPassword'      => lookup('cinder::backend::dellemc_unity::san_password', undef, undef, undef),
      'CinderDellEMCUnityStorageProtocol'  => lookup('cinder::backend::dellemc_unity::storage_protocol', undef, undef, undef),
      'CinderDellEMCUnityIoPorts'          => lookup('cinder::backend::dellemc_unity::unity_io_ports', undef, undef, undef),
      'CinderDellEMCUnityStoragePoolNames' => lookup('cinder::backend::dellemc_unity::unity_storage_pool_names', undef, undef, undef),
    }
    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::dellemc_unity', { $backend => delete_undef_values({
        'backend_availability_zone' => $backend_config['CinderDellEMCUnityAvailabilityZone'],
        'san_ip'                    => $backend_config['CinderDellEMCUnitySanIp'],
        'san_login'                 => $backend_config['CinderDellEMCUnitySanLogin'],
        'san_password'              => $backend_config['CinderDellEMCUnitySanPassword'],
        'storage_protocol'          => $backend_config['CinderDellEMCUnityStorageProtocol'],
        'unity_io_ports'            => $backend_config['CinderDellEMCUnityIoPorts'],
        'unity_storage_pool_names'  => $backend_config['CinderDellEMCUnityStoragePoolNames'],
      })})
    }
  }

}
