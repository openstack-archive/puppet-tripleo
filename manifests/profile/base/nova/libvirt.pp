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
# == Class: tripleo::profile::base::nova::libvirt
#
# Libvirt profile for tripleo. It will deploy Libvirt service and configure it.
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::nova::libvirt (
  $step = hiera('step'),
) {
  if $step >= 4 {
    include ::tripleo::profile::base::nova
    include ::nova::compute::libvirt::services

    file { ['/etc/libvirt/qemu/networks/autostart/default.xml',
      '/etc/libvirt/qemu/networks/default.xml']:
      ensure => absent,
      before => Service['libvirt'],
    }

    # in case libvirt has been already running before the Puppet run, make
    # sure the default network is destroyed
    exec { 'libvirt-default-net-destroy':
      command => '/usr/bin/virsh net-destroy default',
      onlyif  => '/usr/bin/virsh net-info default | /bin/grep -i "^active:\s*yes"',
      before  => Service['libvirt'],
    }
  }

}
