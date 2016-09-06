# Copyright 2015 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# == Class: tripleo::profile::base::swift::ringbuilder
#
# Swift ringbuilder profile for tripleo
#
# === Parameters
#
#  [*replicas*]
#    replicas
#
#  [*build_ring*] = true,
#   (Optional) Whether to build the ring
#   Defaults to true
#
#  [*devices*]
#   (Optional) DEPRECATED The swift devices
#   Should pass raw_disk_prefix, raw_disks and swift_storage_node_ips instead
#   Defaults to ''
#
#  [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
#  [*swift_zones*]
#   (Optional) The swift zones
#   Defaults to 1
#
#  [*raw_disk_prefix*]
#   (Optional) Disk prefix used to create devices list
#   Defaults to 'r1z1-'
#
#  [*raw_disks*]
#   (Optional) list of raw disks in format
#   [':%PORT%/device1', ':%PORT%/device2']
#   Combined with raw_disk_prefix and swift_storage_node_ips
#   to create devices list
#   Defaults to an empty list
#
#  [*swift_storage_node_ips*]
#  (Optional) list of ip addresses for nodes running swift_storage service
#  Defaults to hiera('swift_storage_node_ips') or an empty list
#
class tripleo::profile::base::swift::ringbuilder (
  $replicas,
  $build_ring  = true,
  $devices     = undef,
  $step        = hiera('step'),
  $swift_zones = '1',
  $raw_disk_prefix = 'r1z1-',
  $raw_disks = [],
  $swift_storage_node_ips = hiera('swift_storage_node_ips', []),
) {
  if $step >= 2 {
    # pre-install swift here so we can build rings
    include ::swift
  }

  if $step >= 3 {
    validate_bool($build_ring)

    if $build_ring {
      if $devices {
        $device_array = strip(split(rstrip($devices), ','))
      } else {
        $device_array = tripleo_swift_devices($raw_disk_prefix, $swift_storage_node_ips, $raw_disks)
      }

      # create local rings
      swift::ringbuilder::create{ ['object', 'account', 'container']:
        replicas       => min(count($device_array), $replicas),
      } ->

      # add all other devices
      tripleo::profile::base::swift::add_devices {$device_array:
        swift_zones => $swift_zones,
      } ->

      # rebalance
      swift::ringbuilder::rebalance{ ['object', 'account', 'container']:
        seed => 999,
      }

      Ring_object_device<| |> ~> Exec['rebalance_object']
      Ring_object_device<| |> ~> Exec['rebalance_account']
      Ring_object_device<| |> ~> Exec['rebalance_container']
    }
  }
}
