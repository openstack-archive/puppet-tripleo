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
# == Class: tripleo::profile::base::nova::compute::libvirt_guests
#
# Configures libvirt-guests service.
#
# === Parameters:
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*enabled*]
#   (Optional) Whether libvirt-guests should be configured and enabled or not.
#   Defaults to undef
#
class tripleo::profile::base::nova::compute::libvirt_guests (
  $step                          = Integer(hiera('step')),
  $enabled                       = undef,
) {
  if $step >= 4 {
    class { '::nova::compute::libvirt_guests':
      enabled     => $enabled,
    }
    include ::nova::compute::libvirt_guests

    #set dep to docker to make sure we shutdown instances before libvirt
    #container stops
    if str2bool(hiera('docker_enabled', false)) {
      include ::systemd::systemctl::daemon_reload

      Package<| name == 'docker' |>
      -> file { '/etc/systemd/system/virt-guest-shutdown.target.wants':
        ensure => directory,
      }
      -> systemd::unit_file { 'paunch-container-shutdown.service':
        path   => '/etc/systemd/system/virt-guest-shutdown.target.wants',
        target => '/usr/lib/systemd/system/paunch-container-shutdown.service',
        before => Class['::nova::compute::libvirt_guests'],
      }
    }
  }
}
