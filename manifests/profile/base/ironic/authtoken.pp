# Copyright 2019 Red Hat, Inc.
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
# == Class: tripleo::profile::base::ironic::authtoken
#
# Ironic authtoken profile for TripleO
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
# [*memcached_port*]
#   (Optional) Memcached port to use.
#   Defaults to hiera('memcached_authtoken_port', 11211)
#
# [*security_strategy*]
#   (Optional) Memcached (authtoken) security strategy.
#   Defaults to hiera('memcached_authtoken_security_strategy', undef)
#
# [*secret_key*]
#   (Optional) Memcached (authtoken) secret key, used with security_strategy.
#   The key is hashed with a salt, to isolate services.
#   Defaults to hiera('memcached_authtoken_secret_key', undef)
#
class tripleo::profile::base::ironic::authtoken (
  $step                = Integer(hiera('step')),
  $memcached_ips       = hiera('memcached_node_ips', []),
  $memcached_port      = hiera('memcached_authtoken_port', 11211),
  $security_strategy   = hiera('memcached_authtoken_security_strategy', undef),
  $secret_key          = hiera('memcached_authtoken_secret_key', undef),
) {

  if $step >= 3 {
    if is_ipv6_address($memcached_ips[0]) {
      $memcache_servers = prefix(suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211'), 'inet6:')
    } else {
      $memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211')
    }

    if $secret_key {
      $hashed_secret_key = sha256("${secret_key}+ironic")
    } else {
      $hashed_secret_key = undef
    }

    class { '::ironic::api::authtoken':
      memcached_servers          => $memcache_servers,
      memcache_security_strategy => $security_strategy,
      memcache_secret_key        => $hashed_secret_key,
    }
  }
}
