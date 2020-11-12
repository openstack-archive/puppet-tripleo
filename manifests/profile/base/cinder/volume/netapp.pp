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
#   Defaults to  hiera('cinder::backend::netapp::volume_backend_name', ['tripleo_netapp'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to hiera('cinder::backend::netapp::volume_multi_config', {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::netapp (
  $backend_name = hiera('cinder::backend::netapp::volume_backend_name', ['tripleo_netapp']),
  $multi_config = hiera('cinder::backend::netapp::volume_multi_config', {}),
  $step         = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderNetappAvailabilityZone'         => hiera('cinder::backend::netapp::backend_availability_zone', undef),
      'CinderNetappLogin'                    => hiera('cinder::backend::netapp::netapp_login', undef),
      'CinderNetappPassword'                 => hiera('cinder::backend::netapp::netapp_password', undef),
      'CinderNetappServerHostname'           => hiera('cinder::backend::netapp::netapp_server_hostname', undef),
      'CinderNetappServerPort'               => hiera('cinder::backend::netapp::netapp_server_port', undef),
      'CinderNetappSizeMultiplier'           => hiera('cinder::backend::netapp::netapp_size_multiplier', undef),
      'CinderNetappStorageFamily'            => hiera('cinder::backend::netapp::netapp_storage_family', undef),
      'CinderNetappStorageProtocol'          => hiera('cinder::backend::netapp::netapp_storage_protocol', undef),
      'CinderNetappTransportType'            => hiera('cinder::backend::netapp::netapp_transport_type', undef),
      'CinderNetappVfiler'                   => hiera('cinder::backend::netapp::netapp_vfiler', undef),
      'CinderNetappVserver'                  => hiera('cinder::backend::netapp::netapp_vserver', undef),
      'CinderNetappPartnerBackendName'       => hiera('cinder::backend::netapp::netapp_partner_backend_name', undef),
      'CinderNetappNfsShares'                => hiera('cinder::backend::netapp::nfs_shares', undef),
      'CinderNetappNfsSharesConfig'          => hiera('cinder::backend::netapp::nfs_shares_config', undef),
      'CinderNetappNfsMountOptions'          => hiera('cinder::backend::netapp::nfs_mount_options', undef),
      'CinderNetappCopyOffloadToolPath'      => hiera('cinder::backend::netapp::netapp_copyoffload_tool_path', undef),
      'CinderNetappControllerIps'            => hiera('cinder::backend::netapp::netapp_controller_ips', undef),
      'CinderNetappSaPassword'               => hiera('cinder::backend::netapp::netapp_sa_password', undef),
      'CinderNetappHostType'                 => hiera('cinder::backend::netapp::netapp_host_type', undef),
      'CinderNetappWebservicePath'           => hiera('cinder::backend::netapp::netapp_webservice_path', undef),
      'CinderNetappNasSecureFileOperations'  => hiera('cinder::backend::netapp::nas_secure_file_operations', undef),
      'CinderNetappNasSecureFilePermissions' => hiera('cinder::backend::netapp::nas_secure_file_permissions', undef),
      'CinderNetappPoolNameSearchPattern'    => hiera('cinder::backend::netapp::netapp_pool_name_search_pattern', undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      cinder::backend::netapp { $backend :
        backend_availability_zone       => $backend_config['CinderNetappAvailabilityZone'],
        netapp_login                    => $backend_config['CinderNetappLogin'],
        netapp_password                 => $backend_config['CinderNetappPassword'],
        netapp_server_hostname          => $backend_config['CinderNetappServerHostname'],
        netapp_server_port              => $backend_config['CinderNetappServerPort'],
        netapp_size_multiplier          => $backend_config['CinderNetappSizeMultiplier'],
        netapp_storage_family           => $backend_config['CinderNetappStorageFamily'],
        netapp_storage_protocol         => $backend_config['CinderNetappStorageProtocol'],
        netapp_transport_type           => $backend_config['CinderNetappTransportType'],
        netapp_vfiler                   => $backend_config['CinderNetappVfiler'],
        netapp_vserver                  => $backend_config['CinderNetappVserver'],
        netapp_partner_backend_name     => $backend_config['CinderNetappPartnerBackendName'],
        nfs_shares                      => any2array($backend_config['CinderNetappNfsShares']),
        nfs_shares_config               => $backend_config['CinderNetappNfsSharesConfig'],
        nfs_mount_options               => $backend_config['CinderNetappNfsMountOptions'],
        netapp_copyoffload_tool_path    => $backend_config['CinderNetappCopyOffloadToolPath'],
        netapp_controller_ips           => $backend_config['CinderNetappControllerIps'],
        netapp_sa_password              => $backend_config['CinderNetappSaPassword'],
        netapp_host_type                => $backend_config['CinderNetappHostType'],
        netapp_webservice_path          => $backend_config['CinderNetappWebservicePath'],
        nas_secure_file_operations      => $backend_config['CinderNetappNasSecureFileOperations'],
        nas_secure_file_permissions     => $backend_config['CinderNetappNasSecureFilePermissions'],
        netapp_pool_name_search_pattern => $backend_config['CinderNetappPoolNameSearchPattern'],
      }
    }
  }

}
