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
#   Defaults to lookup('cinder::backend:dellemc_powermax::volume_backend_name', undef, undef,
#   ['tripleo_dellemc_powermax'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::dellemc_powermax::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_powermax (
  $backend_name = lookup('cinder::backend::dellemc_powermax::volume_backend_name', undef, undef, ['tripleo_dellemc_powermax']),
  $multi_config = lookup('cinder::backend::dellemc_powermax::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderPowermaxAvailabilityZone' => lookup('cinder::backend::dellemc_powermax::backend_availability_zone', undef, undef, undef),
      'CinderPowermaxSanIp'            => lookup('cinder::backend::dellemc_powermax::san_ip', undef, undef, undef),
      'CinderPowermaxSanLogin'         => lookup('cinder::backend::dellemc_powermax::san_login', undef, undef, undef),
      'CinderPowermaxSanPassword'      => lookup('cinder::backend::dellemc_powermax::san_password', undef, undef, undef),
      'CinderPowermaxStorageProtocol'  => lookup('cinder::backend::dellemc_powermax::powermax_storage_protocol', undef, undef, undef),
      'CinderPowermaxArray'            => lookup('cinder::backend::dellemc_powermax::powermax_array', undef, undef, undef),
      'CinderPowermaxSrp'              => lookup('cinder::backend::dellemc_powermax::powermax_srp', undef, undef, undef),
      'CinderPowermaxPortGroups'       => lookup('cinder::backend::dellemc_powermax::powermax_port_groups', undef, undef, undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::dellemc_powermax', { $backend => delete_undef_values({
        'backend_availability_zone' => $backend_config['CinderPowermaxAvailabilityZone'],
        'san_ip'                    => $backend_config['CinderPowermaxSanIp'],
        'san_login'                 => $backend_config['CinderPowermaxSanLogin'],
        'san_password'              => $backend_config['CinderPowermaxSanPassword'],
        'powermax_storage_protocol' => $backend_config['CinderPowermaxStorageProtocol'],
        'powermax_array'            => $backend_config['CinderPowermaxArray'],
        'powermax_srp'              => $backend_config['CinderPowermaxSrp'],
        'powermax_port_groups'      => $backend_config['CinderPowermaxPortGroups'],
      })})
    }
  }

}
