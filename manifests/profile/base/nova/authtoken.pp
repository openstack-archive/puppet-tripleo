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
# [*use_ipv6*]
#   (Optional) Flag indicating if ipv6 should be used for caching
#   Defaults to hiera('nova::use_ipv6', false)
#
# [*memcache_nodes_ipv6*]
#   (Optional) Array of ipv6 addresses for memcache.  Used if use_ipv6 is true.
#   Defaults to hiera('memcached_node_ipvs_v6', ['::1'])
#
# [*memcache_nodes_ipv4*]
#   (Optional) Array of ipv4 addresses for memcache. Used by default unless
#   use_ipv6 is set to true.
#   Defaults to hiera('memcached_node_ips', ['127.0.0.1'])
#
class tripleo::profile::base::nova::authtoken (
  $step                = Integer(hiera('step')),
  $use_ipv6            = hiera('nova::use_ipv6', false),
  $memcache_nodes_ipv6 = hiera('memcached_node_ips_v6', ['::1']),
  $memcache_nodes_ipv4 = hiera('memcached_node_ips', ['127.0.0.1']),
) {

  if $step >= 3 {
    $memcached_ips = $use_ipv6 ? {
      true    => $memcache_nodes_ipv6,
      default => $memcache_nodes_ipv4
    }

    $memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211')

    class { '::nova::keystone::authtoken':
      memcached_servers => $memcache_servers
    }
  }
}
