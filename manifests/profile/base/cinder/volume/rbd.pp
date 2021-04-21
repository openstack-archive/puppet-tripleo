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
#   (Optional)  List of names given to the Cinder backend stanza.
#   Defaults to hiera('cinder::backend::rbd::volume_backend_name', ['tripleo_ceph'])
#
# [*backend_availability_zone*]
#   (Optional) Availability zone for this volume backend
#   Defaults to hiera('cinder::backend::rbd::backend_availability_zone', undef)
#
# [*cinder_rbd_backend_host*]
#   (Optional) String to use as backend_host in the backend stanza
#   Defaults to hiera('cinder::backend_host', hiera('cinder::host', $::hostname))
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
# [*cinder_rbd_flatten_volume_from_snapshot*]
#   (Optional) Whether volumes created from a snapshot should be flattened
#   in order to remove a dependency on the snapshot.
#   Defaults to hiera('cinder::backend::rbd::flatten_volume_from_snapshot, undef)
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to {}
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::rbd (
  $backend_name                            = hiera('cinder::backend::rbd::volume_backend_name', ['tripleo_ceph']),
  $backend_availability_zone               = hiera('cinder::backend::rbd::backend_availability_zone', undef),
  # lint:ignore:parameter_documentation
  $cinder_rbd_backend_host                 = hiera('cinder::backend_host', hiera('cinder::host', $::hostname)),
  # lint:endignore
  $cinder_rbd_ceph_conf                    = hiera('cinder::backend::rbd::rbd_ceph_conf', '/etc/ceph/ceph.conf'),
  $cinder_rbd_pool_name                    = 'volumes',
  $cinder_rbd_extra_pools                  = undef,
  $cinder_rbd_secret_uuid                  = undef,
  $cinder_rbd_user_name                    = 'openstack',
  $cinder_rbd_flatten_volume_from_snapshot = hiera('cinder::backend::rbd::flatten_volume_from_snapshot', undef),
  $multi_config                            = {},
  $step                                    = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CephClusterFSID'                    => $cinder_rbd_secret_uuid,
      'CephClientUserName'                 => $cinder_rbd_user_name,
      'CinderRbdAvailabilityZone'          => $backend_availability_zone,
      'CinderRbdPoolName'                  => $cinder_rbd_pool_name,
      'CinderRbdExtraPools'                => $cinder_rbd_extra_pools,
      'CinderRbdFlattenVolumeFromSnapshot' => $cinder_rbd_flatten_volume_from_snapshot,
    }

    any2array($backend_name).each |String $backend| {
      $backend_multi_config  = pick($multi_config[$backend], {})

      $multi_config_cluster = $backend_multi_config['CephClusterName']
      if $multi_config_cluster {
        $backend_ceph_conf = "/etc/ceph/${multi_config_cluster}.conf"
      } else {
        $backend_ceph_conf = $cinder_rbd_ceph_conf
      }

      $backend_config = merge($backend_defaults, $backend_multi_config)

      cinder::backend::rbd { $backend :
        backend_availability_zone        => $backend_config['CinderRbdAvailabilityZone'],
        backend_host                     => $cinder_rbd_backend_host,
        rbd_ceph_conf                    => $backend_ceph_conf,
        rbd_pool                         => $backend_config['CinderRbdPoolName'],
        rbd_user                         => $backend_config['CephClientUserName'],
        rbd_secret_uuid                  => $backend_config['CephClusterFSID'],
        rbd_flatten_volume_from_snapshot => $backend_config['CinderRbdFlattenVolumeFromSnapshot'],
      }

      any2array($backend_config['CinderRbdExtraPools']).each |String $pool_name| {
        cinder::backend::rbd { "${backend}_${pool_name}" :
          backend_availability_zone        => $backend_config['CinderRbdAvailabilityZone'],
          backend_host                     => $cinder_rbd_backend_host,
          rbd_ceph_conf                    => $backend_ceph_conf,
          rbd_pool                         => $pool_name,
          rbd_user                         => $backend_config['CephClientUserName'],
          rbd_secret_uuid                  => $backend_config['CephClusterFSID'],
          rbd_flatten_volume_from_snapshot => $backend_config['CinderRbdFlattenVolumeFromSnapshot'],
        }
      }
    }
  }

}
