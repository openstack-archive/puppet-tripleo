# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::cinder::volume::netapp
#
# Cinder Volume netapp profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to  lookup('cinder::backend::netapp::volume_backend_name', undef, undef, ['tripleo_netapp'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::netapp::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::netapp (
  $backend_name = lookup('cinder::backend::netapp::volume_backend_name', undef, undef, ['tripleo_netapp']),
  $multi_config = lookup('cinder::backend::netapp::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderNetappAvailabilityZone'         => lookup('cinder::backend::netapp::backend_availability_zone', undef, undef, undef),
      'CinderNetappLogin'                    => lookup('cinder::backend::netapp::netapp_login', undef, undef, undef),
      'CinderNetappPassword'                 => lookup('cinder::backend::netapp::netapp_password', undef, undef, undef),
      'CinderNetappServerHostname'           => lookup('cinder::backend::netapp::netapp_server_hostname', undef, undef, undef),
      'CinderNetappServerPort'               => lookup('cinder::backend::netapp::netapp_server_port', undef, undef, undef),
      'CinderNetappSizeMultiplier'           => lookup('cinder::backend::netapp::netapp_size_multiplier', undef, undef, undef),
      'CinderNetappStorageFamily'            => lookup('cinder::backend::netapp::netapp_storage_family', undef, undef, undef),
      'CinderNetappStorageProtocol'          => lookup('cinder::backend::netapp::netapp_storage_protocol', undef, undef, undef),
      'CinderNetappTransportType'            => lookup('cinder::backend::netapp::netapp_transport_type', undef, undef, undef),
      'CinderNetappVserver'                  => lookup('cinder::backend::netapp::netapp_vserver', undef, undef, undef),
      'CinderNetappNfsShares'                => lookup('cinder::backend::netapp::nfs_shares', undef, undef, undef),
      'CinderNetappNfsSharesConfig'          => lookup('cinder::backend::netapp::nfs_shares_config', undef, undef, undef),
      'CinderNetappNfsMountOptions'          => lookup('cinder::backend::netapp::nfs_mount_options', undef, undef, undef),
      'CinderNetappCopyOffloadToolPath'      => lookup('cinder::backend::netapp::netapp_copyoffload_tool_path', undef, undef, undef),
      'CinderNetappHostType'                 => lookup('cinder::backend::netapp::netapp_host_type', undef, undef, undef),
      'CinderNetappNasSecureFileOperations'  => lookup('cinder::backend::netapp::nas_secure_file_operations', undef, undef, undef),
      'CinderNetappNasSecureFilePermissions' => lookup('cinder::backend::netapp::nas_secure_file_permissions', undef, undef, undef),
      'CinderNetappPoolNameSearchPattern'    => lookup('cinder::backend::netapp::netapp_pool_name_search_pattern', undef, undef, undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::netapp', { $backend => delete_undef_values({
        'backend_availability_zone'       => $backend_config['CinderNetappAvailabilityZone'],
        'netapp_login'                    => $backend_config['CinderNetappLogin'],
        'netapp_password'                 => $backend_config['CinderNetappPassword'],
        'netapp_server_hostname'          => $backend_config['CinderNetappServerHostname'],
        'netapp_server_port'              => $backend_config['CinderNetappServerPort'],
        'netapp_size_multiplier'          => $backend_config['CinderNetappSizeMultiplier'],
        'netapp_storage_family'           => $backend_config['CinderNetappStorageFamily'],
        'netapp_storage_protocol'         => $backend_config['CinderNetappStorageProtocol'],
        'netapp_transport_type'           => $backend_config['CinderNetappTransportType'],
        'netapp_vserver'                  => $backend_config['CinderNetappVserver'],
        'nfs_shares'                      => any2array($backend_config['CinderNetappNfsShares']),
        'nfs_shares_config'               => $backend_config['CinderNetappNfsSharesConfig'],
        'nfs_mount_options'               => $backend_config['CinderNetappNfsMountOptions'],
        'netapp_copyoffload_tool_path'    => $backend_config['CinderNetappCopyOffloadToolPath'],
        'netapp_host_type'                => $backend_config['CinderNetappHostType'],
        'nas_secure_file_operations'      => $backend_config['CinderNetappNasSecureFileOperations'],
        'nas_secure_file_permissions'     => $backend_config['CinderNetappNasSecureFilePermissions'],
        'netapp_pool_name_search_pattern' => $backend_config['CinderNetappPoolNameSearchPattern'],
      })})
    }
  }

}
