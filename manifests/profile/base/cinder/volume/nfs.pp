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
# == Class: tripleo::profile::base::cinder::volume::nfs
#
# Cinder Volume nfs profile for tripleo
#
# === Parameters
#
# [*cinder_nfs_servers*]
#   List of NFS shares to mount
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to lookup('cinder::backend::nfs::volume_backend_name', undef, undef, ['tripleo_nfs'])
#
# [*backend_availability_zone*]
#   (Optional) Availability zone for this volume backend
#   Defaults to  lookup('cinder::backend::nfs::backend_availability_zone', undef, undef, undef)
#
# [*cinder_nfs_mount_options*]
#   (Optional) List of mount options for the NFS share
#   Defaults to ''
#
# [*cinder_nfs_shares_config*]
#   (Optional) NFS shares configuration file
#   Defaults to '/etc/cinder/shares-nfs.conf'
#
# [*cinder_nfs_snapshot_support*]
#   (Optional) Whether to enable support for snapshots in the NFS driver.
#   Defaults to $::os_service_default
#
# [*cinder_nas_secure_file_operations*]
#   (Optional) Allow network-attached storage systems to operate in a secure
#   environment where root level access is not permitted. If set to False,
#   access is as the root user and insecure. If set to True, access is not as
#   root. If set to auto, a check is done to determine if this is a new
#   installation: True is used if so, otherwise False. Default is auto.
#   Defaults to $::os_service_default
#
# [*cinder_nas_secure_file_permissions*]
#   (Optional) Set more secure file permissions on network-attached storage
#   volume files to restrict broad other/world access. If set to False,
#   volumes are created with open permissions. If set to True, volumes are
#   created with permissions for the cinder user and group (660). If set to
#   auto, a check is done to determine if this is a new installation: True is
#   used if so, otherwise False. Default is auto.
#   Defaults to $::os_service_default
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to {}
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::nfs (
  $cinder_nfs_servers,
  $backend_name                       = lookup('cinder::backend::nfs::volume_backend_name', undef, undef, ['tripleo_nfs']),
  $backend_availability_zone          = lookup('cinder::backend::nfs::backend_availability_zone', undef, undef, undef),
  $cinder_nfs_mount_options           = '',
  $cinder_nfs_shares_config           = '/etc/cinder/shares-nfs.conf',
  $cinder_nfs_snapshot_support        = $::os_service_default,
  $cinder_nas_secure_file_operations  = $::os_service_default,
  $cinder_nas_secure_file_permissions = $::os_service_default,
  $multi_config                       = {},
  $step                               = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    package {'nfs-utils': }
    $backend_defaults = {
      'CinderNfsAvailabilityZone'      => $backend_availability_zone,
      'CinderNfsServers'               => $cinder_nfs_servers,
      'CinderNfsMountOptions'          => $cinder_nfs_mount_options,
      'CinderNfsSharesConfig'          => $cinder_nfs_shares_config,
      'CinderNfsSnapshotSupport'       => $cinder_nfs_snapshot_support,
      'CinderNasSecureFileOperations'  => $cinder_nas_secure_file_operations,
      'CinderNasSecureFilePermissions' => $cinder_nas_secure_file_permissions,
    }
    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))
      create_resources('cinder::backend::nfs', { $backend => delete_undef_values({
        'backend_availability_zone'   => $backend_config['CinderNfsAvailabilityZone'],
        'nfs_servers'                 => $backend_config['CinderNfsServers'],
        'nfs_mount_options'           => $backend_config['CinderNfsMountOptions'],
        'nfs_shares_config'           => $backend_config['CinderNfsSharesConfig'],
        'nfs_snapshot_support'        => $backend_config['CinderNfsSnapshotSupport'],
        'nas_secure_file_operations'  => $backend_config['CinderNasSecureFileOperations'],
        'nas_secure_file_permissions' => $backend_config['CinderNasSecureFilePermissions'],
      })})
      Package['nfs-utils'] -> Cinder::Backend::Nfs[$backend]
    }
    if str2bool($::selinux) {
      selboolean { 'virt_use_nfs':
        value      => on,
        persistent => true,
        require    => Package['nfs-utils'],
      }
    }
  }
}
