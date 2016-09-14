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
# == Function: tripleo::profile::base::swift::add_devices
#
# Swift add_devices helper function
#
# === Parameters
#
# [*swift_zones*]
#   (Optional) The number of swift zones.
#
define tripleo::profile::base::swift::add_devices(
  $swift_zones = '1'
){
  # NOTE(dprince): Swift zones is not yet properly wired into the Heat
  # templates. See: https://review.openstack.org/#/c/97758/3
  # For now our regex supports the r1z1-192.0.2.6:%PORT%/d1 syntax or the
  # newer r1z%<controller or SwiftStorage><N>%-192.0.2.6:%PORT%/d1 syntax.
  $server_num_or_device = regsubst($name,'^r1z%+[A-Za-z]*([0-9]+)%+-(.*)$','\1')
  if (is_integer($server_num_or_device)) {
    $server_num = $server_num_or_device
  } else {
    $server_num = '1'
  }
  # Function to place server in its zone.  Zone is calculated by
  # server number in heat template modulo the number of zones + 1.
  $zone = (($server_num%$swift_zones) + 1)

  # add the rings
  $base_notnormal = regsubst($name,'^r1.*-(.*)$','\1')
  $ip_notnormal = regsubst($base_notnormal, ':%PORT%.*', '')
  $ip = normalize_ip_for_uri($ip_notnormal)
  $base = regsubst($base_notnormal, $ip_notnormal, $ip)
  $object = regsubst($base, '%PORT%', '6000')
  ring_object_device { $object:
    zone   => '1',
    weight => 100,
  }
  $container = regsubst($base, '%PORT%', '6001')
  ring_container_device { $container:
    zone   => '1',
    weight => 100,
  }
  $account = regsubst($base, '%PORT%', '6002')
  ring_account_device { $account:
    zone   => '1',
    weight => 100,
  }
}
