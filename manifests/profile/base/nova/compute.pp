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
# == Class: tripleo::profile::base::nova::compute
#
# Nova Compute profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*cinder_nfs_backend*]
#   (Optional) Whether or not Cinder is backed by NFS.
#   Defaults to hiera('cinder_enable_nfs_backend', false)
#
# [*nova_nfs_enabled*]
#   (Optional) Whether or not Nova is backed by NFS.
#   Defaults to false
#
# DEPRECATED PARAMETERS
#
# [*keymgr_backend*]
#   (Optional) The encryption key manager backend. The default value
#   ensures Nova's legacy key manager is enabled when no hiera value is
#   specified.
#   Defaults to undef.
#
class tripleo::profile::base::nova::compute (
  $step               = Integer(hiera('step')),
  $cinder_nfs_backend = hiera('cinder_enable_nfs_backend', false),
  $nova_nfs_enabled   = hiera('nova_nfs_enabled', false),
  # DEPRECATED PARAMETERS
  $keymgr_backend     = undef
) {

  if $step >= 4 {
    # deploy basic bits for nova
    include tripleo::profile::base::nova
    include nova::cinder
    include nova::compute::image_cache
    include nova::vendordata
    include nova::glance

    # deploy basic bits for nova-compute
    if keymgr_backend != undef {
      warning('The keymgr_backend parameter has been deprecated')
      class { 'nova::compute':
        keymgr_backend => $keymgr_backend
      }
    } else {
      class { 'nova::compute': }
    }

    include nova::compute::pci
    # If Service['nova-conductor'] is in catalog, make sure we start it
    # before nova-compute.
    Service<| title == 'nova-conductor' |> -> Service['nova-compute']


    # deploy bits to connect nova compute to neutron
    include nova::network::neutron
  }

  # If NFS is used as a Cinder or Nova backend
  if $cinder_nfs_backend or $nova_nfs_enabled {
    ensure_packages('nfs-utils', { ensure => present })
    Package['nfs-utils'] -> Service['nova-compute']
    if str2bool($::selinux) {
      selboolean { 'virt_use_nfs':
        value      => on,
        persistent => true,
      }
      Selboolean['virt_use_nfs'] -> Package['nfs-utils']
    }
  }

}
