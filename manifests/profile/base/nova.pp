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
# == Class: tripleo::profile::base::nova
#
# Nova base profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::nova (
  $step = hiera('step'),
) {

  if hiera('nova::use_ipv6', false) {
    $memcached_servers = suffix(hiera('memcache_node_ips_v6'), ':11211')
  } else {
    $memcached_servers = suffix(hiera('memcache_node_ips'), ':11211')
  }
  if $step >= 3 {
    include ::nova
    # TODO(emilien): once we merge https://review.openstack.org/#/c/325983/
    # let's override the value this way.
    warning('Overriding memcached_servers from puppet-tripleo until 325983 lands.')
    Nova {
      memcached_servers => $memcached_servers,
    }
    include ::nova::config
  }
}
