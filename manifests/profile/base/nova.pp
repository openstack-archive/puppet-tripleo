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
#   Defaults to hiera('bootstrap_nodeid')
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_scheme', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_user_name', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_rpc_use_ssl', '0')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_scheme', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('oslo_messaging_notify_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_user_name', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('oslo_messaging_notify_use_ssl', '0')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*memcached_ips*]
#   (Optional) Array of ipv4 or ipv6 addresses for memcache.
#   Defaults to hiera('memcached_node_ips')

class tripleo::profile::base::nova (
  $bootstrap_node          = hiera('bootstrap_nodeid', undef),
  $oslomsg_rpc_proto       = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(hiera('oslo_messaging_rpc_node_names', undef)),
  $oslomsg_rpc_password    = hiera('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = hiera('oslo_messaging_rpc_port', '5672'),
  $oslomsg_rpc_username    = hiera('oslo_messaging_rpc_user_name', 'guest'),
  $oslomsg_rpc_use_ssl     = hiera('oslo_messaging_rpc_use_ssl', '0'),
  $oslomsg_notify_proto    = hiera('oslo_messaging_notify_scheme', 'rabbit'),
  $oslomsg_notify_hosts    = any2array(hiera('oslo_messaging_notify_node_names', undef)),
  $oslomsg_notify_password = hiera('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = hiera('oslo_messaging_notify_port', '5672'),
  $oslomsg_notify_username = hiera('oslo_messaging_notify_user_name', 'guest'),
  $oslomsg_notify_use_ssl  = hiera('oslo_messaging_notify_use_ssl', '0'),
  $step                    = Integer(hiera('step')),
  $memcached_ips           = hiera('memcached_node_ips'),
) {

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if is_ipv6_address($memcached_ips[0]) {
    $memcache_servers = prefix(suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211'), 'inet6:')
  } else {
    $memcache_servers = suffix(any2array(normalize_ip_for_uri($memcached_ips)), ':11211')
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    include ::nova::config
    class { '::nova::cache':
      enabled          => true,
      backend          => 'oslo_cache.memcache_pool',
      memcache_servers => $memcache_servers,
    }
    class { '::nova':
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
    include ::nova::placement
  }
}
