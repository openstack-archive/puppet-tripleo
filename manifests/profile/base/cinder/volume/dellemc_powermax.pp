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
# == Class: tripleo::profile::base::cinder::volume::dellemc_powermax
#
# Cinder Volume dellemc_powermax profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to hiera('cinder::backend:dellemc_powermax::volume_backend_name,'
#   ['tripleo_dellemc_powermax'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to hiera('cinder::backend::dellemc_powermax::volume_multi_config', {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellemc_powermax (
  $backend_name = hiera('cinder::backend::dellemc_powermax::volume_backend_name', ['tripleo_dellemc_powermax']),
  $multi_config = hiera('cinder::backend::dellemc_powermax::volume_multi_config', {}),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderPowermaxAvailabilityZone' => hiera('cinder::backend::dellemc_powermax::backend_availability_zone', undef),
      'CinderPowermaxSanIp'            => hiera('cinder::backend::dellemc_powermax::san_ip', undef),
      'CinderPowermaxSanLogin'         => hiera('cinder::backend::dellemc_powermax::san_login', undef),
      'CinderPowermaxSanPassword'      => hiera('cinder::backend::dellemc_powermax::san password', undef),
      'CinderPowermaxStorageProtocol'  => hiera('cinder::backend::dellemc_powermax::powermax_storage_protocol', undef),
      'CinderPowermaxArray'            => hiera('cinder::backend::dellemc_powermax::powermax_array', undef),
      'CinderPowermaxSrp'              => hiera('cinder::backend::dellemc_powermax::powermax_srp', undef),
      'CinderPowermaxPortGroups'       => hiera('cinder::backend::dellemc_powermax::powermax_port_groups', undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      cinder::backend::dellemc_powermax { $backend :
        backend_availability_zone => $backend_config['CinderPowermaxAvailabilityZone'],
        san_ip                    => $backend_config['CinderPowermaxSanIp'],
        san_login                 => $backend_config['CinderPowermaxSanLogin'],
        san_password              => $backend_config['CinderPowermaxSanPassword'],
        powermax_storage_protocol => $backend_config['CinderPowermaxStorageProtocol'],
        powermax_array            => $backend_config['CinderPowermaxArray'],
        powermax_srp              => $backend_config['CinderPowermaxSrp'],
        powermax_port_groups      => $backend_config['CinderPowermaPortGroups'],
      }
    }
  }

}
