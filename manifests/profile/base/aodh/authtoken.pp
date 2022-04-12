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
# == Class: tripleo::profile::base::aodh::authtoken
#
# Aodh authtoken profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to lookup('step')
#
# [*memcached_hosts*]
#   (Optional) Array of hostnames, ipv4 or ipv6 addresses for memcache.
#   Defaults to lookup('memcached_node_names', undef, undef, [])
#
# [*memcached_port*]
#   (Optional) Memcached port to use.
#   Defaults to lookup('memcached_authtoken_port', undef, undef, 11211)
#
# [*memcached_ipv6*]
#   (Optional) Whether Memcached uses IPv6 network instead of IPv4 network.
#   Defauls to lookup('memcached_ipv6', undef, undef, false)
#
# [*security_strategy*]
#   (Optional) Memcached (authtoken) security strategy.
#   Defaults to lookup('memcached_authtoken_security_strategy', undef, undef, undef)
#
# [*secret_key*]
#   (Optional) Memcached (authtoken) secret key, used with security_strategy.
#   The key is hashed with a salt, to isolate services.
#   Defaults to lookup('memcached_authtoken_secret_key', undef, undef, undef)
#
# DEPRECATED PARAMETERS
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to undef
#
class tripleo::profile::base::aodh::authtoken (
  $step                = Integer(lookup('step')),
  $memcached_hosts     = lookup('memcached_node_names', undef, undef, []),
  $memcached_port      = lookup('memcached_authtoken_port', undef, undef, 11211),
  $memcached_ipv6      = lookup('memcached_ipv6', undef, undef, false),
  $security_strategy   = lookup('memcached_authtoken_security_strategy', undef, undef, undef),
  $secret_key          = lookup('memcached_authtoken_secret_key', undef, undef, undef),
  # DEPRECATED PARAMETERS
  $memcached_ips       = undef
) {
  $memcached_hosts_real = any2array(pick($memcached_ips, $memcached_hosts))

  if $step >= 3 {
    if $memcached_ipv6 or $memcached_hosts_real[0] =~ Stdlib::Compat::Ipv6 {
      $memcache_servers = $memcached_hosts_real.map |$server| { "inet6:[${server}]:${memcached_port}" }
    } else {
      $memcache_servers = suffix($memcached_hosts_real, ":${memcached_port}")
    }

    if $secret_key {
      $hashed_secret_key = sha256("${secret_key}+aodh")
    } else {
      $hashed_secret_key = undef
    }

    class { 'aodh::keystone::authtoken':
      memcached_servers          => $memcache_servers,
      memcache_security_strategy => $security_strategy,
      memcache_secret_key        => $hashed_secret_key,
    }
  }
}
