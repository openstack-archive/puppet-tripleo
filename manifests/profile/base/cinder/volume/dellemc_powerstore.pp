# Copyright (c) 2020 Dell Inc, or its subsidiaries.
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
# == Class: tripleo::profile::base::cinder::volume::dellemc_powerstore
#
# Cinder Volume dellemc_powerstore profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to hiera('cinder::backend:dellemc_powerstore::volume_backend_name,'
#   ['tripleo_dellemc_powerstore'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to hiera('cinder::backend::dellemc_powerstore::volume_multi_config', {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellemc_powerstore (
  $backend_name = hiera('cinder::backend::dellemc_powerstore::volume_backend_name', ['tripleo_dellemc_powerstore']),
  $multi_config = hiera('cinder::backend::dellemc_powerstore::volume_multi_config', {}),
  $step         = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderPowerStoreAvailabilityZone' => hiera('cinder::backend::dellemc_powerstore::backend_availability_zone', undef),
      'CinderPowerStoreSanIp'            => hiera('cinder::backend::dellemc_powerstore::san_ip', undef),
      'CinderPowerStoreSanLogin'         => hiera('cinder::backend::dellemc_powerstore::san_login', undef),
      'CinderPowerStoreSanPassword'      => hiera('cinder::backend::dellemc_powerstore::san_password', undef),
      'CinderPowerStoreStorageProtocol'  => hiera('cinder::backend::dellemc_powerstore::storage_protocol', undef),
      'CinderPowerStoreAppliances'       => hiera('cinder::backend::dellemc_powerstore::powerstore_appliances', undef),
      'CinderPowerStorePorts'            => hiera('cinder::backend::dellemc_powerstore::powerstore_ports', undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      cinder::backend::dellemc_powerstore { $backend :
        backend_availability_zone => $backend_config['CinderPowerStoreAvailabilityZone'],
        san_ip                    => $backend_config['CinderPowerStoreSanIp'],
        san_login                 => $backend_config['CinderPowerStoreSanLogin'],
        san_password              => $backend_config['CinderPowerStoreSanPassword'],
        storage_protocol          => $backend_config['CinderPowerStoreStorageProtocol'],
        powerstore_appliances     => $backend_config['CinderPowerStoreAppliances'],
        powerstore_ports          => $backend_config['CinderPowerStorePorts'],
      }
    }
  }

}
