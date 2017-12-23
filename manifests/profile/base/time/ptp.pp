# Copyright 2017 Red Hat, Inc.
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
#
# == Class: tripleo::profile::base::time::ptp
#
# PTP base profile for tripleo.
#
# === Parameters
#
# [*ptp4l_interface*]
#   The physical interface name where PTP service is configured on
#   Defaults to 'eth0'
#
# [*ptp4l_conf_slaveonly*]
#   Whether to configure PTP service in slave mode
#   Defaults to 1
#
# [*ptp4l_conf_network_transport*]
#   PTP message transport protocol
#   Defaults to 'UDPv4'

class tripleo::profile::base::time::ptp (
  $ptp4l_interface                = 'eth0',
  $ptp4l_conf_slaveonly           = 1,
  $ptp4l_conf_network_transport   = 'UDPv4',
) {

  $interface_mapping = generate('/bin/os-net-config', '-i', $ptp4l_interface)
  $ptp4l_interface_name = $interface_mapping[$ptp4l_interface]

  ptp::instance_ptp4l { "ptp4l-${title}-${ptp4l_interface_name}":
    ptp4l_interface              => $ptp4l_interface_name,
    ptp4l_conf_slaveonly         => $ptp4l_conf_slaveonly,
    ptp4l_conf_network_transport => $ptp4l_conf_network_transport,
  }

  ptp::instance_phc2sys { "phc2sys-${title}-${ptp4l_interface_name}":
    auto_sync => true,
  }
}
