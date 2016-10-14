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
# == Class: tripleo::profile::pacemaker::rabbitmq
#
# RabbitMQ Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*erlang_cookie*]
#   (Optional) Content of erlang cookie.
#   Defaults to hiera('rabbitmq::erlang_cookie').
#
# [*user_ha_queues*]
#   (Optional) The number of HA queues in to be configured in rabbitmq
#   Defaults to hiera('rabbitmq::nr_ha_queues'), which is usually 0 meaning
#   that the queues number will be CEIL(N/2) where N is the number of rabbitmq
#   nodes.
#
# [*rabbit_nodes*]
#   (Optional) The list of rabbitmq nodes names
#   Defaults to hiera('rabbitmq_node_names')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::rabbitmq (
  $bootstrap_node = hiera('bootstrap_nodeid'),
  $erlang_cookie  = hiera('rabbitmq::erlang_cookie'),
  $user_ha_queues = hiera('rabbitmq::nr_ha_queues', 0),
  $rabbit_nodes   = hiera('rabbitmq_node_names'),
  $step           = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::rabbitmq

  file { '/var/lib/rabbitmq/.erlang.cookie':
    ensure  => file,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0400',
    content => $erlang_cookie,
    replace => true,
    require => Class['::rabbitmq'],
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    tripleo::pacemaker::resource_restart_flag { 'rabbitmq-clone':
      subscribe => Class['rabbitmq::service'],
    }
  }

  if $step >= 2 and $pacemaker_master {
    include ::stdlib
    # The default nr of ha queues is ceiling(N/2)
    if $user_ha_queues == 0 {
      $nr_rabbit_nodes = size($rabbit_nodes)
      $nr_ha_queues = $nr_rabbit_nodes / 2 + ($nr_rabbit_nodes % 2)
    } else {
      $nr_ha_queues = $user_ha_queues
    }
    pacemaker::resource::ocf { 'rabbitmq':
      ocf_agent_name  => 'heartbeat:rabbitmq-cluster',
      resource_params => "set_policy='ha-all ^(?!amq\\.).* {\"ha-mode\":\"exactly\",\"ha-params\":${nr_ha_queues}}'",
      clone_params    => 'ordered=true interleave=true',
      meta_params     => 'notify=true',
      op_params       => 'start timeout=200s stop timeout=200s',
      require         => Class['::rabbitmq'],
    }
  }
}
