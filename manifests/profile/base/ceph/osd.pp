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
# == Class: tripleo::profile::base::ceph::osd
#
# Ceph OSD profile for tripleo
#
# === Parameters
#
# [*ceph_osd_selinux_permissive*]
#   (Optional) Wheter to configure SELinux in permissive mode
#   Default to false
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::ceph::osd (
  $ceph_osd_selinux_permissive = false,
  $step                        = hiera('step'),
) {
  include ::tripleo::profile::base::ceph

  if $step >= 3 {
    if $ceph_osd_selinux_permissive {
      exec { 'set selinux to permissive on boot':
        command => "sed -ie 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config",
        onlyif  => "test -f /etc/selinux/config && ! grep '^SELINUX=permissive' /etc/selinux/config",
        path    => ['/usr/bin', '/usr/sbin'],
      }

      exec { 'set selinux to permissive':
        command => 'setenforce 0',
        onlyif  => "which setenforce && getenforce | grep -i 'enforcing'",
        path    => ['/usr/bin', '/usr/sbin'],
      } -> Class['ceph::profile::osd']
    }

    include ::ceph::profile::osd
  }
}
