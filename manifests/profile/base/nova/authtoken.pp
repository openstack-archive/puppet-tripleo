# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::nova::authtoken
#
# Nova authtoken profile for TripleO
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to hiera('memcached_node_ips')
#
class tripleo::profile::base::nova::authtoken (
  $step                = Integer(hiera('step')),
  $memcached_ips       = hiera('memcached_node_ips'),
) {

  if $step >= 3 {
    if is_ipv6_address($memcached_ips[0]) {
      $memcache_servers = prefix(suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211'), 'inet6:')
    } else {
      $memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211')
    }

    class { '::nova::keystone::authtoken':
      memcached_servers => $memcache_servers
    }
  }
}
