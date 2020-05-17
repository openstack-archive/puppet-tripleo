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
# == Class: tripleo::profile::base::cinder::volume::dellemc_vxflexos
#
# Cinder Volume dellemc_vxflexos profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_dellemc_vxflexos'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellemc_vxflexos (
  $backend_name = hiera('cinder::backend::dellemc_vxflexos::volume_backend_name', 'tripleo_dellemc_vxflexos'),
  $step         = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::dellemc_vxflexos { $backend_name :
      backend_availability_zone               => hiera('cinder::backend::dellemc_vxflexos::backend_availability_zone', undef),
      san_login                               => hiera('cinder::backend::dellemc_vxflexos::san_login', undef),
      san_password                            => hiera('cinder::backend::dellemc_vxflexos::san_password', undef),
      san_ip                                  => hiera('cinder::backend::dellemc_vxflexos::san_ip', undef),
      vxflexos_storage_pools                  => hiera('cinder::backend::dellemc_vxflexos::vxflexos_storage_pools', undef),
      vxflexos_allow_migration_during_rebuild => hiera('cinder::backend::dellemc_vxflexos::vxflexos_allow_migration_during_rebuild', undef),
      vxflexos_allow_non_padded_volumes       => hiera('cinder::backend::dellemc_vxflexos::vxflexos_allow_non_padded_volumes', undef),
      vxflexos_max_over_subscription_ratio    => hiera('cinder::backend::dellemc_vxflexos::vxflexos_max_over_subscription_ratio', undef),
      vxflexos_rest_server_port               => hiera('cinder::backend::dellemc_vxflexos::vxflexos_rest_server_port', undef),
      vxflexos_round_volume_capacity          => hiera('cinder::backend::dellemc_vxflexos::vxflexos_round_volume_capacity', undef),
      vxflexos_server_api_version             => hiera('cinder::backend::dellemc_vxflexos::vxflexos_server_api_version', undef),
      vxflexos_unmap_volume_before_deletion   => hiera('cinder::backend::dellemc_vxflexos::vxflexos_unmap_volume_before_deletion', undef),
      san_thin_provision                      => hiera('cinder::backend::dellemc_vxflexos::san_thin_provision', undef),
      driver_ssl_cert_verify                  => hiera('cinder::backend::dellemc_vxflexos::driver_ssl_cert_verify', undef),
      driver_ssl_cert_path                    => hiera('cinder::backend::dellemc_vxflexos::driver_ssl_cert_path', undef)
    }
  }
}
