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
# == Class: tripleo::profile::base::mistral::authtoken
#
# Mistral authtoken profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*memcached_hosts*]
#   (Optional) Array of hostnames, ipv4 or ipv6 addresses for memcache.
#   Defaults to hiera('memcached_node_names', [])
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
# DEPRECATED PARAMETERS
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to undef
#
class tripleo::profile::base::mistral::authtoken (
  $step                = Integer(hiera('step')),
  $memcached_hosts     = hiera('memcached_node_names', []),
  $memcached_port      = hiera('memcached_authtoken_port', 11211),
  $security_strategy   = hiera('memcached_authtoken_security_strategy', undef),
  $secret_key          = hiera('memcached_authtoken_secret_key', undef),
  # DEPRECATED PARAMETERS
  $memcached_ips       = undef
) {
  $memcached_hosts_real = pick($memcached_ips, $memcached_hosts)

  if $step >= 3 {
    if $memcached_hosts_real[0] =~ Stdlib::Compat::Ipv6 {
      $memcache_servers = prefix(suffix(any2array(normalize_ip_for_uri($memcached_hosts_real)), ":${memcached_port}"), 'inet6:')
    } else {
      $memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_hosts_real)), ":${memcached_port}")
    }

    if $secret_key {
      $hashed_secret_key = sha256("${secret_key}+mistral")
    } else {
      $hashed_secret_key = undef
    }

    class { 'mistral::keystone::authtoken':
      memcached_servers          => $memcache_servers,
      memcache_security_strategy => $security_strategy,
      memcache_secret_key        => $hashed_secret_key,
    }
  }
}
