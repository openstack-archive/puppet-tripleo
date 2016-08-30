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
# [*ceph_mon_initial_members*]
#   (Optional) List of IP addresses to use as mon_initial_members
#   Defaults to hiera('ceph_mon_node_names')
#
# [*ceph_mon_host*]
#   (Optional) List of IP addresses to use as mon_host
#   Deftauls to hiera('ceph_mon_node_ips')
#
# [*enable_ceph_storage*]
#   (Optional) enable_ceph_storage
#   Deprecated: defaults to false
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::ceph (
  $ceph_mon_initial_members = hiera('ceph_mon_node_names', undef),
  $ceph_mon_host            = hiera('ceph_mon_node_ips', '127.0.0.1'),
  $enable_ceph_storage      = false,
  $step                     = hiera('step'),
) {

  if $step >= 2 {
    if $ceph_mon_initial_members {
      if is_array($ceph_mon_initial_members) {
        $mon_initial_members = downcase(join($ceph_mon_initial_members, ','))
      } else {
        $mon_initial_members = downcase($ceph_mon_initial_members)
      }
    } else {
      $mon_initial_members = undef
    }

    if is_array($ceph_mon_host) {
      if is_ipv6_address($ceph_mon_host[0]) {
        $mon_host = join(enclose_ipv6($ceph_mon_host), ',')
      } else {
        $mon_host = join($ceph_mon_host, ',')
      }
    } else {
      $mon_host = $ceph_mon_host
    }

    class { '::ceph::profile::params':
      mon_initial_members => $mon_initial_members,
      mon_host            => $mon_host,
    }

    include ::ceph::conf
  }

  # TODO: deprecated boolean
  if $enable_ceph_storage {
    include ::tripleo::profile::base::ceph::osd
  }
}
