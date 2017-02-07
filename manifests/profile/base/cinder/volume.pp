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
# == Class: tripleo::profile::base::cinder::volume
#
# Cinder Volume profile for tripleo
#
# === Parameters
#
# [*cinder_enable_dellsc_backend*]
#   (Optional) Whether to enable the delsc backend
#   Defaults to true
#
# [*cinder_enable_hpelefthand_backend*]
#   (Optional) Whether to enable the hpelefthand backend
#   Defaults to false
#
# [*cinder_enable_dellps_backend*]
#   (Optional) Whether to enable the dellps backend
#   Defaults to true
#
# [*cinder_enable_iscsi_backend*]
#   (Optional) Whether to enable the iscsi backend
#   Defaults to true
#
# [*cinder_enable_netapp_backend*]
#   (Optional) Whether to enable the netapp backend
#   Defaults to true
#
# [*cinder_enable_nfs_backend*]
#   (Optional) Whether to enable the nfs backend
#   Defaults to true
#
# [*cinder_enable_rbd_backend*]
#   (Optional) Whether to enable the rbd backend
#   Defaults to true
#
# [*cinder_user_enabled_backends*]
#   (Optional) List of additional backend stanzas to activate
#   Defaults to hiera('cinder_user_enabled_backends')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume (
  $cinder_enable_dellsc_backend      = false,
  $cinder_enable_hpelefthand_backend = false,
  $cinder_enable_dellps_backend      = false,
  $cinder_enable_iscsi_backend       = true,
  $cinder_enable_netapp_backend      = false,
  $cinder_enable_nfs_backend         = false,
  $cinder_enable_rbd_backend         = false,
  $cinder_user_enabled_backends      = hiera('cinder_user_enabled_backends', undef),
  $step                              = hiera('step'),
) {
  include ::tripleo::profile::base::cinder

  if $step >= 4 {
    include ::cinder::volume

    if $cinder_enable_dellsc_backend {
      include ::tripleo::profile::base::cinder::volume::dellsc
      $cinder_dellsc_backend_name = hiera('cinder::backend::dellsc_iscsi::volume_backend_name', 'tripleo_dellsc')
    } else {
      $cinder_dellsc_backend_name = undef
    }

    if $cinder_enable_hpelefthand_backend {
      include ::tripleo::profile::base::cinder::volume::hpelefthand
      $cinder_hpelefthand_backend_name = hiera('cinder::backend::hpelefthand_iscsi::volume_backend_name', 'tripleo_hpelefthand')
    } else {
      $cinder_hpelefthand_backend_name = undef
    }

    if $cinder_enable_dellps_backend {
      include ::tripleo::profile::base::cinder::volume::dellps
      $cinder_dellps_backend_name = hiera('cinder::backend::dellps::volume_backend_name', 'tripleo_dellps')
    } else {
      $cinder_dellps_backend_name = undef
    }

    if $cinder_enable_iscsi_backend {
      include ::tripleo::profile::base::cinder::volume::iscsi
      $cinder_iscsi_backend_name = hiera('cinder::backend::iscsi::volume_backend_name', 'tripleo_iscsi')
    } else {
      $cinder_iscsi_backend_name = undef
    }

    if $cinder_enable_netapp_backend {
      include ::tripleo::profile::base::cinder::volume::netapp
      $cinder_netapp_backend_name = hiera('cinder::backend::netapp::volume_backend_name', 'tripleo_netapp')
    } else {
      $cinder_netapp_backend_name = undef
    }

    if $cinder_enable_nfs_backend {
      include ::tripleo::profile::base::cinder::volume::nfs
      $cinder_nfs_backend_name = hiera('cinder::backend::nfs::volume_backend_name', 'tripleo_nfs')
    } else {
      $cinder_nfs_backend_name = undef
    }

    if $cinder_enable_rbd_backend {
      include ::tripleo::profile::base::cinder::volume::rbd
      $cinder_rbd_backend_name = hiera('cinder::backend::rbd::volume_backend_name', 'tripleo_ceph')
    } else {
      $cinder_rbd_backend_name = undef
    }

    $backends = delete_undef_values([$cinder_iscsi_backend_name,
                                      $cinder_rbd_backend_name,
                                      $cinder_dellps_backend_name,
                                      $cinder_dellsc_backend_name,
                                      $cinder_hpelefthand_backend_name,
                                      $cinder_netapp_backend_name,
                                      $cinder_nfs_backend_name,
                                      $cinder_user_enabled_backends])
    # NOTE(aschultz): during testing it was found that puppet 3 may incorrectly
    # include a "" in the previous array which is not removed by the
    # delete_undef_values function. So we need to make sure we don't have any
    # "" strings in our array.
    $cinder_enabled_backends = delete($backends, '')

    class { '::cinder::backends' :
      enabled_backends => $cinder_enabled_backends,
    }
  }

}
