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
# == Class: tripleo::profile::base::nova::compute_libvirt_shared
#
# Libvirt profile for tripleo. It will deploy Libvirt service and configure it.
#
# === Parameters
#
# [*nova_rbd_client_name*]
#   (optional) name of RBD client
#   defaults to hiera('nova::compute::rbd::libvirt_rbd_user')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::nova::compute_libvirt_shared (
  $nova_rbd_client_name = hiera('nova::compute::rbd::libvirt_rbd_user','openstack'),
  $step                 = Integer(hiera('step')),
) {
  if $step >= 4 {
    # Ceph + Libvirt
    $rbd_ephemeral_storage = hiera('nova::compute::rbd::ephemeral_storage', false)
    $rbd_persistent_storage = hiera('rbd_persistent_storage', false)
    if $rbd_ephemeral_storage or $rbd_persistent_storage {
      include ::nova::compute::rbd
      exec{ "exec-setfacl-${nova_rbd_client_name}-nova":
        path    => ['/bin', '/usr/bin'],
        command => "setfacl -m u:nova:r-- /etc/ceph/ceph.client.${nova_rbd_client_name}.keyring",
        unless  => "getfacl /etc/ceph/ceph.client.${nova_rbd_client_name}.keyring | grep -q user:nova:r--",
      }
      -> exec{ "exec-setfacl-${nova_rbd_client_name}-nova-mask":
        path    => ['/bin', '/usr/bin'],
        command => "setfacl -m m::r /etc/ceph/ceph.client.${nova_rbd_client_name}.keyring",
        unless  => "getfacl /etc/ceph/ceph.client.${nova_rbd_client_name}.keyring | grep -q mask::r",
      }
    }

    if $rbd_ephemeral_storage {
      class { '::nova::compute::libvirt':
        libvirt_disk_cachemodes => ['network=writeback'],
        libvirt_hw_disk_discard => 'unmap',
      }
    } else {
      include ::nova::compute::libvirt
    }
  }
}
