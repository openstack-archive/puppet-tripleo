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
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::database::redis (
  $bootstrap_node       = hiera('redis_short_bootstrap_node_name'),
  $enable_load_balancer = hiera('enable_load_balancer', true),
  $step                 = Integer(hiera('step')),
  $redis_file_limit     = undef,
  $pcs_tries            = hiera('pcs_tries', 20),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 1 {
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
      pacemaker::resource::ocf { 'redis':
        ocf_agent_name  => 'heartbeat:redis',
        master_params   => '',
        meta_params     => 'notify=true ordered=true interleave=true',
        resource_params => 'wait_last_known_master=true',
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
