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
# == Class: tripleo::profile::base::ceph
#
# Ceph base profile for tripleo
#
# === Parameters
#
# [*ceph_ipv6*]
#   (Optional) Force daemons to bind on IPv6 addresses
#   Defaults to false
#
# [*ceph_mon_initial_members*]
#   (Optional) List of IP addresses to use as mon_initial_members
#   Defaults to undef
#
# [*ceph_mon_host*]
#   (Optional) List of IP addresses to use as mon_host
#   Deftauls to undef
#
# [*ceph_mon_host_v6*]
#   (Optional) List of IPv6 addresses, surrounded by brackets, used as
#   mon_host when ceph_ipv6 is true
#   Defaults to undef
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::ceph (
  $ceph_ipv6                = false,
  $ceph_mon_initial_members = undef,
  $ceph_mon_host            = undef,
  $ceph_mon_host_v6         = undef,
  $step                     = hiera('step'),
) {

  if $step >= 2 {
    if $ceph_mon_initial_members {
      $mon_initial_members = downcase($ceph_mon_initial_members)
    } else {
      $mon_initial_members = undef
    }
    if $ceph_ipv6 {
      $mon_host = $ceph_mon_host_v6
    } else {
      $mon_host = $ceph_mon_host
    }

    class { '::ceph::profile::params':
      mon_initial_members => $mon_initial_members,
      mon_host            => $mon_host,
    }

    include ::ceph::conf
  }
}
