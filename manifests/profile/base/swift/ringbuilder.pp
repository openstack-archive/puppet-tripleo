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
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#  [*swift_zones*]
#   (Optional) The swift zones
#   Defaults to 1
#  [*devices*]
#   (Optional) The swift devices
#   Defaults to ''
#  [*build_ring*]      = true,
#   (Optional) Whether to build the ring
#   Defaults to true
#  [*replicas*]
#    replicas

class tripleo::profile::base::swift::ringbuilder (
  $step = hiera('step'),
  $swift_zones     = '1',
  $devices         = '',
  $build_ring      = true,
  $replicas,
) {

  if $step >= 2 {
    # pre-install swift here so we can build rings
    include ::swift
  }

  if $step >= 3 {
    validate_bool($build_ring)

    if $build_ring {

      $device_array = strip(split(rstrip($devices), ','))

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
