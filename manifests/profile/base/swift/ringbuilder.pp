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
#  [*part_power*]
#  (Optional) The total number of partitions that should exist in the ring.
#  This is expressed as a power of 2.
#  Defaults to undef
#
#  [*min_part_hours*]
#  Minimum amount of time before partitions can be moved.
#  Defaults to undef
#
# [*swift_ring_get_tempurl*]
# GET tempurl to fetch Swift rings from
#
# [*swift_ring_put_tempurl*]
# PUT tempurl to upload Swift rings to
#
# [*skip_consistency_check*]
# If set to true, skip the recon check to ensure rings are identical on all
# nodes. Defaults to false
#
class tripleo::profile::base::swift::ringbuilder (
  $replicas,
  $build_ring  = true,
  $devices     = undef,
  $step        = Integer(hiera('step')),
  $swift_zones = '1',
  $raw_disk_prefix = 'r1z1-',
  $raw_disks = [],
  $swift_storage_node_ips = hiera('swift_storage_node_ips', []),
  $part_power = undef,
  $min_part_hours = undef,
  $swift_ring_get_tempurl = hiera('swift_ring_get_tempurl', ''),
  $swift_ring_put_tempurl = hiera('swift_ring_put_tempurl', ''),
  $skip_consistency_check = false,
) {

  if $step >= 2 and $swift_ring_get_tempurl != '' {
    exec{'fetch_swift_ring_tarball':
      path    => ['/usr/bin'],
      command => "curl -g --insecure --silent --retry 3 '${swift_ring_get_tempurl}' -o /tmp/swift-rings.tar.gz",
      returns => [0, 3],
      timeout => 30,
      tries   => 3,
    }
    ~> exec{'extract_swift_ring_tarball':
      path    => ['/bin'],
      command => 'tar xzf /tmp/swift-rings.tar.gz -C /',
      returns => [0, 2]
    }
  }

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
        part_power     => $part_power,
        replicas       => min(count($device_array), $replicas),
        min_part_hours => $min_part_hours,
      }

      # add all other devices
      -> tripleo::profile::base::swift::add_devices {$device_array:
        swift_zones => $swift_zones,
      }

      # rebalance
      -> swift::ringbuilder::rebalance{ ['object', 'account', 'container']:
        seed => '999',
      }

      Ring_object_device<| |> ~> Exec['rebalance_object']
      Ring_account_device<| |> ~> Exec['rebalance_account']
      Ring_container_device<| |> ~> Exec['rebalance_container']
    }
  }

  if $step >= 5 and $build_ring and $swift_ring_put_tempurl != '' {
    if $skip_consistency_check {
      exec{'create_swift_ring_tarball':
        path    => ['/bin', '/usr/bin'],
        command => 'tar cvzf /tmp/swift-rings.tar.gz /etc/swift/*.builder /etc/swift/*.ring.gz /etc/swift/backups/',
      }
    } else {
      exec{'create_swift_ring_tarball':
        path    => ['/bin', '/usr/bin'],
        command => 'tar cvzf /tmp/swift-rings.tar.gz /etc/swift/*.builder /etc/swift/*.ring.gz /etc/swift/backups/',
        unless  => 'swift-recon --md5 | grep -q "doesn\'t match"',
      }
    }
    exec{'upload_swift_ring_tarball':
      path        => ['/usr/bin'],
      command     => "curl -g --insecure --silent --retry 3 -X PUT '${$swift_ring_put_tempurl}' --data-binary @/tmp/swift-rings.tar.gz",
      require     => Exec['create_swift_ring_tarball'],
      refreshonly => true,
      timeout     => 30,
      tries       => 3,
    }

    Exec['rebalance_account'] ~> Exec['create_swift_ring_tarball']
    Exec['rebalance_container'] ~> Exec['create_swift_ring_tarball']
    Exec['rebalance_object'] ~> Exec['create_swift_ring_tarball']

    Exec['create_swift_ring_tarball'] ~> Exec['upload_swift_ring_tarball']
  }
}
