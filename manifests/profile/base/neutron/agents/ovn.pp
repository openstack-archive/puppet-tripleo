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
# == Class: tripleo::profile::base::neutron::agents::ovn
#
# OVN Neutron agent profile for tripleo
#
# [*ovn_db_host*]
#   (Optional) The IP-Address where OVN DBs are listening. If passed a list it
#   will construct a comma separated string like
#   protocol:ip1:port,protocol:ip2:port.
#   Defaults to hiera('ovn_dbs_vip')
#
# [*ovn_sbdb_port*]
#   (Optional) Port number on which southbound database is listening
#   Defaults to hiera('ovn::southbound::port')
#
# [*protocol*]
#   (optional) Protocol use in communication with dbs
#   Defaults to tcp
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*ovn_chassis_mac_map*]
#  (optional) A list of key-value pairs that map a chassis specific mac to
#  a physical network name. An example
#  value mapping two chassis macs to two physical network names would be:
#  physnet1:aa:bb:cc:dd:ee:ff,physnet2:a1:b2:c3:d4:e5:f6
#  These are the macs that ovn-controller will replace a router port
#  mac with, if packet is going from a distributed router port on
#  vlan type logical switch.
#  Defaults to hiera('ovn_chassis_mac_map')
#
class tripleo::profile::base::neutron::agents::ovn (
  $ovn_db_host          = hiera('ovn_dbs_vip'),
  $ovn_sbdb_port        = hiera('ovn::southbound::port'),
  $protocol             = 'tcp',
  $step                 = Integer(hiera('step')),
  $ovn_chassis_mac_map  = hiera('ovn_chassis_mac_map', undef),
) {
  if $step >= 4 {
    if is_string($ovn_db_host) {
      $ovn_remote_real = join(["${protocol}", normalize_ip_for_uri($ovn_db_host), "${ovn_sbdb_port}"], ':')
    } elsif is_array($ovn_db_host) {
      $ovn_remote_real = join($ovn_db_host.map |$i| { "${protocol}:${normalize_ip_for_uri($i)}:${ovn_sbdb_port}" }, ',')
    }

    class { 'ovn::controller':
      ovn_remote              => $ovn_remote_real,
      enable_ovn_match_northd => true,
      ovn_chassis_mac_map     => $ovn_chassis_mac_map,
    }
  }
}
