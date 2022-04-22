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
# == Class: tripleo::profile::base::cinder::volume::dellemc_powerflex
#
# Cinder Volume dellemc_powerflex profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to lookup('cinder::backend::dellemc_powerflex::volume_backend_name', undef, undef, 'tripleo_dellemc_powerflex')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_powerflex (
  $backend_name = lookup('cinder::backend::dellemc_powerflex::volume_backend_name', undef, undef, 'tripleo_dellemc_powerflex'),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    create_resources('cinder::backend::dellemc_powerflex', { $backend_name => delete_undef_values({
      'backend_availability_zone'                => lookup('cinder::backend::dellemc_powerflex::backend_availability_zone',
                                                          undef, undef, undef),
      'san_login'                                => lookup('cinder::backend::dellemc_powerflex::san_login', undef, undef, undef),
      'san_password'                             => lookup('cinder::backend::dellemc_powerflex::san_password', undef, undef, undef),
      'san_ip'                                   => lookup('cinder::backend::dellemc_powerflex::san_ip', undef, undef, undef),
      'powerflex_storage_pools'                  => lookup('cinder::backend::dellemc_powerflex::powerflex_storage_pools',
                                                          undef, undef, undef),
      'powerflex_allow_migration_during_rebuild' => lookup('cinder::backend::dellemc_powerflex::powerflex_allow_migration_during_rebuild',
                                                          undef, undef, undef),
      'powerflex_allow_non_padded_volumes'       => lookup('cinder::backend::dellemc_powerflex::powerflex_allow_non_padded_volumes',
                                                          undef, undef, undef),
      'powerflex_max_over_subscription_ratio'    => lookup('cinder::backend::dellemc_powerflex::powerflex_max_over_subscription_ratio',
                                                          undef, undef, undef),
      'powerflex_rest_server_port'               => lookup('cinder::backend::dellemc_powerflex::powerflex_rest_server_port',
                                                          undef, undef, undef),
      'powerflex_round_volume_capacity'          => lookup('cinder::backend::dellemc_powerflex::powerflex_round_volume_capacity',
                                                          undef, undef, undef),
      'powerflex_server_api_version'             => lookup('cinder::backend::dellemc_powerflex::powerflex_server_api_version',
                                                          undef, undef, undef),
      'powerflex_unmap_volume_before_deletion'   => lookup('cinder::backend::dellemc_powerflex::powerflex_unmap_volume_before_deletion',
                                                          undef, undef, undef),
      'san_thin_provision'                       => lookup('cinder::backend::dellemc_powerflex::san_thin_provision', undef, undef, undef),
      'driver_ssl_cert_verify'                   => lookup('cinder::backend::dellemc_powerflex::driver_ssl_cert_verify',
                                                          undef, undef, undef),
      'driver_ssl_cert_path'                     => lookup('cinder::backend::dellemc_powerflex::driver_ssl_cert_path', undef, undef, undef)
    })})
  }
}
