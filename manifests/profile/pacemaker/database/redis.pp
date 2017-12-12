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
# == Class: tripleo::profile::pacemaker::database::redis
#
# OpenStack Redis Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('redis_short_bootstrap_node_name')
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     redis_certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to hiera('redis_certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*enable_load_balancer*]
#   (Optional) Whether load balancing is enabled for this cluster
#   Defaults to hiera('enable_load_balancer', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*redis_file_limit*]
#   (Deprecated) The file limit to put in /etc/security/limits.d/redis.conf
#   for when redis is managed by pacemaker. Defaults to hiera('redis_file_limit')
#   or 10240 (default in redis systemd limits). Note this option is deprecated
#   since puppet-redis grew support for ulimits in cluster configurations.
#   https://github.com/arioch/puppet-redis/pull/192. Set redis::ulimit via hiera
#   to control this limit.
#
# [*redis_network*]
#   (Optional) The network name where the redis endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('redis_network', undef)
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*extra_config_file*]
#   (Optional) When TLS proxy is in use, name of a host-specific Redis
#   config file that configures tunnel connection.
#   This is set by t-h-t.
#   Defaults to '/etc/redis-tls.conf'
#
# [*tls_tunnel_local_name*]
#   (Optional) When TLS proxy is in use, name of the localhost to forward
#   unencryption Redis traffic to.
#   This is set by t-h-t.
#   Defaults to 'localhost'
#
# [*tls_tunnel_base_port*]
#   (Optional) When TLS proxy is in use, a base integer value that is used
#   to generate a unique port number for each peer in the Redis cluster.
#   Defaults to '6660'
#
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 6379
#
class tripleo::profile::pacemaker::database::redis (
  $certificate_specs     = hiera('redis_certificate_specs', {}),
  $enable_internal_tls   = hiera('enable_internal_tls', false),
  $bootstrap_node        = hiera('redis_short_bootstrap_node_name'),
  $enable_load_balancer  = hiera('enable_load_balancer', true),
  $step                  = Integer(hiera('step')),
  $redis_file_limit      = undef,
  $redis_network         = hiera('redis_network', undef),
  $pcs_tries             = hiera('pcs_tries', 20),
  $extra_config_file     = '/etc/redis-tls.conf',
  $tls_tunnel_local_name = 'localhost',
  $tls_tunnel_base_port  = 6660,
  $tls_proxy_bind_ip     = undef,
  $tls_proxy_fqdn        = undef,
  $tls_proxy_port        = 6379,
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $enable_internal_tls {
    if !$redis_network {
      fail('redis_network is not set in the hieradata.')
    }
    if !$tls_proxy_bind_ip {
      fail('tls_proxy_bind_ip is not set in the hieradata.')
    }
    if !$tls_proxy_fqdn {
      fail('tls_proxy_fqdn is required if internal TLS is enabled.')
    }

    $redis_node_names = hiera('redis_short_node_names', [$::hostname])
    $redis_node_ips   = hiera('redis_node_ips', [$tls_proxy_bind_ip])

    # keep a mapping of [node name, node ip, replication port]
    $replication_tuples = zip($redis_node_names, $redis_node_ips).map |$index, $pair| {
      $pair.concat($tls_tunnel_base_port+$index)
    }
  } else {
    $replication_tuples = []
  }

  if $step >= 1 {
    if $enable_internal_tls {
      $tls_certfile = $certificate_specs['service_certificate']
      $tls_keyfile = $certificate_specs['service_key']

      include ::tripleo::stunnel

      # encrypted endpoint for incoming redis service
      ::tripleo::stunnel::service_proxy { 'redis':
        accept_host  => $tls_proxy_bind_ip,
        accept_port  => $tls_proxy_port,
        connect_host => $tls_tunnel_local_name,
        connect_port => $tls_proxy_port,
        certificate  => $tls_certfile,
        key          => $tls_keyfile,
        notify       => Class['::redis'],
      }

      # encrypted endpoints for outgoing redis replication traffic
      $redis_peers = $replication_tuples.filter |$tuple| {$tuple[1] != $tls_proxy_bind_ip}
      $redis_peers.each |$tuple| {
        ::tripleo::stunnel::service_proxy { "redis_peer_${tuple[2]}":
          client       => 'yes',
          accept_host  => $tls_tunnel_local_name,
          accept_port  => $tuple[2],
          connect_host => $tuple[1],
          connect_port => $tls_proxy_port,
          certificate  => $tls_certfile,
          key          => $tls_keyfile,
          notify       => Class['::redis'],
        }
      }

      # redis slave advertise itself as running on a specific
      # <localhost:port> that uniquely identifies it. This value is
      # used by the master as is, and points the the outgoing stunnel
      # endpoint to target this slave.

      $local_tuple = $replication_tuples.filter |$tuple| {
        $tuple[1] == $tls_proxy_bind_ip
      }
      if length($local_tuple)!=1 {
        fail("could not determine local TLS replication port (local ip: '${tls_proxy_bind_ip}', assigned ports: '${replication_tuples}')")
      }

      # NOTE: config parameters slave-announce-* are not exposed by
      # puppet-redis, so for now we configure them via an additional
      # host-specific config file
      File {"${extra_config_file}":
        ensure  => present,
        content => "# Host-specific configuration for TLS
slave-announce-ip ${tls_tunnel_local_name}
slave-announce-port ${local_tuple[0][2]}
",
      }
    }
    # If the old hiera key exists we use that to set the ulimit in order not to break
    # operators which set it. We might remove this in a later release (post pike anyway)
    $old_redis_file_limit = hiera('redis_file_limit', undef)
    if $old_redis_file_limit != undef {
      warning('redis_file_limit parameter is deprecated, use redis::ulimit in hiera.')
      class { '::redis':
        ulimit => $old_redis_file_limit,
      }
    } else {
      include ::redis
    }
    if $pacemaker_master and hiera('stack_action') == 'UPDATE' {
      tripleo::pacemaker::resource_restart_flag { 'redis-master':
        # ouch, but trying to stay close how notification works in
        # puppet-redis when pacemaker is not being used
        subscribe => Exec["cp -p ${::redis::config_file_orig} ${::redis::config_file}"]
      }
    }
  }

  if $step >= 2 {
    pacemaker::property { 'redis-role-node-property':
      property => 'redis-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
    if $pacemaker_master {
      if length($replication_tuples)>1 {
        $tunnel_map = $replication_tuples.map |$tuple| {"${tuple[0]}:${tuple[2]}"}
        $tunnel_opt = " tunnel_port_map='${tunnel_map.join(';')}' tunnel_host='${tls_tunnel_local_name}'"
      } else {
        $tunnel_opt=''
      }
      pacemaker::resource::ocf { 'redis':
        ocf_agent_name  => 'heartbeat:redis',
        master_params   => '',
        meta_params     => 'notify=true ordered=true interleave=true',
        resource_params => "wait_last_known_master=true${tunnel_opt}",
        op_params       => 'start timeout=200s stop timeout=200s',
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['redis-role eq true'],
        },
        require         => [Class['::redis'],
                            Pacemaker::Property['redis-role-node-property']],
      }
    }
  }
}
