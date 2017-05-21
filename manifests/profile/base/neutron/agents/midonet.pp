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
# == Class: tripleo::profile::base::neutron::agents::midonet
#
# Midonet Neutron agent profile
#
# === Parameters
#
# [*midonet_libvirt_qemu_data*]
#   (Optional) qemu.conf data for midonet.
#   Defaults to hiera('midonet_libvirt_qemu_data')
#
# [*neutron_api_node_ips*]
#   (Optional) The IPs of the Neutron API hosts
#   Defaults to hiera('neutron_api_node_ips')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::agents::midonet (
  $midonet_libvirt_qemu_data = hiera('midonet_libvirt_qemu_data', ''),
  $neutron_api_node_ips      = hiera('neutron_api_node_ips', ''),
  $step                      = Integer(hiera('step')),
) {
  if $step >= 4 {
    # TODO(devvesa) provide non-controller ips for these services
    class { '::tripleo::network::midonet::agent':
      zookeeper_servers => $neutron_api_node_ips,
      cassandra_seeds   => $neutron_api_node_ips
    }

    if defined(Service['libvirt']) {
      file { '/etc/libvirt/qemu.conf':
        ensure  => present,
        content => hiera('midonet_libvirt_qemu_data')
      }
    }
  }
}
