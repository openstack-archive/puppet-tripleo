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
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_nfs'
#
# [*cinder_nfs_mount_options*]
#   (Optional) List of mount options for the NFS share
#   Defaults to ''
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::nfs (
  $cinder_nfs_servers,
  $backend_name             = hiera('cinder::backend::nfs::volume_backend_name', 'tripleo_nfs'),
  $cinder_nfs_mount_options = '',
  $step                     = hiera('step'),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    if str2bool($::selinux) {
      selboolean { 'virt_use_nfs':
        value      => on,
        persistent => true,
      } -> Package['nfs-utils']
    }

    package {'nfs-utils': } ->
    cinder::backend::nfs { $backend_name :
      nfs_servers       => $cinder_nfs_servers,
      nfs_mount_options => $cinder_nfs_mount_options,
      nfs_shares_config => '/etc/cinder/shares-nfs.conf',
    }
  }

}
