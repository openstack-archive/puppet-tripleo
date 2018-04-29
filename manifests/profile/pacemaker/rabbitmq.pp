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
# [*erlang_cookie*]
#   (Optional) Content of erlang cookie.
#   Defaults to hiera('rabbitmq::erlang_cookie').
#
# [*user_ha_queues*]
#   (Optional) The number of HA queues in to be configured in rabbitmq
#   Defaults to hiera('rabbitmq::nr_ha_queues'), which is usually 0 meaning
#   that the queues number will be CEIL(N/2) where N is the number of rabbitmq
#   nodes. The special value of -1 represents the mode 'ha-mode: all'
#
# [*rpc_scheme*]
#   (Optional) Protocol for oslo messaging rpc backend.
#   Defaults to hiera('oslo_messaging_rpc_scheme').
#
# [*rpc_bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   when rabbit is configured for rpc messaging backend
#   Defaults to hiera('oslo_messaging_rpc_bootstrap_node_name')
#
# [*rpc_nodes*]
#   (Optional) Array of host(s) for oslo messaging rpc nodes.
#   Defaults to hiera('oslo_messaging_rpc_node_names', []).
#
# [*notify_scheme*]
#   (Optional) oslo messaging notify backend indicator.
#   Defaults to hiera('oslo_messaging_notify_scheme').
#
# [*notify_bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   when rabbit is configured for rpc messaging backend
#   Defaults to hiera('oslo_messaging_notify_bootstrap_node_name')
#
# [*notify_nodes*]
#   (Optional) Array of host(s) for oslo messaging notify nodes.
#   Defaults to hiera('oslo_messaging_notify_node_names', []).
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::rabbitmq (
  $erlang_cookie         = hiera('rabbitmq::erlang_cookie'),
  $user_ha_queues        = hiera('rabbitmq::nr_ha_queues', 0),
  $rpc_scheme            = hiera('oslo_messaging_rpc_scheme'),
  $rpc_bootstrap_node    = hiera('oslo_messaging_rpc_short_bootstrap_node_name'),
  $rpc_nodes             = hiera('oslo_messaging_rpc_node_names', []),
  $notify_scheme         = hiera('oslo_messaging_notify_scheme'),
  $notify_bootstrap_node = hiera('oslo_messaging_notify_short_bootstrap_node_name'),
  $notify_nodes          = hiera('oslo_messaging_notify_node_names', []),
  $pcs_tries             = hiera('pcs_tries', 20),
  $step                  = Integer(hiera('step')),
) {
  if $rpc_scheme == 'rabbit' {
    $bootstrap_node = $rpc_bootstrap_node
    $rabbit_nodes = $rpc_nodes
  } elsif $notify_scheme == 'rabbit' {
    $bootstrap_node = $notify_bootstrap_node
    $rabbit_nodes = $notify_nodes
  } else {
    $bootstrap_node = undef
    $rabbit_nodes = []
  }

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

  if $step >= 2 {
    pacemaker::property { 'rabbitmq-role-node-property':
      property => 'rabbitmq-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
    if $pacemaker_master {
      include ::stdlib
      # The default nr of ha queues is ceiling(N/2)
      if $user_ha_queues == 0 {
        $nr_rabbit_nodes = size($rabbit_nodes)
        $nr_ha_queues = $nr_rabbit_nodes / 2 + ($nr_rabbit_nodes % 2)
        $params = "set_policy='ha-all ^(?!amq\\.).* {\"ha-mode\":\"exactly\",\"ha-params\":${nr_ha_queues}}'"
      } elsif $user_ha_queues == -1 {
        $params = 'set_policy=\'ha-all ^(?!amq\.).* {"ha-mode":"all"}\''
      } else {
        $nr_ha_queues = $user_ha_queues
        $params = "set_policy='ha-all ^(?!amq\\.).* {\"ha-mode\":\"exactly\",\"ha-params\":${nr_ha_queues}}'"
      }
      pacemaker::resource::ocf { 'rabbitmq':
        ocf_agent_name  => 'heartbeat:rabbitmq-cluster',
        resource_params => $params,
        clone_params    => 'ordered=true interleave=true',
        meta_params     => 'notify=true',
        op_params       => 'start timeout=200s stop timeout=200s',
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['rabbitmq-role eq true'],
        },
        require         => [Class['::rabbitmq'],
                            Pacemaker::Property['rabbitmq-role-node-property']],
        notify          => Exec['rabbitmq-ready'],
      }
      # This grep makes sure the rabbit app in erlang is up and running
      # which is enough to guarantee that the user will eventually get
      # replicated around the cluster
      exec { 'rabbitmq-ready':
        path        => '/usr/sbin:/usr/bin:/sbin:/bin',
        command     => 'rabbitmqctl status | grep -F "{rabbit,"',
        timeout     => 30,
        tries       => 180,
        try_sleep   => 10,
        refreshonly => true,
        tag         => 'rabbitmq_ready',
      }
      # Make sure that if we create rabbitmq users at the same step it happens
      # after the cluster is up
      Exec['rabbitmq-ready'] -> Rabbitmq_user<||>
      Exec['rabbitmq-ready'] -> Rabbitmq_policy<||>
    }
  }
}
