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
# == Class: tripleo::profile::base::cinder::volume::iscsi
#
# Cinder Volume iscsi profile for tripleo
#
# === Parameters
#
# [*cinder_iscsi_address*]
#   The address where to bind the iscsi targets daemon
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_iscsi'
#
# [*cinder_iscsi_helper*]
#   (Optional) The iscsi helper to use
#   Defaults to 'tgtadm'
#
# [*cinder_iscsi_protocol*]
#   (Optional) The iscsi protocol to use
#   Defaults to 'iscsi'
#
# [*cinder_lvm_loop_device_size*]
#   (Optional) The size (in MB) of the LVM loopback volume
#   Defaults to '10280'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::iscsi (
  $cinder_iscsi_address,
  $backend_name                = hiera('cinder::backend::iscsi::volume_backend_name', 'tripleo_iscsi'),
  $cinder_iscsi_helper         = 'tgtadm',
  $cinder_iscsi_protocol       = 'iscsi',
  $cinder_lvm_loop_device_size = '10280',
  $step                        = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    class { '::cinder::setup_test_volume':
      size => join([$cinder_lvm_loop_device_size, 'M']),
    }

    # NOTE(gfidente): never emit in hieradata:
    # key: [ipv6]
    # as it will cause hiera parsing errors
    cinder::backend::iscsi { $backend_name :
      iscsi_ip_address => normalize_ip_for_uri($cinder_iscsi_address),
      iscsi_helper     => $cinder_iscsi_helper,
      iscsi_protocol   => $cinder_iscsi_protocol,
    }
  }

}
