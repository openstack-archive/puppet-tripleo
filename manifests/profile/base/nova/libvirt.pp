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
# [*libvirtd_config*]
#   (Optional) Overrides for libvirtd config options
#   Default to {}
#
class tripleo::profile::base::nova::libvirt (
  $step = Integer(hiera('step')),
  $libvirtd_config = {},
) {
  include ::tripleo::profile::base::nova::compute_libvirt_shared

  if $step >= 4 {
    include ::tripleo::profile::base::nova
    include ::tripleo::profile::base::nova::migration::client
    include ::nova::compute::libvirt::services

    $libvirtd_config_default = {
      unix_sock_group    => {value => '"libvirt"'},
      auth_unix_ro       => {value => '"none"'},
      auth_unix_rw       => {value => '"none"'},
      unix_sock_ro_perms => {value => '"0777"'},
      unix_sock_rw_perms => {value => '"0770"'}
    }

    class { '::nova::compute::libvirt::config':
      libvirtd_config => merge($libvirtd_config_default, $libvirtd_config)
    }

    file { ['/etc/libvirt/qemu/networks/autostart/default.xml',
      '/etc/libvirt/qemu/networks/default.xml']:
      ensure  => absent,
      require => Package['libvirt'],
      before  => Service['libvirt'],
    }

    # in case libvirt has been already running before the Puppet run, make
    # sure the default network is destroyed
    exec { 'libvirt-default-net-destroy':
      command => '/usr/bin/virsh net-destroy default',
      onlyif  => '/usr/bin/virsh net-info default | /bin/grep -i "^active:\s*yes"',
      require => Package['libvirt'],
      before  => Service['libvirt'],
    }

    include ::nova::compute::libvirt::qemu
  }
}
