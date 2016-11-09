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
# == Class: tripleo::profile::base::swift::proxy
#
# Swift proxy profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*memcache_servers*]
#   (Optional) List of memcache servers
#   Defaults to hiera('memcached_node_ips')
#
# [*memcache_port*]
#   (Optional) memcache port
#   Defaults to 11211
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('swift::proxy::ceilometer::rabbit_port', 5672)
#
class tripleo::profile::base::swift::proxy (
  $step             = hiera('step'),
  $memcache_servers = hiera('memcached_node_ips'),
  $memcache_port    = 11211,
  $rabbit_hosts     = hiera('rabbitmq_node_ips', undef),
  $rabbit_port      = hiera('swift::proxy::ceilometer::rabbit_port', 5672),
) {
  if $step >= 4 {
    $swift_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcache_servers)), ":${memcache_port}")
    include ::swift::config
    include ::swift::proxy
    include ::swift::proxy::proxy_logging
    include ::swift::proxy::healthcheck
    class { '::swift::proxy::cache':
      memcache_servers => $swift_memcache_servers
    }
    include ::swift::proxy::keystone
    include ::swift::proxy::authtoken
    include ::swift::proxy::staticweb
    include ::swift::proxy::ratelimit
    include ::swift::proxy::catch_errors
    include ::swift::proxy::tempurl
    include ::swift::proxy::formpost
    include ::swift::proxy::bulk
    $swift_rabbit_hosts = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    class { '::swift::proxy::ceilometer':
      rabbit_hosts => $swift_rabbit_hosts,
    }
    include ::swift::proxy::versioned_writes
    include ::swift::proxy::slo
    include ::swift::proxy::dlo
    include ::swift::proxy::copy
    include ::swift::proxy::container_quotas
    include ::swift::proxy::account_quotas
  }
}
