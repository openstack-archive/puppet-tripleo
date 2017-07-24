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
# == Class: tripleo::glance::nfs_mount
#
# NFS mount for Glance image storage file backend
#
# === Parameters
#
# [*share*]
#   NFS share to mount, in 'IP:PATH' format.
#
# [*options*]
#   (Optional) NFS mount options. Defaults to
#   'intr,context=system_u:object_r:glance_var_lib_t:s0'
#
# [*edit_fstab*]
#   (Optional) Whether to persist the mount info to fstab.
#   Defaults to true.
#
# [*fstab_fstype*]
#   (Optional) File system type to use in fstab for the mount.
#   Defaults to 'nfs4'.
#
# [*fstab_prepend_options*]
#   (Optional) Extra mount options for fstab (prepended to $options).
#   Defaults to 'bg', so that a potentially failed mount doesn't
#   prevent the machine from booting.
#
class tripleo::glance::nfs_mount (
  $share,
  $options               = 'intr,context=system_u:object_r:glance_var_lib_t:s0',
  $edit_fstab            = true,
  $fstab_fstype          = 'nfs4',
  $fstab_prepend_options = '_netdev,bg'
) {

  $images_dir = '/var/lib/glance/images'

  if $options and $options != '' {
    $options_part = "-o ${options}"
  } else {
    $options_part = ''
  }

  if $fstab_prepend_options and $fstab_prepend_options != '' {
    $fstab_prepend_part = "${fstab_prepend_options},"
  } else {
    $fstab_prepend_part = ''
  }

  file { $images_dir:
    ensure => directory,
  }
  -> exec { 'NFS mount for glance file backend':
    path    => ['/usr/sbin', '/usr/bin'],
    command => "mount -t nfs '${share}' '${images_dir}' ${options_part}",
    unless  => "mount | grep ' ${images_dir} '",
  }

  if $edit_fstab {
    file_line { 'NFS for glance in fstab':
      ensure => present,
      line   => "${share} ${images_dir} ${fstab_fstype} ${fstab_prepend_part}${options} 0 0",
      match  => " ${images_dir} ",
      path   => '/etc/fstab',
    }
  }
}
