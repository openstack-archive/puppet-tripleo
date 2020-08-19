# Copyright 2020 Red Hat, Inc.
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
# == Class: tripleo::profile::base::swift
#
# Swift common profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*memcache_port*]
#   (Optional) memcache port
#   Defaults to 11211
#
# [*memcache_servers*]
#   (Optional) List of memcache servers
#   Defaults to hiera('memcached_node_ips', [])
#
class tripleo::profile::base::swift (
  $step                 = Integer(hiera('step')),
  $memcache_port        = 11211,
  $memcache_servers     = hiera('memcached_node_ips', []),
) {
  if $step >= 4 {
    $swift_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcache_servers)), ":${memcache_port}")
    class { 'swift::objectexpirer':
      pipeline         => ['catch_errors', 'cache', 'proxy-server'],
      memcache_servers => $swift_memcache_servers
    }
  }
}
