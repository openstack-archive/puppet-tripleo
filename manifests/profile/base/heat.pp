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
# == Class: tripleo::profile::base::heat
#
# Heat profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('heat_engine_short_bootstrap_node_name')
#
# [*manage_db_purge*]
#   (Optional) Whether to enable db purging
#   Defaults to lookup('heat_enable_db_purge', undef, undef, true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
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
#   Defaults to lookup('heat::cache::backend', undef, undef, false)
#
# DEPRECATED PARAMETERS
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to undef
#
class tripleo::profile::base::heat (
  $bootstrap_node          = lookup('heat_engine_short_bootstrap_node_name'),
  $manage_db_purge         = lookup('heat_enable_db_purge', undef, undef, true),
  $step                    = Integer(lookup('step')),
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
  $memcached_hosts         = lookup('memcached_node_names', undef, undef, []),
  $memcached_port          = lookup('memcached_port', undef, undef, 11211),
  $memcached_ipv6          = lookup('memcached_ipv6', undef, undef, false),
  $cache_backend           = lookup('heat::cache::backend', undef, undef, false),
  # DEPRECATED PARAMETERS
  $memcached_ips           = undef
) {
  $memcached_hosts_real = any2array(pick($memcached_ips, $memcached_hosts))

  include tripleo::profile::base::heat::authtoken

  # Domain resources will be created at step5 on the node running keystone.pp
  # configure heat.conf at step3 and 4 but actually create the domain later.
  if $step >= 3 {
    class { 'heat::keystone::domain':
      manage_domain => false,
      manage_user   => false,
      manage_role   => false,
    }

    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    class { 'heat' :
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
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

    include heat::clients
    include heat::config
    include heat::cors
    include heat::db
    include heat::logging
    include heat::trustee

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

    class { 'heat::cache':
      memcache_servers => $cache_memcache_servers
    }
  }

  if $step >= 5 {
    if $manage_db_purge {
      include heat::cron::purge_deleted
    }
  }
}
