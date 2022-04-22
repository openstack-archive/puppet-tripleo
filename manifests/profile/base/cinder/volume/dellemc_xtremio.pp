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
# == Class: tripleo::profile::base::cinder::volume::dellemc_xtremio
#
# Cinder Volume dellemc_xtremio profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to lookup('cinder::backend::dellemc_xtremio::volume_backend_name', undef, undef, ['tripleo_dellemc_xtremio'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::dellemc_xtremio::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_xtremio (
  $backend_name = lookup('cinder::backend::dellemc_xtremio::volume_backend_name', undef, undef, ['tripleo_dellemc_xtremio']),
  $multi_config = lookup('cinder::backend::dellemc_xtremio::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {

    $backend_defaults = {
      'CinderXtremioAvailabilityZone'      => lookup('cinder::backend::dellemc_xtremio::backend_availability_zone', undef, undef, undef),
      'CinderXtremioSanIp'                 => lookup('cinder::backend::dellemc_xtremio::san_ip', undef, undef, undef),
      'CinderXtremioSanLogin'              => lookup('cinder::backend::dellemc_xtremio::san_login', undef, undef, undef),
      'CinderXtremioSanPassword'           => lookup('cinder::backend::dellemc_xtremio::san_password', undef, undef, undef),
      'CinderXtremioStorageProtocol'       => lookup('cinder::backend::dellemc_xtremio::xtremio_storage_protocol', undef, undef, undef),
      'CinderXtremioClusterName'           => lookup('cinder::backend::dellemc_xtremio::xtremio_cluster_name', undef, undef, undef),
      'CinderXtremioArrayBusyRetryCount'   => lookup('cinder::backend::dellemc_xtremio::xtremio_array_busy_retry_count',
                                                    undef, undef, undef),
      'CinderXtremioArrayBusyRetryInterval'=> lookup('cinder::backend::dellemc_xtremio::xtremio_array_busy_retry_interval',
                                                    undef, undef, undef),
      'CinderXtremioVolumesPerGlanceCache' => lookup('cinder::backend::dellemc_xtremio::xtremio_volumes_per_glance_cache',
                                                    undef, undef, undef),
      'CinderXtremioPorts'                 => lookup('cinder::backend::dellemc_xtremio::xtremio_ports', undef, undef, undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::dellemc_xtremio', { $backend => delete_undef_values({
        'backend_availability_zone'         => $backend_config['CinderXtremioAvailabilityZone'],
        'san_ip'                            => $backend_config['CinderXtremioSanIp'],
        'san_login'                         => $backend_config['CinderXtremioSanLogin'],
        'san_password'                      => $backend_config['CinderXtremioSanPassword'],
        'xtremio_storage_protocol'          => $backend_config['CinderXtremioStorageProtocol'],
        'xtremio_cluster_name'              => $backend_config['CinderXtremioClusterName'],
        'xtremio_array_busy_retry_count'    => $backend_config['CinderXtremioArrayBusyRetryCount'],
        'xtremio_array_busy_retry_interval' => $backend_config['CinderXtremioArrayBusyRetryInterval'],
        'xtremio_volumes_per_glance_cache'  => $backend_config['CinderXtremioVolumesPerGlanceCache'],
        'xtremio_ports'                     => $backend_config['CinderXtremioPorts'],
      })})
    }
  }
}
