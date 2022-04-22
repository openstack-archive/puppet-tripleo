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
# == Class: tripleo::profile::base::cinder::volume::dellemc_sc
#
# Cinder Volume dellemc_sc profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to lookup('cinder::backend::dellemc_sc::volume_backend_name', undef, undef, ['tripleo_dellemc_sc'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::dellemc_sc::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_sc (
  $backend_name = lookup('cinder::backend::dellemc_sc::volume_backend_name', undef, undef, ['tripleo_dellemc_sc']),
  $multi_config = lookup('cinder::backend::dellemc_sc::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {

    $backend_defaults = {
      'CinderSCAvailabilityZone'         => lookup('cinder::backend::dellemc_sc::backend_availability_zone', undef, undef, undef),
      'CinderSCSanIp'                    => lookup('cinder::backend::dellemc_sc::san_ip', undef, undef, undef),
      'CinderSCSanLogin'                 => lookup('cinder::backend::dellemc_sc::san_login', undef, undef, undef),
      'CinderSCSanPassword'              => lookup('cinder::backend::dellemc_sc::san_password', undef, undef, undef),
      'CinderSCStorageProtocol'          => lookup('cinder::backend::dellemc_sc::sc_storage_protocol', undef, undef, undef),
      'CinderSCSSN'                      => lookup('cinder::backend::dellemc_sc::dell_sc_ssn', undef, undef, undef),
      'CinderSCTargetIpAddress'          => lookup('cinder::backend::dellemc_sc::iscsi_ip_address', undef, undef, undef),
      'CinderSCTargetPort'               => lookup('cinder::backend::dellemc_sc::iscsi_port', undef, undef, undef),
      'CinderSCApiPort'                  => lookup('cinder::backend::dellemc_sc::dell_sc_api_port', undef, undef, undef),
      'CinderSCServerFolder'             => lookup('cinder::backend::dellemc_sc::dell_sc_server_folder', undef, undef, undef),
      'CinderSCVolumeFolder'             => lookup('cinder::backend::dellemc_sc::dell_sc_volume_folder', undef, undef, undef),
      'CinderSCExcludedDomainIps'        => lookup('cinder::backend::dellemc_sc::excluded_domain_ips', undef, undef, undef),
      'CinderSCSecondarySanIp'           => lookup('cinder::backend::dellemc_sc::secondary_san_ip', undef, undef, undef),
      'CinderSCSecondarySanLogin'        => lookup('cinder::backend::dellemc_sc::secondary_san_login', undef, undef, undef),
      'CinderSCSecondarySanPassword'     => lookup('cinder::backend::dellemc_sc::secondary_san_password', undef, undef, undef),
      'CinderSCSecondaryApiPort'         => lookup('cinder::backend::dellemc_sc::secondary_sc_api_port', undef, undef, undef),
      'CinderSCUseMultipathForImageXfer' => lookup('cinder::backend::dellemc_sc::use_multipath_for_image_xfer', undef, undef, undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::dellemc_sc', { $backend => delete_undef_values({
        'backend_availability_zone'    => $backend_config['CinderSCAvailabilityZone'],
        'san_ip'                       => $backend_config['CinderSCSanIp'],
        'san_login'                    => $backend_config['CinderSCSanLogin'],
        'san_password'                 => $backend_config['CinderSCSanPassword'],
        'sc_storage_protocol'          => $backend_config['CinderSCStorageProtocol'],
        'dell_sc_ssn'                  => $backend_config['CinderSCSSN'],
        'target_ip_address'            => $backend_config['CinderSCTargetIpAddress'],
        'target_port'                  => $backend_config['CinderSCTargetPort'],
        'dell_sc_api_port'             => $backend_config['CinderSCApiPort'],
        'dell_sc_server_folder'        => $backend_config['CinderSCServerFolder'],
        'dell_sc_volume_folder'        => $backend_config['CinderSCVolumeFolder'],
        'excluded_domain_ips'          => $backend_config['CinderSCExcludedDomainIps'],
        'secondary_san_ip'             => $backend_config['CinderSCSecondarySanIp'],
        'secondary_san_login'          => $backend_config['CinderSCSecondarySanLogin'],
        'secondary_san_password'       => $backend_config['CinderSCSecondarySanPassword'],
        'secondary_sc_api_port'        => $backend_config['CinderSCSecondaryApiPort'],
        'use_multipath_for_image_xfer' => $backend_config['CinderSCUseMultipathForImageXfer'],
      })})
    }
  }
}
