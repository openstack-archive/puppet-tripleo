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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('nova_api_short_bootstrap_node_name', undef, undef, undef)
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef))
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_port', undef, undef, '5672')
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef))
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_port', undef, undef, '5672')
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_user_name', undef, undef, 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_notify_use_ssl', undef, undef, '0')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to Integer(lookup('step'))
#
# [*memcached_hosts*]
#   (Optional) Array of hostnames, ipv4 or ipv6 addresses for memcache.
#   Defaults to lookup('memcached_node_names', undef, undef, [])
#
# [*memcached_port*]
#   (Optional) Memcached port to use.
#   Defaults to lookup('memcached_port', undef, undef, 11211)
#
# [*memcached_ipv6*]
#   (Optional) Whether Memcached uses IPv6 network instead of IPv4 network.
#   Defaults to lookup('memcached_ipv6', undef, undef, false)
#
# [*cache_backend*]
#   (Optional) oslo.cache backend used for caching.
#   Defaults to lookup('nova::cache::backend', undef, undef, false)
#
# DEPRECATED PARAMETERS
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to undef
#
class tripleo::profile::base::nova (
  $bootstrap_node          = lookup('nova_api_short_bootstrap_node_name', undef, undef, undef),
  $oslomsg_rpc_proto       = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef)),
  $oslomsg_rpc_password    = lookup('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = lookup('oslo_messaging_rpc_port', undef, undef, '5672'),
  $oslomsg_rpc_username    = lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest'),
  $oslomsg_rpc_use_ssl     = lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0'),
  $oslomsg_notify_proto    = lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit'),
  $oslomsg_notify_hosts    = any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef)),
  $oslomsg_notify_password = lookup('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = lookup('oslo_messaging_notify_port', undef, undef, '5672'),
  $oslomsg_notify_username = lookup('oslo_messaging_notify_user_name', undef, undef, 'guest'),
  $oslomsg_notify_use_ssl  = lookup('oslo_messaging_notify_use_ssl', undef, undef, '0'),
  $step                    = Integer(lookup('step')),
  $memcached_hosts         = lookup('memcached_node_names', undef, undef, []),
  $memcached_port          = lookup('memcached_port', undef, undef, 11211),
  $memcached_ipv6          = lookup('memcached_ipv6', undef, undef, false),
  $cache_backend           = lookup('nova::cache::backend', undef, undef, false),
  # DEPRECATED PARAMETERS
  $memcached_ips           = undef
) {
  $memcached_hosts_real = any2array(pick($memcached_ips, $memcached_hosts))

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    if lookup('nova_is_additional_cell', undef, undef, undef) {
      $oslomsg_rpc_hosts_real = any2array(lookup('oslo_messaging_rpc_cell_node_names', undef, undef, undef))
    } else {
      $oslomsg_rpc_hosts_real = $oslomsg_rpc_hosts
    }

    if $memcached_ipv6 or $memcached_hosts_real[0] =~ Stdlib::Compat::Ipv6 {
      if $cache_backend in ['oslo_cache.memcache_pool', 'dogpile.cache.memcached'] {
        # NOTE(tkajinm): The inet6 prefix is required for backends using
        #                python-memcached
        $cache_memcache_servers = $memcached_hosts_real.map |$server| { "inet6:[${server}]:${memcached_port}" }
      } else {
        # NOTE(tkajinam): The other backends like pymemcache don't require
        #                 the inet6 prefix
        $cache_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_hosts_real)), ":${memcached_port}")
      }
    } else {
      $cache_memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_hosts_real)), ":${memcached_port}")
    }

    include nova::config
    include nova::logging
    class { 'nova::cache':
      memcache_servers => $cache_memcache_servers
    }
    class { 'nova':
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts_real,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_notify_use_ssl_real,
      }),
    }
    include nova::cinder
    include nova::glance
    include nova::placement
    include nova::keystone::service_user
  }
}
