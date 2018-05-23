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
# == Class: tripleo::profile::base::cinder::volume::rbd
#
# Cinder Volume rbd profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_ceph'
#
# [*cinder_rbd_backend_host*]
#   (Optional) String to use as backend_host in the backend stanza
#   Defaults to hiera('cinder::backend_host', hiera('cinder::host', 'hostgroup'))
#
# [*cinder_rbd_ceph_conf*]
#   (Optional) The path to the Ceph cluster config file
#   Defaults to '/etc/ceph/ceph.conf'
#
# [*cinder_rbd_pool_name*]
#   (Optional) The name of the RBD pool to use
#   Defaults to 'volumes'
#
# [*cinder_rbd_extra_pools*]
#   (Optional) List of additional pools to use for Cinder. A separate RBD
#   backend is created for each additional pool.
#   Defaults to undef
#
# [*cinder_rbd_secret_uuid*]
#   (Optional) UUID of the of the libvirt secret storing the Cephx key
#   Defaults to undef
#
# [*cinder_rbd_user_name*]
#   (Optional) The user name for the RBD client
#   Defaults to 'openstack'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::rbd (
  $backend_name            = hiera('cinder::backend::rbd::volume_backend_name', 'tripleo_ceph'),
  $cinder_rbd_backend_host = hiera('cinder::backend_host', hiera('cinder::host', 'hostgroup')),
  $cinder_rbd_ceph_conf    = hiera('cinder::backend::rbd::rbd_ceph_conf', '/etc/ceph/ceph.conf'),
  $cinder_rbd_pool_name    = 'volumes',
  $cinder_rbd_extra_pools  = undef,
  $cinder_rbd_secret_uuid  = undef,
  $cinder_rbd_user_name    = 'openstack',
  $step                    = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::rbd { $backend_name :
      backend_host    => $cinder_rbd_backend_host,
      rbd_ceph_conf   => $cinder_rbd_ceph_conf,
      rbd_pool        => $cinder_rbd_pool_name,
      rbd_user        => $cinder_rbd_user_name,
      rbd_secret_uuid => $cinder_rbd_secret_uuid,
    }

    if $cinder_rbd_extra_pools {
      $cinder_rbd_extra_pools.each |$pool_name| {
        cinder::backend::rbd { "${backend_name}_${pool_name}" :
          backend_host    => $cinder_rbd_backend_host,
          rbd_ceph_conf   => $cinder_rbd_ceph_conf,
          rbd_pool        => $pool_name,
          rbd_user        => $cinder_rbd_user_name,
          rbd_secret_uuid => $cinder_rbd_secret_uuid,
        }
      }
    }
  }

}
